//
//  ExtBeaconCell.swift
//  TextCoreBlueTooth
//
//  Created by abbas on 4/15/20.
//  Copyright © 2020 abbas. All rights reserved.
//

// Supporting Methods

import UIKit
import CoreBluetooth

//MARK:- Supporting Cell Methods
extension BeaconCell {
    func topVC() -> UIViewController?{
        return navigationController?.topViewController
    }
    
    func initialCongigration() {
        btnConnect.setTitle("Connect", for: .selected)
        btnConnect.setTitle("Disconnect", for: .normal)
        btnConnect.setTitle("Connecting...", for: [.disabled, .selected])
        btnConnect.setTitle("Disconnecting...", for: [.disabled])
        
        btnBuzzer.addTarget(self, action: #selector(btnBuzzer_pressed(_:)), for: .touchUpInside)
        //locationManager.delegate = self
        //locationManager.requestAlwaysAuthorization()
    }
    
    func setData(peripheral:CBPeripheral, tag:Int, btConnect:(selctor:Selector, targetVC:UIViewController)) {
        self.lblName.text = peripheral.name?.capitalized
        self.lblID.text = "UUID: \(peripheral.identifier)"
        
        self.btnConnect.addTarget(btConnect.targetVC, action: btConnect.selctor, for: .touchDown)
        self.btnConnect.tag = tag
        
        switch peripheral.state {
        case .disconnected:     // Connect
            btnConnect.isEnabled = true
            btnConnect.isSelected = true
        case .connected:        // Disconnect
            btnConnect.isEnabled = true
            btnConnect.isSelected = false
        case .connecting:
            btnConnect.isEnabled = false
            btnConnect.isSelected = true
        case .disconnecting:
            btnConnect.isEnabled = false
            btnConnect.isSelected = false
        @unknown default:
            fatalError()
        }
       // let isConnected = peripheral.state == .connected
       // if isConnected {
       //     if peripheral.services?.count == 0 {
                //discoverServices()
                //btnConnect.isEnabled = false
                //serviceDiscoveryState = 1
       //     }
       // }
        self.navigationController = btConnect.targetVC.navigationController
        self.peripheral = peripheral
        adjustCellHeight()
    }
    
    func adjustCellHeight() {
        
        //var newVal:CGFloat = 0
        //if self.peripheral?.state == .connected {
        //    if validateServices() == true {
        //        newVal = 130
        //    } else {
        //        newVal = 0
        //    }
        //} else {
        //    newVal = 0
        //}
        //if newVal != beaconViewHeight.constant {
        //    beaconViewHeight.constant = newVal
        //    (navigationController?.viewControllers[0] as? ScanViewController)?.tableView.reloadData()
        //}
    }
    
    func validateServices () -> Bool {
        let isMService = self.peripheral?.services?.contains{ $0.uuid == Config.peripheralService } ?? false
        //let isBtService = self.peripheral?.services?.contains{ $0.uuid.uuidString == Config.batteryService.uppercased() } ?? false
        //let isBzService = self.peripheral?.services?.contains{ $0.uuid.uuidString == Config.buzzerService } ?? false
        //print(" \(isMService) \(isBtService) \(isBzService)")
        return isMService
    }
    
    func disableShortly(_ sender: UIButton) {
        sender.isEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            sender.isEnabled = true
        }
    }
}

//MARK: - Core CB Methods
extension BeaconCell {
    func discoverServices() {
        //peripheral.forEach { (peripheral) in
        peripheral.delegate = self
        peripheral.discoverServices(nil)
        //}
    }
    
