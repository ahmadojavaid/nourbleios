//
//  ExtBeaconViewController.swift
//  TextCoreBlueTooth
//
//  Created by abbas on 4/20/20.
//  Copyright © 2020 abbas. All rights reserved.
//

import UIKit
import CoreBluetooth
import CoreLocation

extension BeaconViewController {
    
    func initialCongigration() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.requestAlwaysAuthorization()
    }
    
    func setData(){
        let configData = Config.getBeaconData(identifier: peripheral.identifier.uuidString)
        txtUUID.text = configData.uuidString
        txtMajor.text = "\(configData.major)"
        txtMinor.text = "\(configData.minor)"
    }
    
    func validateServices () -> Bool {
        let isMService = self.peripheral?.services?.contains{ $0.uuid == Config.peripheralService } ?? false
        return isMService
    }
    
    func disableShortly(_ sender: UIButton) {
        sender.isEnabled = false
        sender.backgroundColor = .lightGray
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            sender.isEnabled = true
            sender.backgroundColor = .systemBlue
        }
    }
}

//MARK: - Core CB Methods
extension BeaconViewController {
    
    func discoverServices() {
        self.showAlertMessage(title: "", message: "Discovering Services")
        peripheral.delegate = self
        peripheral.discoverServices(nil)
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
    }
    
    func writeValue(serviceUUID: CBUUID? = nil, characUUID: CBUUID, data: Data, responseOption:CBCharacteristicWriteType = .withoutResponse) {
        peripheral?.services?.forEach({ (oneService) in
            if oneService.uuid == serviceUUID || serviceUUID == nil{
                oneService.characteristics?.forEach({ (oneCharacteristic) in
                    if oneCharacteristic.uuid == characUUID {
                        //let data: Data = message.data(using: String.Encoding.utf8)!
                        
                        peripheral?.writeValue(data, for: oneCharacteristic, type: responseOption)
                        
                        print("Write Request Send to:\(oneCharacteristic.uuid), \nData:\(Array<UInt8>(data))")
                    }
                })
            }
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
extension BeaconViewController {
    
    func processDidUpdateValueFor(_ error: Error?, _ characteristic: CBCharacteristic) {
        logDidUpdateValueFor(error, characteristic)
        
        guard error == nil else { return }
        
        let data = characteristic.value ?? Data()
        switch characteristic.uuid {
        case Config.characBatteryLevel:
            btnBattery.setTitle("Battery: \(Array<UInt8>(data)[0]) %", for: .normal)
        case Config.characButtonState:
            let datau8 = Array<UInt8>(data)
            let value = datau8.count > 0 ? datau8[0]:20
            if value == UInt8(1) {
                self.showAlertMessage(title: "Button Event", message: "Device Buton Pressed")
            }
        case Config.characReadWriteData:
            self.verifyConfigration(data)
        default:
            break
        }
    }
    
    func verifyConfigration(_ data:Data) {
        if data.count >= 44 {
            let uuidString = String(data: Data(Array<UInt8>(data)[0...31]), encoding: .utf8) ?? ""
            let mjArray = (String(data: Data(Array(Array<UInt8>(data)[32...35])), encoding: .utf8) ?? "").map{$0.hexDigitValue ?? 0}
            let major = mjArray[0] * 16 * 16 * 16 + mjArray[1] * 16 * 16 + mjArray[2] * 16 + mjArray[3]
            let miArray = (String(data: Data(Array(Array<UInt8>(data)[36...39])), encoding: .utf8) ?? "").map{$0.hexDigitValue ?? 0}
            let minor = miArray[0] * 16 * 16 * 16 + miArray[1] * 16 * 16 + miArray[2] * 16 + miArray[3]
            //let tiArray = (String(data: Data(Array(Array<UInt8>(data)[40...43])), encoding: .utf8) ?? "").map{$0.hexDigitValue ?? 0}
            //let interval = tiArray[0] * 16 * 16 * 16 + tiArray[1] * 16 * 16 + tiArray[2] * 16 + tiArray[3]
            //print("mjArray:\(mjArray), miArray:\(miArray), tiArray:\(tiArray)")
            let bConfig = Config.getBeaconData(identifier: peripheral.identifier.uuidString)
            
            self.showAlertMessage(title: "", message: "Beacon Configured Successfully")
            if uuidString == bConfig.uuidString.replacingOccurrences(of: "-", with: "").uppercased() && major == bConfig.major && bConfig.minor == minor {
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.showAlertMessage(title: "Relaunch Your App", message: "")
                }
                                
                DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                    print("iBeacon Will Start Monitering")
                    //exit(0)
                    self.startBeacon()
                }
            }
        }
    }
}

//MARK: - Supporting CB Methods
extension BeaconViewController {
    func didDiscoverdAllCharacteristics() -> Bool  {
        processServicesDiscovery -= 1
        if processServicesDiscovery == 0 {
            logServices()
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
extension BeaconViewController {
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
            self.showAlertMessage(title: "", message: "Error didReadRSSI : \(error!.localizedDescription)")
            print("Error RSSI: \(error?.localizedDescription ?? "")")
        } else {
            print("didReadRSSI: \(RSSI)")
        }
    }
    
    func logDidUpdateValueFor(_ error: Error?, _ characteristic: CBCharacteristic) {
        if error != nil {
            self.showAlertMessage(title: "Error", message: error!.localizedDescription)
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
            self.showAlertMessage(title: "Error Writing", message: error!.localizedDescription)
            print("Write Error:\(error?.localizedDescription ?? "")")
        } else {
            self.showAlertMessage(title: "Success Data Write", message: "Success Data Write to Device Characteristic:\(characteristic.uuid.uuidString)")
            //print("Success Data Write to Device Charis:\(characteristic.uuid.uuidString)")
        }
    }
}

// Distance 
extension BeaconViewController {
    func locationString(_ beacon:CLBeacon?) -> String {
        
        func nameForProximity(_ proximity: CLProximity) -> String {
            switch proximity {
            case .unknown:
                return "Unknown"
            case .immediate:
                return "Immediate"
            case .near:
                return "Near"
            case .far:
                return "Far"
            }
        }
        
        guard let beacon = beacon else { return "Location: Unknown" }
        
        let proximity = nameForProximity(beacon.proximity)
        let accuracy = String(format: "%.2f", beacon.accuracy)
        
        var location = "Location: \(proximity)"
        if beacon.proximity != .unknown {
            location += " (approx. \(accuracy)m)"
        }
        
        return location
    }
    
    
    func calculateNewDistance(txCalibratedPower: Int, rssi: Int) -> Double {
        if rssi == 0 {
            return -1
        }
        let ratio = Double(exactly:rssi)!/Double(txCalibratedPower)
        if ratio < 1.0 {
            return pow(10.0, ratio)
        } else {
            let accuracy = 0.89976 * pow(ratio, 7.7095) + 0.111
            return accuracy
        }
    }
}
