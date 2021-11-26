//
//  BeaconViewController.swift
//  TextCoreBlueTooth
//
//  Created by abbas on 3/25/20.
//  Copyright © 2020 abbas. All rights reserved.
//

import UIKit
import CoreBluetooth
import CoreLocation

class BeaconViewController: UIViewController {
    
    var peripheral:CBPeripheral!
    
    //var cell:DeviceTableViewCell!
    
    @IBOutlet weak var txtUUID: UITextField!
    @IBOutlet weak var txtMajor: UITextField!
    @IBOutlet weak var txtMinor: UITextField!
    
    @IBOutlet weak var lblStatus: UILabel!
    @IBOutlet weak var lblUUID: UILabel!
    @IBOutlet weak var lblMajor: UILabel!
    @IBOutlet weak var lblMinor: UILabel!
    @IBOutlet weak var lblSNR: UILabel!
    
    @IBOutlet weak var btnBattery: UIButton!
    @IBOutlet weak var btnCardBtn: UIButton!
    
    var processServicesDiscovery = 0
    var beacons: [CLBeacon] = []
    var locationManager: CLLocationManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setData()
        initialCongigration()
        discoverServices()
        self.view.isUserInteractionEnabled = false
        //ibeaconConfigration()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    //override func viewWillDisappear(_ animated: Bool) {
    //    super.viewWillDisappear(animated)
        //AppDelegate.shared?.locationManagerSetup()
        //AppDelegate.shared?.beaconSetup()
    //}
    
    @IBAction func btnBattery_pressed(_ sender: UIButton) {
        disableShortly(sender)
        blueSetNotify(characteristicUUID: Config.characBatteryLevel)
    }
    
    @IBAction func btnCardBtn_pressed(_ sender: UIButton) {
        disableShortly(sender)
        blueSetNotify(characteristicUUID: Config.characButtonState)
    }
    
    @IBAction func btnBuzzer(_ sender: UIButton) {
        disableShortly(sender)
        let data = [UInt8(2)]
        //Array<UInt8>([1])[0]
        let ddd = Data(data)
        //let dd = data[0]
        writeValue(serviceUUID: Config.buzzerService, characUUID: Config.characSound, data: ddd)
    }
    
    @IBAction func btnConfigure(_ sender: UIButton) {
        disableShortly(sender)
        configureBeacon()
    }
}

extension BeaconViewController:CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        discoverCharacteristics()
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if didDiscoverdAllCharacteristics() {
            self.view.isUserInteractionEnabled = true
            //self.showAlertMessage(title: "", message: "Subscribing Notifications...")
            //enableNotification()
            //DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            //    self.showAlertMessage(title: "", message: "Sending Confgration String...")
            //self.configureBeacon()
            //}
        }
    }
}

//MARK:- Peripheral Delegate Data Methods
extension BeaconViewController {
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            self.showAlertMessage(title: "Error Enabling Notification", message: error.localizedDescription)
        } else {
            self.showAlertMessage(title: "Success Notification Enabled", message: "Notification Enabled Successfully for Characteristic \(characteristic.uuid)")
            self.blueRead(characUUID: characteristic.uuid)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral,  didUpdateValueFor characteristic: CBCharacteristic, error: Error?){
        processDidUpdateValueFor(error, characteristic)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        logDidWriteValueFor(error, characteristic)
    }
    
    // RSSI was read : signal power
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        logDidReadRSSI(error, RSSI)
        if error != nil { self.showAlertMessage(title: "", message: "didReadRSSI: \(RSSI)") }
    }
}

extension BeaconViewController:CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .denied, .restricted:
            self.showAlertMessage(title: "", message: "******** User not authorized to access phone location!!!!")
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
            lblStatus.text = "No beacon found!"
        } else  {
            lblStatus.text = "iBeacon Detected With:"
            let dist = (nbeacon?.rssi ?? 0)
            let distance = dist > 0 ? dist:-dist
            
            lblUUID.text = "UUID: \(nbeacon?.uuid.uuidString ?? "")"
            lblMajor.text = "Major: \(nbeacon?.major ?? 0)"
            lblMinor.text = "Minor: \(nbeacon?.minor ?? 0)"
            lblSNR.text = "Distance: \(distance)"
            //lblBeacon.text = "UUID: \(nbeacon?.uuid.uuidString ?? "") \nMajor: \(nbeacon?.major ?? 0), Minor:\(nbeacon?.minor ?? 0), \nDistance: \(dist > 0 ? dist:(-dist))"
        }
    }
 
}

//MARK: - Beacon Configration
extension BeaconViewController {
    func configureBeacon(){
        print("BTN Configration Did Pressed")
        self.view.isUserInteractionEnabled = false
        //Config.setConfigData(identifier: peripheral.identifier.uuidString ?? "",
        //                    uuidString: txtUUID.text ?? "",
        //                     major: ((txtMajor.text ?? "0") as NSString).integerValue,
        //                     minor: ((txtMinor.text ?? "0") as NSString).integerValue)
        
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            let configData = Config.getBeaconData(identifier: self.peripheral.identifier.uuidString )
            self.showAlertMessage(title: "", message: "Sending Congfigration Data...")
            print("Configration String Did Send")
            let data = self.encodeConfigData(uuidString: configData.uuidString,
                                             major: configData.major,
                                             minor: configData.minor,
                                             interval: Config.interval)
            
            //self.writeValue(characUUID: Config.characReadWriteData, data: data)
            self.writeValue(serviceUUID: Config.peripheralService, characUUID: Config.characReadWriteData, data: data, responseOption: .withResponse)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.showAlertMessage(title: "", message: "Reading Device Configration...")
            // send command code: 5 to read config data
            print("Read Configration Command 0x05 Did Sent")
            self.writeValue(serviceUUID: Config.peripheralService, characUUID: Config.characWriteCommand, data: Data(Array<UInt8>([5])), responseOption: .withResponse)
            self.view.isUserInteractionEnabled = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
            self.showAlertMessage(title: "", message: "Verifying Configration...")
            print("Request Read Configration Did Sent")
            self.blueRead(characUUID: Config.characReadWriteData)
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
    
    func startBeacon() -> Void {
        locationManager?.delegate = self
        let configData =  Config.getBeaconData(identifier: peripheral.identifier.uuidString)
        
        let beaconRegion: CLBeaconRegion = CLBeaconRegion(uuid: UUID(uuidString: configData.uuidString) ?? UUID(), identifier: "")
        
        beaconRegion.notifyEntryStateOnDisplay = true
        //beaconRegion.notifyOnExit = true
        //beaconRegion.notifyOnEntry = true
        
        //locationManager?.stopMonitoring(for: beaconRegion)
        locationManager?.startMonitoring(for: beaconRegion)
    }
}

