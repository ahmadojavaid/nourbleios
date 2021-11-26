//
//  DeviceCell.swift
//  TextCoreBlueTooth
//
//  Created by abbas on 3/24/20.
//  Copyright © 2020 abbas. All rights reserved.
//

import UIKit
import CoreBluetooth

protocol DeviceCellDelegate:class {
    func didReadRSSI(rssi:NSNumber)
}

class DeviceTableViewCell: UITableViewCell {
    /*
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblUUID: UILabel!
    @IBOutlet weak var btnConnect: UIButton!
    
    @IBOutlet weak var batteryProgress: UIProgressView!
    @IBOutlet weak var batteryPercentage: UILabel!
    
    weak var delegate:DeviceCellDelegate?
    
    var nConfigure = 0
    var nTries = 0
    // iBeacon
    @IBOutlet weak var btnConfigure: UIButton!
    
    weak var navigationController:UINavigationController?
    func topVC() -> UIViewController?{
        return navigationController?.topViewController
    }
    
    var processServicesDiscovery = 0
    var peripheral:CBPeripheral!
    
    @IBAction func btnConnectPressed(_ sender: UIButton) {
    }
    
    func setData(peripheral:CBPeripheral, tag:Int, btConnect:(selctor:Selector, targetVC:UIViewController), btConfigureSelector:Selector) {
        self.lblName.text = peripheral.name?.capitalized
        self.lblUUID.text = "UUID: \(peripheral.identifier)"
        
        self.btnConnect.addTarget(btConnect.targetVC, action: btConnect.selctor, for: .touchDown)
        self.btnConnect.tag = tag
        
        self.btnConfigure.addTarget(btConnect.targetVC, action: btConfigureSelector, for: .touchDown)
        self.btnConfigure.tag = tag
        
        let isConnected = peripheral.state == .connected
        if isConnected {
            if (peripheral.services?.count ?? 0) == 0 {
                discoverServices()
                btnConnect.isEnabled = false
            }
        }
        self.navigationController = btConnect.targetVC.navigationController
        
        self.peripheral = peripheral
        // Configration
        btnConnect.setTitle("Connect", for: .selected)
        btnConnect.setTitle("Disconnect", for: .normal)
        btnConnect.setTitle("Connecting...", for: [.disabled, .selected])
    }
}

//MARK:- Peripheral Delegate Methods
extension DeviceTableViewCell:CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        //self.services = services
        for service in services {
            //let index = bluePeripheral.firstIndex{$0.identifier == service.peripheral.identifier}!
            peripheral.discoverCharacteristics(nil, for: service)
            processServicesDiscovery += 1
            //dispatchGroup.enter()
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("DiscoverdService:\(service), \nDidDiscoverdCharac:\(service.characteristics ?? [])")
        processServicesDiscovery -= 1
        if processServicesDiscovery == 0 {
            characteristicsDidDiscovered()
            for srv in (peripheral.services ?? []) {
                var srvStr = srv.uuid.uuidString + " : "
                for chr in (srv.characteristics ?? []) {
                    srvStr += chr.uuid.uuidString + ", "
                }
                print(srvStr)
            }
        }
    }
    
    fileprivate func characteristicsDidDiscovered() {
        btnConnect.isEnabled = true
        btnConnect.isSelected = false
        enableNotification()
        //peripheral.services?[0].characteristics?[0].isNotifying
    }
}

//MARK:- Peripheral Delegate Data Methods
extension DeviceTableViewCell {
    fileprivate func uInt8toString (_ value:UInt8) -> String {
        let str = String(format: "%X", value)
        if str.count < 2 {
            return "0" + str
        }
        return str
    }
    
    func peripheral(_ peripheral: CBPeripheral,  didUpdateValueFor characteristic: CBCharacteristic, error: Error?){
        if error != nil {
            topVC()?.showAlertMessage(title: "Error Update Value", message: error!.localizedDescription)
            print("Did Update Value For Char Error: \(error?.localizedDescription ?? "")")
        } else {
            let data = characteristic.value ?? Data()
            
            if characteristic.uuid == Config.characBatteryLevel {
                let batteryLevel = Array<UInt8>(data)[0]
                batteryPercentage.text = "\(batteryLevel) %"
                batteryProgress.progress = Float(batteryLevel) / 100.0
                
                if batteryLevel % 10 == 0 {
                    print("Battery Notification:\(characteristic.uuid.uuidString) \nThe Value:- \(Array<UInt8>(data)[0])")
                }
            } else {
                
                print("Did Update for UUID:\(characteristic.uuid.uuidString) \nThe Value:- \(Array<UInt8>(data).map(uInt8toString).joined(separator: ", ")) The Value(Str): \n[\(String(describing: String(data: data, encoding: .utf8)))]")
                
                if characteristic.uuid == Config.characButtonState {
                    //self.processCardButtonPress(data)
                    topVC()?.showAlertMessage(title: "Button Event", message: "Device Buton Pressed")
                } else if characteristic.uuid == Config.characReadWriteData {
                    self.verifyConfigration(data)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            topVC()?.showAlertMessage(title: "Error Writing", message: error!.localizedDescription)
            print("Write Error:\(error?.localizedDescription ?? "")")
        } else {
            print("Success Data Write to Device Charis:\(characteristic.uuid.uuidString)")
        }
    }
    
    // RSSI was read : signal power
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        if error != nil {
            topVC()?.showAlertMessage(title: "", message: "Error didReadRSSI : \(error!.localizedDescription)")
            print("Error RSSI: \(error?.localizedDescription ?? "")")
        } else {
            topVC()?.showAlertMessage(title: "", message: "didReadRSSI: \(RSSI)")
        }
    }
    
}

//MARK:- Core Data Read Write Methods
extension DeviceTableViewCell {
    func blueRead(characUUID: String) {
        // var valueReadBytes: [UInt8] = []
        // read battery level of peripheral
        peripheral?.services?.forEach({ (oneService) in
            oneService.characteristics?.forEach({ (oneCharacteristic) in
                if oneCharacteristic.uuid == CBUUID(string: characUUID) {
                    peripheral?.readValue(for: oneCharacteristic)
                    print("Read Did Send Char:\(oneCharacteristic.uuid)")
                    //log("read request sent")
                }
            })
        })
        //usleep(10000)
    }
    
    func writeValue(characUUID: String, data: Data) {
        peripheral?.services?.forEach({ (oneService) in
            oneService.characteristics?.forEach({ (oneCharacteristic) in
                if oneCharacteristic.uuid == CBUUID(string: characUUID) {
                    //let data: Data = message.data(using: String.Encoding.utf8)!
                    peripheral?.writeValue(data, for: oneCharacteristic, type: CBCharacteristicWriteType.withResponse)
                    print("Write Request Send to:\(oneCharacteristic.uuid), \nData:\(Array<UInt8>(data))")
                }
            })
        })
        //usleep(10000)
    }
    
    func blueSetNotify(characteristicUUID: String) {
        peripheral?.services?.forEach({ (oneService) in
            oneService.characteristics?.forEach({ (oneCharacteristic) in
                if oneCharacteristic.uuid == CBUUID(string: characteristicUUID) {
                    peripheral?.setNotifyValue(true, for: oneCharacteristic)
                    print("Notification request sent to: \(oneCharacteristic.uuid.uuidString)")
                }
            })
        })
    }
}

extension DeviceTableViewCell {
    func discoverServices() {
        //peripheral.forEach { (peripheral) in
        peripheral.delegate = self
        peripheral.discoverServices(nil)
        //}
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
                return bService.uuid.uuidString == Config.peripheralService.uppercased()
            })
            let buttonChars = buttonService?.characteristics?.first(where: { (chars) -> Bool in
                return chars.uuid.uuidString == Config.characButtonState.uppercased()
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
            let tiArray = (String(data: Data(Array(Array<UInt8>(data)[40...43])), encoding: .utf8) ?? "").map{$0.hexDigitValue ?? 0}
            let interval = tiArray[0] * 16 * 16 * 16 + tiArray[1] * 16 * 16 + tiArray[2] * 16 + tiArray[3]
            //print("mjArray:\(mjArray), miArray:\(miArray), tiArray:\(tiArray)")
            let bConfig = Config.getBeaconData(identifier: peripheral.identifier.uuidString)
            
            if uuidString == bConfig.uuidString.replacingOccurrences(of: "-", with: "").uppercased() && major == bConfig.major && bConfig.minor == minor && interval == Config.interval {
                topVC()?.showAlertMessage(title: "", message: "Device Configration Done Successfully")
                print("Device Configration Done Successfully")
            }
        }
    }
 */
}

