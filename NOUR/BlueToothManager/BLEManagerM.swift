//
//  BLEManager.swift
//  NOUR
//
//  Created by abbas on 6/25/20.
//  Copyright © 2020 abbas. All rights reserved.
//
/*
import UIKit
import CoreBluetooth
import SwiftyBluetooth

class BLEManager: NSObject {
    
    static var shared = BLEManager()
    
    var completionBLERead:((Bool, Data?, String) -> Void)?
    var completionBLEWrite:((Bool, String) -> Void)?
    
    var isProcessing = false
    var peripheral:CBPeripheral!
    
    var myPeripherals:[Peripheral] = [] {
        didSet {
            for id in 0..<myPeripherals.count {
                self.connect(id)
            }
        }
    }
    
    func add(peripheral:Peripheral) {
        if !isInPeripherals(peripheral: peripheral) {
            myPeripherals.append(peripheral)
        }
    }
    
    func getPeripheral(id:String) -> Peripheral? {
        return myPeripherals.first { (perifri) -> Bool in
            return perifri.identifier.uuidString == id
        }
    }
    
    fileprivate func isInPeripherals(peripheral:Peripheral) -> Bool {
        for perifir in myPeripherals {
            if perifir.identifier == peripheral.identifier {
                return true
            }
        }
        return false
    }
    
    fileprivate func postNotification(isSuccess:Bool){
        // post a notification
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "notificationName"), object: nil, userInfo: ["isSuccess": isSuccess])
        // `default` is now a property, not a method call
    }
    
    fileprivate func connect(_ id: Int) {
        isProcessing = true
        if myPeripherals[id].state == .connected {
            self.discoverServices(id)
        } else {
            myPeripherals[id].connect(withTimeout: 5) { result in
                self.isProcessing = false
                switch result {
                case .success:
                    self.discoverServices(id)
                case .failure(let error):
                    print(error.localizedDescription)
                    self.postNotification(isSuccess: false)
                }
            }
        }
    }
    
    fileprivate func discoverServices(_ id: Int) {
        isProcessing = true
        if let services = myPeripherals[id].services {
            self.discoverChars(for: services, id: id)
            isProcessing = false
        } else {
            myPeripherals[id].discoverServices { (result) in
                self.isProcessing = false
                switch result {
                case .success(let services):
                    //print("Services \(service.uuid)")
                    self.discoverChars(for: services, id: id)
                case .failure(let error):
                    print(error.localizedDescription)
                    self.postNotification(isSuccess: false)
                }
            }
        }
    }
    
    fileprivate func discoverChars(for services: [CBService], id:Int, sid:Int = 0) {
        isProcessing = true
        if let chars = services[sid].characteristics {
            chars.forEach { (char) in print("Service Char: \(char.uuid)") }
            if sid < (services.count - 1) {
                self.discoverChars(for: services, id: id, sid: sid + 1)
            } else {
                self.postNotification(isSuccess: true)
                isProcessing = false
            }
        } else {
            self.myPeripherals[id].discoverCharacteristics(ofServiceWithUUID: services[sid].uuid) { (result) in
                switch result {
                case .success(let chars):
                    chars.forEach { (char) in print("Service Char: \(char.uuid)") }
                    if sid < (services.count - 1) {
                        self.discoverChars(for: services, id: id, sid: sid + 1)
                    } else {
                        self.postNotification(isSuccess: true)
                        self.isProcessing = false
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                    self.postNotification(isSuccess: false)
                    self.isProcessing = false
                }
            }
        }
    }
}

// CoreBluetooth Functions
extension BLEManager {
    func blueRead(peripheral:CBPeripheral, characUUID: CBUUID, completion completionBLERead:((Bool, Data?, String) -> Void)?) {
        self.peripheral = peripheral
        self.peripheral.delegate = self
        self.completionBLERead = completionBLERead
        // var valueReadBytes: [UInt8] = []
        // read battery level of peripheral
        peripheral.services?.forEach({ (oneService) in
            oneService.characteristics?.forEach({ (oneCharacteristic) in
                if oneCharacteristic.uuid == characUUID {
                    peripheral.readValue(for: oneCharacteristic)
                    print("Read Did Send Char:\(oneCharacteristic.uuid)")
                    //log("read request sent")
                }
            })
        })
    }
    
    func writeValue(peripheral:CBPeripheral,
                    serviceUUID: CBUUID? = nil,
                    characUUID: CBUUID,
                    data: Data,
                    responseOption:CBCharacteristicWriteType = .withResponse,
                    completion completionBLEWrite:((Bool, String) -> Void)?)
    {
        self.completionBLEWrite = completionBLEWrite
        if responseOption == .withoutResponse {
            completionBLEWrite?(true, "")
        }
        self.peripheral = peripheral
        self.peripheral.delegate = self
        peripheral.services?.forEach({ (oneService) in
            if oneService.uuid == serviceUUID || serviceUUID == nil{
                oneService.characteristics?.forEach({ (oneCharacteristic) in
                    if oneCharacteristic.uuid == characUUID {
                        //let data: Data = message.data(using: String.Encoding.utf8)!
                        peripheral.writeValue(data, for: oneCharacteristic, type: responseOption)
                        
                        print("Write Request Send to:\(oneCharacteristic.uuid), \nData:\(Array<UInt8>(data))")
                    }
                })
            }
        })
        //usleep(10000)
    }
    
    func blueSetNotify(peripheral:CBPeripheral, characteristicUUID: CBUUID) {
        peripheral.services?.forEach({ (oneService) in
            oneService.characteristics?.forEach({ (oneCharacteristic) in
                if oneCharacteristic.uuid == characteristicUUID {
                    peripheral.setNotifyValue(true, for: oneCharacteristic)
                    print("Notification request sent to: \(oneCharacteristic.uuid.uuidString)")
                }
            })
        })
    }
}

extension BLEManager:CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let _ = error {
            
        } else {
            
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral,  didUpdateValueFor characteristic: CBCharacteristic, error: Error?){
        if let err = error {
            completionBLERead?(false, nil, err.localizedDescription)
        }
            let data = characteristic.value ?? Data()
            switch characteristic.uuid {
            case CBUUID(string: Config.batteryCharac):
                completionBLERead?(true, data, "battery")
            case CBUUID(string: Config.readWriteDataCharac):
                completionBLERead?(true, data, "data")
            default:
                break
            }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            completionBLEWrite?(false, error.localizedDescription)
        } else {
            completionBLEWrite?(true, "success")
        }
    }
    
    // RSSI was read : signal power
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        
    }
}
*/
