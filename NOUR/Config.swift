//
//  Config.swift
//  TextCoreBlueTooth
//
//  Created by abbas on 3/25/20.
//  Copyright © 2020 abbas. All rights reserved.
//

import Foundation
import CoreBluetooth

class Config: NSObject {
    
    static let peripheralService = "edfec62e-9910-0bac-5241-d8bda6932a2f"
    static let readWriteDataCharac = "772AE377-B3D2-4F8E-4042-5481D1E0098C"
    static let writeCommandCharac = "2D86686A-53DC-25B3-0C4A-F0E10C8DEE20" // Instructions Send byte [0] = 0x05 instruction
    static let buttonStateCharac = "6C290D2E-1C03-ACA1-AB48-A9B908BAE79E"  // Notification: press: 0x00, release: 0x01
    
    static let buzzerService = "0x1802" //, "1802")
    static let buzzerCharac = "0x2A06" //, "2A06") // Write Value = 0x01 or 0x02. The buzzer will sound.
    
    static let batteryService = "0x180F" //, "180F")
    static let batteryCharac = "0x2A19" //, "2A19") // Enable Notify. to display service
    
    static func getBeaconData(identifier:String) -> (uuidString:String, major:Int, minor:Int) {
        
        let id = identifier.uppercased()
        
        var uuid = ""
        if let uid = UserDefaults.standard.string(forKey: "uuidString") {
            uuid = uid
        } else {
            uuid = UUID().uuidString
            UserDefaults.standard.set(uuid, forKey: "uuidString")
        }
                
        let major:Int = 10
        
        var minor = UserDefaults.standard.integer(forKey: id + "minor")
        if minor == 0 {
            minor = UserDefaults.standard.integer(forKey: "CMINOR") + 1
            UserDefaults.standard.set(minor, forKey: "CMINOR")
            UserDefaults.standard.set(minor,forKey: id + "minor")
        }
        return (uuid, major, minor)
    }
    //static func setConfigData(identifier:String, uuidString:String, major:Int, minor:Int){
    //    UserDefaults.standard.set(uuidString, forKey: "uuidString")
    //    UserDefaults.standard.set(major, forKey: identifier.uppercased() + "major")
    //    UserDefaults.standard.set(minor, forKey: identifier.uppercased() + "minor")
    //}
    //static var iBeaconService = "2f234454-cf6d-4a0f-adf2-f4911ba9ffa7"
    //static var major = 1
    //static var minor = 2
    static var interval = 500
}
