//
//  APPeripheral.swift
//  NOUR
//
//  Created by abbas on 7/6/20.
//  Copyright © 2020 abbas. All rights reserved.
//

import UIKit
import CoreBluetooth

@objc enum PeripheralState:Int {
    case unknown, disconnecting, disconnected, connecting, connected, discovering, idleDiscoverd, reading, readRSSI ,writing
    var message:String {
        switch self {
        case .unknown:
            return "Unknown"
        case .disconnecting:
            return "Disconnecting..."
        case .disconnected:
            return "Disconnected"
        case .connecting:
            return "Connecting..."
        case .connected:
            return "Connected"
        case .discovering:
            return "Discovering Characteristics..."
        case .idleDiscoverd:
            return "Ready"
        case .reading:
            return "Reading Data..."
        case .writing:
            return "Sending Data..."
        case .readRSSI:
            return "Reading Connection..."
        }
    }
}

class APPeripheralManager: NSObject {
    typealias completionBLE = ((Bool, String) -> Bool)
    
    fileprivate var completionServicesDiscovery:completionBLE?
    fileprivate var completionBLERead:((Bool, Data?, String) -> Bool)?
    fileprivate var completionReadRSSI:((Bool, Int?, String, String) -> Bool)?
    fileprivate var completionBLEWrite:completionBLE?
    fileprivate var completionSetNotify:completionBLE?
    fileprivate var completionService:completionBLE?
    fileprivate var completionChar:completionBLE?
    
    //fileprivate var sDiscovery = 0
    
    fileprivate var stateCounter1 = 0
    fileprivate var stateCounter2 = 0
    fileprivate var charDiscoveryIndex = 0
    
    fileprivate var peripheralStateObserver:NSKeyValueObservation!
    fileprivate var operationQueue:[()->Void] = []
    
    @objc dynamic var state:PeripheralState = .unknown
    var peripheral:CBPeripheral!
    
    func performStateAction() {
        
        switch state {
        case .disconnecting,.unknown, .connecting:
            stateCounter1 = 0
            stateCounter2 = 0
        case .discovering:
            stateCounter1 = stateCounter1 + 1
            if stateCounter1 == 30 {
                stateCounter1 = 0
                state = .connected
            }
            stateCounter2 = 0
        case .reading, .writing, .readRSSI:
            stateCounter2 = stateCounter2 + 1
            if stateCounter2 == 30 {
                stateCounter2 = 0
                state = .idleDiscoverd
            }
            stateCounter1 = 0
        case .connected:
            let discState = peripheral.isDiscoverd()
            if discState == 1 {
                state = .idleDiscoverd
            } else if discState == 0 {
                charDiscoveryIndex = 0
                self.discoverCharistrics()
            } else {
                self.discoverServicesChars()
            }
            stateCounter1 = 0
            stateCounter2 = 0
        case .idleDiscoverd:
            if operationQueue.count > 0 {
                let operation = operationQueue.removeFirst()
                operation()
            }
            stateCounter1 = 0
            stateCounter2 = 0
        case .disconnected:
            BLEManager.shared.centralManager.connect(peripheral, options: nil)
            stateCounter1 = 0
            stateCounter2 = 0
        }
    }
    
    func executeStateAction() {
        self.performStateAction()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.executeStateAction()
        }
    }
    
    init(_ peripheral:CBPeripheral) {
        super.init()
        self.peripheral = peripheral
        self.peripheral.delegate = self
        let ps = self.peripheral.state
        state = ps == .connected ? .connected: (ps == .connecting ? .connecting: (ps == .disconnected ? .disconnected:.disconnecting))
        
        peripheralStateObserver = self.peripheral.observe(\CBPeripheral.state, options: .new) { (perif, change) in
            switch peripheral.state {
            case .connected:
                self.state = .connected
            case .connecting:
                self.state = .connecting
            case .disconnected:
                self.state = .disconnected
            case .disconnecting:
                self.state = .disconnecting
            @unknown default:
                self.state = .unknown
            }
        }
        executeStateAction()
    }
    
    deinit {
        peripheralStateObserver.invalidate()
    }
    
}

extension APPeripheralManager {
    func discoverServicesChars() {
        self.state = .discovering
        let services = Array<CBUUID>(CBConfig.chars.keys)
        self.peripheral.discoverServices(services)
    }
    
    func discoverCharistrics() {
        let service = peripheral.services![charDiscoveryIndex]
        self.peripheral.discoverCharacteristics(CBConfig.chars[service.uuid], for: service)
        guard (charDiscoveryIndex + 1) < (self.peripheral.services?.count ?? 0) else {
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.charDiscoveryIndex += 1
            self?.discoverCharistrics()
        }
    }
    
    func readRSSI(completion completionReadRSSI:((Bool, Int?, String, String) -> Bool)?) {
        if self.state == .idleDiscoverd {
            self.state = .readRSSI
        } else {
            self.operationQueue.append { self.readRSSI(completion: completionReadRSSI) }
            return
        }
        
        if let completion = completionReadRSSI {
            self.completionReadRSSI = completion
        }
        
        self.peripheral.readRSSI()
    }
    
    func readData (
        characUUID: CBUUID,
        serviceUUID: CBUUID,
        completion completionBLERead:((Bool, Data?, String) -> Bool)?
    ) {
        if self.state == .idleDiscoverd {
            self.state = .reading
        } else {
            operationQueue.append {
                self.readData(characUUID: characUUID, serviceUUID: serviceUUID, completion: completionBLERead)
            }
            return
        }
        
        guard let characteristic = getChar(charUUID: characUUID, serviceUUID: serviceUUID) else {
            self.discoverServicesChars()
            operationQueue.append {
                self.readData(characUUID: characUUID, serviceUUID: serviceUUID, completion: completionBLERead)
            }
            return
        }
        
        if let completion = completionBLERead {
            self.completionBLERead = completion
        }
        
        self.peripheral.readValue(for: characteristic)
        
    }
    
