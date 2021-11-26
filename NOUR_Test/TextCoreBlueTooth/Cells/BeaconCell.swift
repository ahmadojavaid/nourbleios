//
//  BeaconCell.swift
//  TextCoreBlueTooth
//
//  Created by abbas on 4/15/20.
//  Copyright © 2020 abbas. All rights reserved.
//

import UIKit
import CoreBluetooth
//import CoreLocation

class BeaconCell: UITableViewCell {
    
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblID: UILabel!
    @IBOutlet weak var btnConnect: UIButton!
    
    @IBOutlet weak var beaconViewHeight: NSLayoutConstraint!
    @IBOutlet weak var btnBuzzer: UIButton!
    @IBOutlet weak var lblBattery: UILabel!
    @IBOutlet weak var lblBeacon: UILabel!
    
    //var locationManager = CLLocationManager()
    
    weak var navigationController:UINavigationController?
    
    var nConfigure = 0
    var nTries = 0
    var processServicesDiscovery = 0
    var peripheral:CBPeripheral!
    var serviceDiscoveryState = 0
    
    override func awakeFromNib() {
        super.awakeFromNib()
        //locationManager.startMonitoringSignificantLocationChanges()
        initialCongigration()
    }
    
    @objc func btnBuzzer_pressed(_ sender:UIButton) {
        disableShortly(sender)
        writeValue(characUUID: Config.characSound, data: Data(Array<UInt8>([1])))
    }
}



//MARK:- Peripheral Delegate Methods
extension BeaconCell:CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        //discoverCharacteristics()
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if didDiscoverdAllCharacteristics() {
            topVC()?.showAlertMessage(title: "", message: "Subscribing Notifications...")
            enableNotification()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.topVC()?.showAlertMessage(title: "", message: "Sending Confgration String...")
                //self.configureBeacon()
            }
        }
    }
}

//MARK:- Peripheral Delegate Data Methods
extension BeaconCell {
    func peripheral(_ peripheral: CBPeripheral,  didUpdateValueFor characteristic: CBCharacteristic, error: Error?){
        processDidUpdateValueFor(error, characteristic)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        logDidWriteValueFor(error, characteristic)
    }
    
    // RSSI was read : signal power
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        logDidReadRSSI(error, RSSI)
        if error != nil { topVC()?.showAlertMessage(title: "", message: "didReadRSSI: \(RSSI)") }
    }
}
/*
extension BeaconCell:CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .denied, .restricted:
            topVC()?.showAlertMessage(title: "", message: "******** User not authorized to access phone location!!!!")
            print("User Denayed Access for location")
        case .authorizedAlways, .authorizedWhenInUse:
            print("iBeacon Starting....")
            self.startBeacon()
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        manager.requestState(for: region)
    }
    
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        let uuid  = UUID(uuidString: Config.getBeaconData(identifier: peripheral.identifier.uuidString).uuidString)!
        if state == .inside {
            manager.startRangingBeacons(satisfying: CLBeaconIdentityConstraint(uuid: uuid))
            return
        }
        manager.stopRangingBeacons(satisfying: CLBeaconIdentityConstraint(uuid: uuid))
    }
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        
        let config = Config.getBeaconData(identifier: peripheral.identifier.uuidString)
        
        let nbeacon = beacons.first { Int(truncating: $0.minor) == config.minor }
        
        if nbeacon == nil {
            lblBeacon.text = "No beacon found!"
        } else  {
            let dist = (nbeacon?.rssi ?? 0)
            //let distance = round((dist > 0 ? dist:0) * 100) / 100
            
            lblBeacon.text = "UUID: \(nbeacon?.uuid.uuidString ?? "") \nMajor: \(nbeacon?.major ?? 0), Minor:\(nbeacon?.minor ?? 0), \nDistance: \(dist > 0 ? dist:(-dist))"
        }
    }
}
*/
/*
//MARK: - Beacon Configration
extension BeaconCell {
    func configureBeacon(){
        print("BTN Configration Did Pressed")
        topVC()?.view.isUserInteractionEnabled = false
        //Config.setConfigData(identifier: peripheral.identifier.uuidString ?? "",
        //                    uuidString: txtUUID.text ?? "",
        //                     major: ((txtMajor.text ?? "0") as NSString).integerValue,
        //                     minor: ((txtMinor.text ?? "0") as NSString).integerValue)
        let configData = Config.getBeaconData(identifier: peripheral.identifier.uuidString )
        
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            print("Configration String Did Send")
            let data = self.encodeConfigData(uuidString: configData.uuidString,
                                             major: configData.major,
                                             minor: configData.minor,
                                             interval: Config.interval)
            
            self.writeValue(characUUID: Config.characReadWriteData, data: data)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.topVC()?.showAlertMessage(title: "", message: "Reading Device Configration...")
            // send command code: 5 to read config data
            print("Read Configration Command 0x05 Did Sent")
            self.writeValue(characUUID: Config.characWriteCommand, data: Data(Array<UInt8>([5])))
            self.topVC()?.view.isUserInteractionEnabled = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            self.topVC()?.showAlertMessage(title: "", message: "Verifying Configration...")
            print("Request Read Configration Did Sent")
            self.blueRead(characUUID: Config.characReadWriteData)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.5) {
            self.topVC()?.showAlertMessage(title: "", message: "Starting iBeacon Service...")
            print("iBeacon Will Start Monitering")
            self.startBeacon()
        }
    }
    
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
}
*/
