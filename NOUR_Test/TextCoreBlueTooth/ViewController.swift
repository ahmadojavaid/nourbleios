//
//  ViewController.swift
//  TextCoreBlueTooth
//
//  Created by abbas on 3/14/20.
//  Copyright © 2020 abbas. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController {
    
    @IBOutlet weak var btnConnect: UIButton!
    @IBOutlet weak var lblConnectionStatus: UILabel!
    @IBOutlet weak var lblBatteryStatus: UILabel!
    @IBOutlet weak var lblCardDistance: UILabel!
    @IBOutlet weak var textView: UITextView!
    
    let peripheralService = "edfec62e-9910-0bac-5241-d8bda6932a2f"
    let characReadWriteData = "772AE377-B3D2-4F8E-4042-5481D1E0098C"
    let characWriteCommand = "2D86686A-53DC-25B3-0C4A-F0E10C8DEE20" // Instructions Send byte [0] = 0x05 instruction
    let characButtonState = "6C290D2E-1C03-ACA1-AB48-A9B908BAE79E"  // Notification: press: 0x00, release: 0x01
    
    let buzzerService = "00001802-0000-1000-8000-00805f9b34fb"
    let characSound = "00002A06-0000-1000-8000-00805f9b34fb" // Write Value = 0x01 or 0x02. The buzzer will sound.
    
    let batteryService = "0000180F-0000-1000-8000-00805f9b34fb"
    let characBatteryLevel = "00002A19-0000-1000-8000-00805f9b34fb" // Enable Notify. to display service
    
    let iBeaconService = "2f234454-cf6d-4a0f-adf2-f4911ba9ffa7"
    let major = 1
    let minor = 2
    let interval = 500
    
    var centralManager: CBCentralManager!
    var bluePeripheral: CBPeripheral!
    var services: [CBService] = []
    
    var serviceCount = 0 {
        didSet {
            if serviceCount == 0 {
                blueSetNotify(characteristicUUID: characButtonState)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.blueSetNotify(characteristicUUID: self.characBatteryLevel)
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    let data = self.encodeConfigData(uuidString: self.iBeaconService, major: self.major, minor: self.minor, interval: self.interval)
                    self.writeValue(characUUID: self.characReadWriteData, data: data)
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    // send command code: 5 to read config data
                    self.writeValue(characUUID: self.characWriteCommand, data: Data(Array<UInt8>([5])))
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                    self.blueRead(characUUID: self.characReadWriteData)
                }
                
                self.services.forEach { (service) in
                    var chris = ""
                    service.characteristics?.forEach { chr in
                        chris = chris + "\(chr.uuid), "
                    }
                    print("Services Discoverd...")
                    print("\(service.uuid) : \(chris)")
                }
            }
        }
    }
    
    //var peripheralConnected: CBPeripheral? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        btnConnect.setTitle("Connect", for: .selected)
        btnConnect.setTitle("Disconnect", for: .normal)
        btnConnect.setTitle("Connecting...", for: [.disabled, .selected])
        //let scanButton = UIBarButtonItem(title: "Scan", style: .plain, target: self, action: Selector())
        //self.navigationItem.rightBarButtonItem =
    }
    
    @IBAction func btnConnect_pressed(_ sender: UIButton) {
        if sender.isSelected {
            textView.text = ""
            sender.isEnabled = false
            blueSetup()
            lblConnectionStatus.text = "Connecting..."
        } else {
            btnConnect.isSelected = true
            centralManager?.cancelPeripheralConnection(bluePeripheral)
            lblConnectionStatus.text = "Disconnected"
        }
    }
    
    @IBAction func buzzz_pressed(_ sender: UIButton) {
        sender.isEnabled = false
        self.writeValue(characUUID: self.characSound, data: Data(Array<UInt8>([1])))
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            sender.isEnabled = true
        }
    }
    
    func blueSetup() {
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func blueScan() {
        let serviceList = [CBUUID(string: peripheralService)]
        centralManager.scanForPeripherals(withServices: nil, options: nil)
    }
    
    func blueConnect() {
        /* let options = [
         CBConnectPeripheralOptionNotifyOnConnectionKey: true,
         CBConnectPeripheralOptionNotifyOnDisconnectionKey: true,
         CBConnectPeripheralOptionNotifyOnNotificationKey: true,
         CBCentralManagerRestoredStatePeripheralsKey: true,
         CBCentralManagerRestoredStateScanServicesKey : true
         ] */
        centralManager.connect(bluePeripheral, options: nil)
    }
    
    func discoverServices(){
        self.bluePeripheral.delegate = self
        services.removeAll()
        bluePeripheral?.discoverServices( nil )
    }
    
    func blueRead(characUUID: String) {
        // var valueReadBytes: [UInt8] = []
        // read battery level of peripheral
        bluePeripheral?.services?.forEach({ (oneService) in
            oneService.characteristics?.forEach({ (oneCharacteristic) in
                if oneCharacteristic.uuid == CBUUID(string: characUUID) {
                    bluePeripheral?.readValue(for: oneCharacteristic)
                    //log("read request sent")
                }
            })
        })
        //usleep(10000)
    }
    
    func blueSetNotify(characteristicUUID: String) {
        bluePeripheral?.services?.forEach({ (oneService) in
            oneService.characteristics?.forEach({ (oneCharacteristic) in
                if oneCharacteristic.uuid == CBUUID(string: characteristicUUID) {
                    bluePeripheral?.setNotifyValue(true, for: oneCharacteristic)
                }
            })
        })
    }
    
    func writeValue(characUUID: String, data: Data) {
        self.bluePeripheral?.services?.forEach({ (oneService) in
            oneService.characteristics?.forEach({ (oneCharacteristic) in
                if oneCharacteristic.uuid == CBUUID(string: characUUID) {
                    //let data: Data = message.data(using: String.Encoding.utf8)!
                    bluePeripheral?.writeValue(data, for: oneCharacteristic, type: CBCharacteristicWriteType.withResponse)
                }
            })
        })
        //usleep(10000)
    }
}

