//
//  BLEManager.swift
//  NOUR
//
//  Created by abbas on 6/25/20.
//  Copyright © 2020 abbas. All rights reserved.
//

import UIKit
import CoreBluetooth

@objc enum CentralState:Int {
    case unknown, resetting, unsupported, unauthorized, poweredOff, poweredOn, restoring, restored, searching, idleDiscoverd
    var message:String {
        switch self {
        case .unknown:
            return "An unknown error occured. Please try again after some time or contact support."
        case .resetting:
            return "Resetting..."
        case .unsupported:
            return "The device is not supported for Bluetooth operations."
        case .unauthorized:
            return "Bluetooth access to Nour was restricted. This can be configured in phone settings."
        case .poweredOff:
            return "Phone bluetooth is Off."
        case .poweredOn:
            return "On"
        case .restoring:
            return "Restoring..."
        case .restored:
            return "Restored"
        case .searching:
            return "Searching..."
        case .idleDiscoverd:
            return "Ready"
        }
    }
}

class BLEManager: NSObject {
    
    typealias completionBLE = ((Bool, String)->Bool)
    
    static var shared = BLEManager()
    
    fileprivate var completionIsReady:completionBLE?
    fileprivate var completionConnect:completionBLE?
    fileprivate var completionScanResult:((Bool, CBPeripheral, [String : Any], String)->Bool)?
    
    fileprivate var scanTime:Int = 0
    fileprivate var myPeripheralsIndex:[String:Int] = [:]
    fileprivate var centralManagerObserver:NSKeyValueObservation!
    fileprivate var isExecuting = true
    
    var centralManager:CBCentralManager!
    @objc dynamic var state:CentralState = .unknown
    
    @objc dynamic var myPeripherals:[APPeripheralManager] = [] {
        didSet {
            self.myPeripheralsIndex = [:]
            for (index, value) in myPeripherals.enumerated() {
                myPeripheralsIndex[value.peripheral.identifier.uuidString] = index
            }
        }
    }
    
    deinit {
        self.centralManagerObserver?.invalidate()
    }
    
    init(completion completionIsReady:completionBLE?) {
        super.init()
        self.completionIsReady = completionIsReady
        self.centralManager = CBCentralManager ( delegate: self, queue: nil, options: nil )
    }
    
    fileprivate override init() {
        super.init()
        self.centralManager = CBCentralManager (
            delegate: self, queue: nil,
            options: [ CBCentralManagerOptionRestoreIdentifierKey:"NOUR0012203003044554" ]
        )

        centralManagerObserver = self.centralManager.observe(\CBCentralManager.state, options: .new) { (central, change) in
            switch central.state {
            case .unknown:
                self.state = .unknown
            case .resetting:
                self.state = .resetting
            case .unsupported:
                self.state = .unauthorized
            case .unauthorized:
                self.state = .unauthorized
            case .poweredOff:
                self.state = .poweredOff
            case .poweredOn:
                self.state = .poweredOn
            @unknown default:
                self.state = .unknown
            }
        }
        executeStateAction()
    }
    
    func configure() {
        print("Configuring BLEManager for auto search and connection...")
    }
    
    fileprivate func performStateAction() {
        //unknown, resetting, unsupported, unauthorized, poweredOff, poweredOn, restoring, searching, idleDiscoverd
        switch state {
        case .unknown, .resetting, .unsupported, .poweredOff, .unauthorized:
            break
        case .poweredOn:
            print("Bluetooth is on")
            if isRestored() {
                state = .idleDiscoverd
            } else {
                retrivePeripherals()
            }
        case .restoring:
            // Update this state to 'powerdOn' after 5 seconds if not done
            print("Restoring...")
        case .restored:
            if isRestored() {
                state = .idleDiscoverd
            } else {
                self.scanPeripherals(completionScanResult: nil)
            }
        case .searching:
            if centralManager.isScanning == false {
                if isRestored() {
                    state = .idleDiscoverd
                } else {
                    self.scanPeripherals(completionScanResult: nil)
                }
            }
            print("Searching...")
        case .idleDiscoverd:
            self.isExecuting = false
        }
    }
    
