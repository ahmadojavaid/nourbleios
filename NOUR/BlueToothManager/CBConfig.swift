//
//  CBConfig.swift
//  NOUR
//
//  Created by abbas on 7/4/20.
//  Copyright © 2020 abbas. All rights reserved.
//

import UIKit
import CoreBluetooth

class CBConfig: NSObject {
    
    static let peripheralService = CBUUID(string: "edfec62e-9910-0bac-5241-d8bda6932a2f")
    
    static let readWriteDataCharac = CBUUID(string: "772AE377-B3D2-4F8E-4042-5481D1E0098C")
    static let writeCommandCharac = CBUUID(string: "2D86686A-53DC-25B3-0C4A-F0E10C8DEE20") // Instructions Send byte [0] = 0x05 instruction
    static let buttonStateCharac = CBUUID(string: "6C290D2E-1C03-ACA1-AB48-A9B908BAE79E")  // Notification: press: 0x00, release: 0x01
    
    static let buzzerService = CBUUID(string: "0x1802") //
    static let buzzerCharac = CBUUID(string: "0x2A06")  // Write Value = 0x01 or 0x02. The buzzer will sound.
    
    static let batteryService = CBUUID(string: "0x180F")//
    static let batteryCharac = CBUUID(string: "0x2A19") // Enable Notify. to display service
    
    static let servicesSet = Set( [CBConfig.peripheralService, CBConfig.buzzerService, CBConfig.batteryService ])
    static let characSet = Set([CBConfig.readWriteDataCharac, CBConfig.writeCommandCharac, CBConfig.buttonStateCharac, CBConfig.buzzerCharac, CBConfig.batteryCharac])
    
    static let chars:[CBUUID:[CBUUID]] = [
        peripheralService:[readWriteDataCharac, writeCommandCharac],
        buzzerService:[buzzerCharac],
        batteryService:[batteryCharac]
    ]
    
    static let charsSet:[CBUUID:Set<CBUUID>] = [
        peripheralService:Set([readWriteDataCharac, writeCommandCharac]),
        buzzerService:Set([buzzerCharac]),
        batteryService:Set([batteryCharac])
    ]
    
    static let interval = 500
    
}

extension CBPeripheral {
    fileprivate func isServicesDiscoverd() -> Bool {
        let servicesSet = Set((services ?? []).map({$0.uuid}))
        for (key, _) in CBConfig.chars {
            if !servicesSet.contains(key) {
                return false
            }
        }
        return true
    }
    
    func isDiscoverd() -> Int {
        guard self.isServicesDiscoverd() else {
            return -1
        }
        for service in (services ?? []) {
            let chars = Set(service.characteristics?.map({$0.uuid}) ?? [])
            for chr in CBConfig.chars[service.uuid] ?? [] {
                if !chars.contains(chr) {
                    return 0
                }
            }
        }
        return 1
    }
}