extension ViewController: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            print("central.state is .unknown")
        case .resetting:
            print("central.state is .resetting")
        case .unsupported:
            print("central.state is .unsupported")
        case .unauthorized:
            print("central.state is .unauthorized")
        case .poweredOff:
            print("central.state is .poweredOff")
        case .poweredOn:
            blueScan()
            print("central.state is .poweredOn")
        @unknown default:
            fatalError()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let name = (advertisementData["kCBAdvDataLocalName"] as? String ?? "") + (peripheral.name ?? "")
        if name.uppercased().contains("BEACON") {
            bluePeripheral = peripheral
            centralManager.stopScan()
            blueConnect()
            print("Device Printing..........................")
            print("peripheral:\(peripheral)")
            print("advertisementData:\(advertisementData)")
            print("Device Printed...........................")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        discoverServices()
        btnConnect.isEnabled = true
        btnConnect.isSelected = false
        lblConnectionStatus.text = "Connected."
        print("Connected!")
    }
    
}

// MARK: - PERIPHERAL STATUS UPDATE
extension ViewController:CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        self.services = services
        
        for service in services {
            self.bluePeripheral.discoverCharacteristics(nil, for: service)
            serviceCount = serviceCount + 1
            //dispatchGroup.enter()
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        serviceCount = serviceCount - 1
    }
}

// MARK: - DATA READ WRITE DELEGATE
extension ViewController {
    // reads notification state of charistric when it gets updated
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            print("Error didUpdateNotificationStateFor : " + error!.localizedDescription)
        }
        else {
            print("Notif State Updated For:" + characteristic.uuid.uuidString )
        }
    }
    
    // Data read from remote peripheral, or error
    
    func peripheral(_ peripheral: CBPeripheral,  didUpdateValueFor characteristic: CBCharacteristic, error: Error?){
        if error != nil {
            print("Error didUpdateValueFor : " + error!.localizedDescription)
        } else {
            //let array = [UInt8](characteristic.value ?? Data())
            //var str = ""
            //for b in array {
            //    str += String(describing: b)
            //}
            let data = characteristic.value ?? Data()
            //let str = String.init(data: data, encoding: .utf8) ?? ""
            //print("Received: " + str)
            //print("didUpdateValueFor characteristic : " + characteristic.uuid.uuidString  + " -- " + str)
            if characteristic.uuid.uuidString == characBatteryLevel.uppercased() {
                lblBatteryStatus.text = "Battery \(Array<UInt8>(data)[0])%"
            } else if characteristic.uuid.uuidString == characButtonState.uppercased() {
                self.processCardButtonPress(data)
            } else if characteristic.uuid.uuidString == characReadWriteData.uppercased() {
                self.verifyConfigration(data)
            }
        }
    }
    
    // data written to peripheral, with response from peripheral (ok, or error)
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            print("Error didWriteValueFor : " + error!.localizedDescription)
        } else {
            print("Data Send to Device")
        }
    }
    
    // RSSI was read : signal power
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        if error != nil {
            print(("Error didReadRSSI : \(error!.localizedDescription)"))
        } else {
            print("didReadRSSI: \(RSSI)")
        }
    }
}