    func setAsPowerdOn() {
        state = .poweredOn
        self.isExecuting = true
        executeStateAction()
    }
    
    fileprivate func executeStateAction() {
        self.performStateAction()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            if self?.isExecuting == true {
                self?.executeStateAction()
            }
        }
    }
}

//MARK:- Utality Methods Get, Set and Filter
extension BLEManager {
    func getPeripheralID(by identifier:UUID) -> Int? {
        return self.myPeripheralsIndex[identifier.uuidString]
    }
    func getPeripheralID(by identifier:String) -> Int? {
        return self.myPeripheralsIndex[identifier]
    }
    
    func getPeripheralBy(index:Int) -> CBPeripheral? {
        guard index < myPeripherals.count else {
            return nil
        }
        return myPeripherals[index].peripheral
    }
    
    func add(peripheral:CBPeripheral) -> Bool {
        guard isInPeripherals(peripheral: peripheral) else {
            myPeripherals.append(APPeripheralManager(peripheral))
            return true
        }
        return false
    }
    func add(peripheral:APPeripheralManager) -> Bool {
        guard isInPeripherals(peripheral: peripheral.peripheral) else {
            myPeripherals.append(peripheral)
            return true
        }
        return false
    }
}

//MARK:- BLE Operations
extension BLEManager {
    
    func scanPeripherals (time:Int? = nil, completionScanResult:((Bool, CBPeripheral, [String : Any], String)->Bool)?) {
        state = .searching
        if let completion = completionScanResult {
            self.completionScanResult = completion
        }
        self.centralManager.scanForPeripherals(withServices: [CBConfig.buzzerService], options: nil)
        if let time = time {
            self.scanTime = time
            self.stopScan()
        }
    }
    
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        print("WillRestoreState:\(dict)")
    }
    
    func connect(index:Int, completion completionConnect:completionBLE?) {
        self.completionConnect = completionConnect
        centralManager.connect(myPeripherals[index].peripheral, options: nil)
    }
    
    func connect(peripheral: CBPeripheral, completion completionConnect:completionBLE?) {
        self.completionConnect = completionConnect
        centralManager.connect(peripheral, options: nil)
    }
    
    func retrivePeripherals() {
        self.state = .restoring
                
        let pids = Set(Product.getAllProducts().products.map({UUID(uuidString: $0.id)!}))
        if pids.count == 0 { return }
        
        var peripherals:[CBPeripheral] = []
        
        let rcPeripheral = centralManager.retrieveConnectedPeripherals(withServices: [CBConfig.peripheralService, CBConfig.buzzerService, CBConfig.buzzerService])
        
        for rcp in rcPeripheral {
            if pids.contains(rcp.identifier) {
                _ = self.addin(peripherals: &peripherals, peripheral: rcp)
            }
        }
        
        let riPeripheral = centralManager.retrievePeripherals(withIdentifiers: Array(pids))
        
        if peripherals.count != pids.count {
            
            for rip in riPeripheral {
                if pids.contains(rip.identifier) {
                    _ = self.addin(peripherals: &peripherals, peripheral: rip)
                }
            }
            
        }
        
        for prf in peripherals {
            if !myPeripherals.contains(where: {$0.peripheral.identifier == prf.identifier}) {
                myPeripherals.append(APPeripheralManager(prf))
            }
        }
        state = myPeripherals.count == pids.count ? .idleDiscoverd:.restored
    }
}

/*
 case .unknown:
     return "An unknown error occured. Please try again after some time or contact support."
 case .resetting:
     return "Resetting..."
 case .unsupported:
     return "The device is not supported for Bluetooth operations."
 case .unauthorized:
     return "Bluetooth access to Nour was restricted. This can be configured in phone settings."
 case .poweredOff:
     return "Phone bluetooth is Off."
 case .poweredOn:
     return "On"
 case .restoring:
     return "Restoring..."
 case .restored:
     return "Restored"
 case .searching:
     return "Searching..."
 case .idleDiscoverd:
     return "Ready"
 }
 */