    func writeValue (
        characUUID: CBUUID,
        serviceUUID: CBUUID,
        data: Data,
        responseOption:CBCharacteristicWriteType = .withResponse,
        completion completionBLEWrite:completionBLE?
    ) {
        if self.state == .idleDiscoverd {
            self.state = .writing
        } else {
            operationQueue.append {
                self.writeValue(characUUID: characUUID, serviceUUID: serviceUUID, data: data, completion: completionBLEWrite)
            }
            return
        }
        
        guard let characteristic = getChar(charUUID: characUUID, serviceUUID: serviceUUID) else {
            self.discoverServicesChars()
            operationQueue.append {
                self.writeValue(characUUID: characUUID, serviceUUID: serviceUUID, data: data, completion: completionBLEWrite)
            }
            return
        }
        
        if let completion = completionBLEWrite {
            self.completionBLEWrite = completion
        }
        
        guard state == .writing else {
            operationQueue.append {
                self.writeValue(characUUID: characUUID, serviceUUID: serviceUUID, data: data, completion: completionBLEWrite)
            }
            return
        }
        self.peripheral.writeValue(data, for: characteristic, type: responseOption)
        
        if responseOption == .withoutResponse {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if self.completionBLEWrite?(true, "") == true {
                    self.completionBLEWrite = nil
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.state = .idleDiscoverd
            }
        }
    }
    
    func setNotify (
        characUUID: CBUUID,
        serviceUUID: CBUUID,
        completion completionSetNotify:completionBLE?
    ) {
        if state == .idleDiscoverd {
            self.state = .writing
        } else {
            self.operationQueue.append {
                self.setNotify(characUUID: characUUID, serviceUUID: serviceUUID, completion: completionSetNotify)
            }
            return
        }
        
        guard let characteristic = getChar(charUUID: characUUID, serviceUUID: serviceUUID) else {
            self.discoverServicesChars()
            self.operationQueue.append {
                self.setNotify(characUUID: characUUID, serviceUUID: serviceUUID, completion: completionSetNotify)
            }
            return
        }
        
        if let completion = completionSetNotify {
            self.completionSetNotify = completion
        }
        
        self.peripheral.setNotifyValue(true, for: characteristic)
    }
}

extension APPeripheralManager:CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            if self.completionServicesDiscovery?(false, error.localizedDescription) == true {
                self.completionServicesDiscovery = nil
            }
            state = .connected
        } else {
            charDiscoveryIndex = 0
            discoverCharistrics()
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Error?) {
        if let error = error {
            if self.completionServicesDiscovery?(false, error.localizedDescription) == true {
                self.completionServicesDiscovery = nil
            }
            state = .connected
        } else {
            charDiscoveryIndex = 0
            discoverCharistrics()
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            if self.completionServicesDiscovery?(false, error.localizedDescription) == true {
                self.completionServicesDiscovery = nil
            }
            state = .connected
        } else if peripheral.isDiscoverd() == 1 {
            state = .idleDiscoverd
            if self.completionServicesDiscovery?(true, peripheral.identifier.uuidString) == true {
                self.completionServicesDiscovery = nil
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            if self.completionSetNotify?(false, error.localizedDescription) == true {
                self.completionSetNotify = nil
            }
        } else {
            if self.completionSetNotify?(true, characteristic.uuid.uuidString) == true {
                self.completionSetNotify = nil
            }
        }
        state = .idleDiscoverd
    }
    
    func peripheral(_ peripheral: CBPeripheral,  didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let err = error {
            if completionBLERead?(false, nil, err.localizedDescription) == true {
                self.completionBLERead = nil
            }
            print("Reading Error: \(err.localizedDescription)")
            self.state = .idleDiscoverd
            return
        }
        let data = characteristic.value ?? Data()
        switch characteristic.uuid {
        case CBConfig.batteryCharac:
            if completionBLERead?(true, data, "battery") == true {
                self.completionBLERead = nil
            }
        case CBConfig.readWriteDataCharac:
            if completionBLERead?(true, data, "data") == true {
                self.completionBLERead = nil
            }
        default:
            break
        }
        self.state = .idleDiscoverd
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            if completionBLEWrite?(false, error.localizedDescription) == true {
                completionBLEWrite = nil
            }
        } else {
            if completionBLEWrite?(true, "success") == true {
                completionBLEWrite = nil
            }
        }
        state = .idleDiscoverd
    }
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        print("didWriteValueFor descriptor: \(error?.localizedDescription ?? "\(descriptor)")")
    }
    
    func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        if self.completionBLEWrite?(true, peripheral.identifier.uuidString) == true {
            self.completionBLEWrite = nil
        }
        print("toSendWriteWithoutResponse")
    }
    
    // RSSI was read : signal power
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        if let error = error {
            if self.completionReadRSSI?(false, 0, peripheral.identifier.uuidString ,error.localizedDescription) == true {
                self.completionReadRSSI = nil
            }
        } else {
            if self.completionReadRSSI?(true, Int(truncating: RSSI), peripheral.identifier.uuidString, "Success") == true {
                self.completionReadRSSI = nil
            }
        }
    }
}

//MARK: - Local Unility Methods
extension APPeripheralManager {
    func getChar(charUUID:CBUUID, serviceUUID:CBUUID) -> CBCharacteristic? {
        for service in peripheral.services ?? [] {
            if serviceUUID == service.uuid {
                for char in service.characteristics ?? [] {
                    if char.uuid == charUUID {
                        return char
                    }
                }
            }
        }
        return nil
    }
}