//MARK: - Supporting Methods
extension ViewController {
    func encodeConfigData(uuidString:String, major:Int, minor:Int, interval:Int) -> Data {
        let uuidPrefix = Array("uuid:".utf8).map{UInt8($0)}
        let MJPre = Array("mj:".utf8).map{UInt8($0)}
        let MIPre = Array("mi:".utf8).map{UInt8($0)}
        let INPre = Array("in:".utf8).map{UInt8($0)}
        
        let uuidUInt = uuidString.replacingOccurrences(of: "-", with: "").map{UInt8($0.hexDigitValue!)}
        var uuidUInt8:[UInt8] = Array(repeating: 0, count: 16)
        for i in 0...15 {
            uuidUInt8[i] = 16 * uuidUInt[i * 2] + uuidUInt[i * 2 + 1]
        }
        let MJ:[UInt8] = [UInt8(major/256), UInt8(major%256)]
        let MI:[UInt8] = [UInt8(minor/256), UInt8(minor%256)]
        let IN:[UInt8] = [UInt8(interval/256), UInt8(interval%256)]
        
        var configData = ((uuidPrefix + uuidUInt8) + (MJPre + MJ))
        configData = configData + ((MIPre + MI) + (INPre + IN))
        
        return Data(configData)
    }
    
    func verifyConfigration(_ data:Data){
        if data.count == 44 {
            let uuidString = String(data: Data(Array<UInt8>(data)[0...31]), encoding: .utf8) ?? ""
            let mjArray = (String(data: Data(Array(Array<UInt8>(data)[32...35])), encoding: .utf8) ?? "").map{$0.hexDigitValue ?? 0}
            let major = mjArray[0] * 16 * 16 * 16 + mjArray[1] * 16 * 16 + mjArray[2] * 16 + mjArray[3]
            let miArray = (String(data: Data(Array(Array<UInt8>(data)[36...39])), encoding: .utf8) ?? "").map{$0.hexDigitValue ?? 0}
            let minor = miArray[0] * 16 * 16 * 16 + miArray[1] * 16 * 16 + miArray[2] * 16 + miArray[3]
            let tiArray = (String(data: Data(Array(Array<UInt8>(data)[40...43])), encoding: .utf8) ?? "").map{$0.hexDigitValue ?? 0}
            let interval = tiArray[0] * 16 * 16 * 16 + tiArray[1] * 16 * 16 + tiArray[2] * 16 + tiArray[3]
            //print("mjArray:\(mjArray), miArray:\(miArray), tiArray:\(tiArray)")
            print("uuidString: \(uuidString)")
            print("major: \(major)")
            print("minor: \(minor)")
            print("interval: \(interval)")
            if uuidString == self.iBeaconService.replacingOccurrences(of: "-", with: "").uppercased() && major == self.major && self.minor == minor && interval == self.interval {
                print("Device Configration Done Successfully")
            }
        }
    }
    
    func processCardButtonPress(_ data: Data) {
        if data.count > 0 {
            let cmd = Array<UInt8>(data)[0]
            print("Received: \(cmd)")
            if cmd == 1 {
                let alert = UIAlertController(title: "Button Pressed", message: "You have pressed card button", preferredStyle: .alert)
                self.present(alert, animated: true, completion: nil)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    alert.dismiss(animated: true, completion: nil)
                }
            }
        }
    }
}