    func discoverCharacteristics() {
        guard let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
            processServicesDiscovery += 1
        }
    }
    
    func blueRead(characUUID: CBUUID) {
        // var valueReadBytes: [UInt8] = []
        // read battery level of peripheral
        peripheral?.services?.forEach({ (oneService) in
            oneService.characteristics?.forEach({ (oneCharacteristic) in
                if oneCharacteristic.uuid == characUUID {
                    peripheral?.readValue(for: oneCharacteristic)
                    print("Read Did Send Char:\(oneCharacteristic.uuid)")
                    //log("read request sent")
                }
            })
        })
        //usleep(10000)
    }
    
    func writeValue(characUUID: CBUUID, data: Data) {
        peripheral?.services?.forEach({ (oneService) in
            oneService.characteristics?.forEach({ (oneCharacteristic) in
                if oneCharacteristic.uuid == characUUID {
                    //let data: Data = message.data(using: String.Encoding.utf8)!
                    peripheral?.writeValue(data, for: oneCharacteristic, type: CBCharacteristicWriteType.withResponse)
                    print("Write Request Send to:\(oneCharacteristic.uuid), \nData:\(Array<UInt8>(data))")
                }
            })
        })
        //usleep(10000)
    }
    
    func blueSetNotify(characteristicUUID: CBUUID) {
        peripheral?.services?.forEach({ (oneService) in
            oneService.characteristics?.forEach({ (oneCharacteristic) in
                if oneCharacteristic.uuid == characteristicUUID {
                    peripheral?.setNotifyValue(true, for: oneCharacteristic)
                    print("Notification request sent to: \(oneCharacteristic.uuid.uuidString)")
                }
            })
        })
    }
}

//MARK: - Core App Supporting Methods
extension BeaconCell {
    
    func processDidUpdateValueFor(_ error: Error?, _ characteristic: CBCharacteristic) {
        logDidUpdateValueFor(error, characteristic)
        
        guard error == nil else { return }
        
        let data = characteristic.value ?? Data()
        switch characteristic.uuid {
        case Config.characBatteryLevel:
            lblBattery.text = "\(Array<UInt8>(data)[0]) %"
        case Config.characButtonState:
            topVC()?.showAlertMessage(title: "Button Event", message: "Device Buton Pressed")
        case Config.characReadWriteData:
            self.verifyConfigration(data)
        default:
            break
        }
    }
    
    func enableNotification() {
        nConfigure = 0
        nTries += 1
        // Enable Battery Notification
        let battryService = peripheral.services?.first(where: { (bService) -> Bool in
            return bService.uuid == Config.batteryService
        })
        let battryChars = battryService?.characteristics?.first(where: { (chars) -> Bool in
            return chars.uuid == Config.characBatteryLevel
        })
        if battryChars?.isNotifying != true {
            self.blueSetNotify(characteristicUUID: Config.characBatteryLevel)
            self.nConfigure += 1
            print("Notification Enable Req Send for Battery Service")
        } else {
            print("Notification Did Enabled for Battery Service")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            // Enable Card Button Notification
            let buttonService = self.peripheral.services?.first(where: { (bService) -> Bool in
                return bService.uuid == Config.peripheralService
            })
            let buttonChars = buttonService?.characteristics?.first(where: { (chars) -> Bool in
                return chars.uuid == Config.characButtonState
            })
            if buttonChars?.isNotifying != true {
                self.blueSetNotify(characteristicUUID: Config.characButtonState)
                self.nConfigure += 1
                print("Notification Enable Req Send for Button Service")
            } else {
                print("Notification Did Enabled for Button Service")
            }
            
            if self.nConfigure != 0 && self.nTries < 5 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                    self?.enableNotification()
                }
            } else if self.nConfigure == 0 {
                self.topVC()?.showAlertMessage(title: "", message: "Notifications Subscribed.")
            }
        }
    }
    
    func verifyConfigration(_ data:Data) {
        if data.count == 44 {
            let uuidString = String(data: Data(Array<UInt8>(data)[0...31]), encoding: .utf8) ?? ""
            let mjArray = (String(data: Data(Array(Array<UInt8>(data)[32...35])), encoding: .utf8) ?? "").map{$0.hexDigitValue ?? 0}
            let major = mjArray[0] * 16 * 16 * 16 + mjArray[1] * 16 * 16 + mjArray[2] * 16 + mjArray[3]
            let miArray = (String(data: Data(Array(Array<UInt8>(data)[36...39])), encoding: .utf8) ?? "").map{$0.hexDigitValue ?? 0}
            let minor = miArray[0] * 16 * 16 * 16 + miArray[1] * 16 * 16 + miArray[2] * 16 + miArray[3]
            //let tiArray = (String(data: Data(Array(Array<UInt8>(data)[40...43])), encoding: .utf8) ?? "").map{$0.hexDigitValue ?? 0}
            //let interval = tiArray[0] * 16 * 16 * 16 + tiArray[1] * 16 * 16 + tiArray[2] * 16 + tiArray[3]
            //print("mjArray:\(mjArray), miArray:\(miArray), tiArray:\(tiArray)")
            let bConfig = Config.getBeaconData(identifier: peripheral.identifier.uuidString)
            
            if uuidString == bConfig.uuidString.replacingOccurrences(of: "-", with: "").uppercased() && major == bConfig.major && bConfig.minor == minor {
                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                    self.topVC()?.showAlertMessage(title: "", message: "Beacon Configured Successfully")
                }
                print("Beacon Configured Successfully")
            }
        }
    }
}