extension BLEManager: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .resetting:
            break
        case .poweredOff:
            if self.completionIsReady?(false, "Phone bluetooth is Off.") == true {
                self.completionIsReady = nil
            }
        case .unauthorized:
            if self.completionIsReady?(false, "Bluetooth access to Nour was restricted. This can be configured in phone settings.") == true {
                self.completionIsReady = nil
            }
        case .unsupported:
            if self.completionIsReady?(false, "The device is not supported for Bluetooth operations.") == true {
                self.completionIsReady = nil
            }
        case .poweredOn:
            if self.completionIsReady?(true, "success") == true {
                self.completionIsReady = nil
            }
        default:
            if self.completionIsReady?(false, "An unknown error occured. Please try again after some time or contact support.") == true {
                self.completionIsReady = nil
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if let completion = completionScanResult {
            if completion(true, peripheral, advertisementData, "") == true {
                self.completionScanResult = nil
            }
        } else {
            let nd = Set(self.getNotDiscoverdPIDs())
            if nd.contains(peripheral.identifier) {
                _ = self.add(peripheral: peripheral)
                if isRestored() {
                    self.state = .idleDiscoverd
                    centralManager.stopScan()
                }
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if self.completionConnect?(true, "\(peripheral.identifier)") == true {
            completionConnect = nil
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if self.completionConnect?(false, error?.localizedDescription ?? "") == true {
            completionConnect = nil
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("didDisconnectPeripheral: \(error?.localizedDescription ?? "")")
    }
}

// Private supporting methods
fileprivate extension BLEManager {
    func isInPeripherals(peripheral:CBPeripheral) -> Bool {
        for perifir in myPeripherals {
            if perifir.peripheral.identifier == peripheral.identifier {
                return true
            }
        }
        return false
    }
    
    func postNotification(isSuccess:Bool) {
        // post a notification
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "notificationName"), object: nil, userInfo: ["isSuccess": isSuccess])
        // `default` is now a property, not a method call
    }
    
    func isAuthorized() -> Bool {
        if #available(iOS 13.0, *) {
            return centralManager.authorization == .allowedAlways
        } else {
            return centralManager.state != .unauthorized
        }
    }
    
    func isBluetoothOn() -> Bool {
        return centralManager.state == .poweredOn
    }
    
    func isBluetoothReady() -> Bool {
        return isAuthorized() && isBluetoothOn()
    }
    
    func getReady(completion completionGetReady:((Bool, String)->Void)){
        
    }
    
    func addin(peripherals: inout [APPeripheralManager], peripheral:CBPeripheral) -> Bool {
        let isInPeripherals = peripherals.contains(where: {($0).peripheral.identifier == peripheral.identifier})
        guard isInPeripherals else {
            peripherals.append(APPeripheralManager(peripheral))
            return true
        }
        return false
    }
    
    func addin(peripherals: inout [CBPeripheral], peripheral:CBPeripheral) -> Bool {
        let isInPeripherals = peripherals.contains(where: {($0).identifier == peripheral.identifier})
        guard isInPeripherals else {
            peripherals.append(peripheral)
            return true
        }
        return false
    }
    
    func stopScan() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            if let sself = self {
                sself.scanTime = sself.scanTime - 1
                if sself.scanTime > 0 {
                    sself.stopScan()
                } else {
                    sself.centralManager.stopScan()
                    sself.completionScanResult = nil
                }
            }
        }
    }
    
    func isRestored() -> Bool {
        return Product.getAllProducts().products.count == myPeripherals.count
    }
    
    func getNotDiscoverdPIDs() -> [UUID] {
        var pids = Product.getAllProducts().products.map({UUID(uuidString: $0.id)!})
        for index in 0..<myPeripherals.count {
            if let id = pids.firstIndex(where: {$0 == myPeripherals[index].peripheral.identifier}) {
                pids.remove(at: id)
            }
        }
        return pids
    }
}