//MARK: - Supporting CB Methods
extension BeaconCell {
    func didDiscoverdAllCharacteristics() -> Bool  {
        processServicesDiscovery -= 1
        if processServicesDiscovery == 0 {
            logServices()
            //btnConnect.isEnabled = true
            //btnConnect.isSelected = false
            //adjustCellHeight()
            return true
        } else {
            return false
        }
    }
    
    func uInt8toString (_ value:UInt8) -> String {
        let str = String(format: "%X", value)
        if str.count < 2 {
            return "0" + str
        }
        return str
    }
}

//MARK:- Log methods
extension BeaconCell {
    func logServices() {
        for srv in (peripheral.services ?? []) {
            var srvStr = srv.uuid.uuidString + " : "
            for chr in (srv.characteristics ?? []) {
                srvStr += chr.uuid.uuidString + ", "
            }
            print(srvStr)
        }
    }
    
    func logDidReadRSSI(_ error: Error?, _ RSSI: NSNumber) {
        if error != nil {
            topVC()?.showAlertMessage(title: "", message: "Error didReadRSSI : \(error!.localizedDescription)")
            print("Error RSSI: \(error?.localizedDescription ?? "")")
        } else {
            print("didReadRSSI: \(RSSI)")
        }
    }
    
    func logDidUpdateValueFor(_ error: Error?, _ characteristic: CBCharacteristic) {
        if error != nil {
            topVC()?.showAlertMessage(title: "Error", message: error!.localizedDescription)
            print("Did Update Value For Char Error: \(error?.localizedDescription ?? "")")
        } else {
            let data = characteristic.value ?? Data()
            if characteristic.uuid != Config.characBatteryLevel {
                print("Did Update for UUID:\(characteristic.uuid.uuidString) \nThe Value:- \(Array<UInt8>(data).map(uInt8toString).joined(separator: ", ")) The Value(Str): \n[\(String(describing: String(data: data, encoding: .utf8)))]")
            }
        }
    }
    
    func logDidWriteValueFor(_ error: Error?, _ characteristic: CBCharacteristic) {
        if error != nil {
            topVC()?.showAlertMessage(title: "Error Writing", message: error!.localizedDescription)
            print("Write Error:\(error?.localizedDescription ?? "")")
        } else {
            print("Success Data Write to Device Charis:\(characteristic.uuid.uuidString)")
        }
    }
}

//MARK:- Supporting UITableViewCell Extension
extension UITableViewCell {
    static func getInstance(nibName:String) -> UITableViewCell? {
        if let nibContents = Bundle.main.loadNibNamed(nibName, owner: UITableViewCell(), options: nil) {
            for item in nibContents {
                if let cell = item as? UITableViewCell {
                    return cell
                }
            }
        }
        return nil
    }
}
