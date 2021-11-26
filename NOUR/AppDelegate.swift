//
//  AppDelegate.swift
//  NOUR
//
//  Created by abbas on 6/1/20.
//  Copyright © 2020 abbas. All rights reserved.
//

import UIKit
import IQKeyboardManagerSwift
import RealmSwift
//import SwiftyBluetooth
import CoreBluetooth
import CoreLocation
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    fileprivate var id = -1
    fileprivate var identifier:String = ""
    var bleManager:BLEManager!
    
    let uiRealm = try! Realm()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        FirebaseApp.configure()
        bleManager = BLEManager.shared
        if LocationManager.shared.isAuthorized() == false {
            LocationManager.shared.requestAuthoriztion { (isSuccess, message) in
                self.startMonitoring()
            }
        } else {
            self.startMonitoring()
        }
        
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.toolbarTintColor = Theme.Colors.tint
        notificatinoSetup()
        BLEManager.shared.configure()
        
        //bluetoothInitialSetup()
        //scanPeripherals()
        return true
    }
    
    func readRSSI() {
        //if id < 0 {
        for i in 0..<BLEManager.shared.myPeripherals.count {
            BLEManager.shared.myPeripherals[i].readRSSI(completion: readRSSICompletion(_:_:_:_:))
        }
        //} else  {
        //    BLEManager.shared.myPeripherals[id].readRSSI(completion: readRSSICompletion(_:_:_:_:))
        //}
    }
    
    func readRSSICompletion(_ isSuccess:Bool, _ rssi:Int?, _ identifier:String, _ message:String) -> Bool {
        
        self.id = BLEManager.shared.getPeripheralID(by: identifier) ?? -1
        if isSuccess {
            print("ID: \(identifier): \(rssi ?? 0)")
        } else {
            print("ID: " + message)
        }
        print("ID: \(self.id)")
        //Dispatch.DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
        //    self.readRSSI()
        //}
        return false
    }
    
    func startMonitoring() {
        LocationManager.shared.monitorRegions { (isSuccess, state, identifier) in
            switch state {
            case .outside:
                Product.updateStatus(identifier: identifier, status: "2")
                LocationManager.shared.getCurrontLocation { (isSuccess, location, identifier) in
                    if isSuccess, let location = location {
                        Product.updateLocationWith(
                            identifier: identifier,
                            latitude:CGFloat(location.coordinate.latitude),
                            longitude: CGFloat(location.coordinate.longitude))
                    }
                    //NotificationCenter.default.post(name: Notification.Name.LocationDidUpdated, object: nil)
                    
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                    let product = Product.getProductby(identifier: identifier)
                    if product?.status == "2" {
                        NotificationManager.shared.scheduleNotification(title:"Remember!", body: "\(product?.name ?? product?.type ?? "") is not with you.", isDefauld:false)
                    }
                }
                print("Outside Region")
            case .inside:
                Product.updateStatus(identifier: identifier, status: "1")
                LocationManager.shared.getCurrontLocation { (isSuccess, location, message) in
                    if isSuccess, let location = location {
                        Product.updateLocations(
                            latitude: CGFloat(location.coordinate.latitude),
                            longitude: CGFloat(location.coordinate.longitude)
                        )
                        //NotificationCenter.default.post(name: Notification.Name.LocationDidUpdated, object: nil)
                    }
                }
                print("Inside Region")
            case .unknown:
                print("Knknown Region")
            }
        }
    }
}

extension AppDelegate:UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if UIApplication.shared.applicationIconBadgeNumber > 0 {
            completionHandler([.alert])
            center.removeAllDeliveredNotifications()
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if UIApplication.shared.applicationIconBadgeNumber > 0 {
            center.removeAllDeliveredNotifications()
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
        completionHandler()
    }
}

/*
 //MARK: - BLUETOOTH SETUP
 fileprivate extension AppDelegate {
 
 func bluetoothInitialSetup() {
 SwiftyBluetooth.setSharedCentralInstanceWith(restoreIdentifier: "NOUR_FRIDAY_JUNE_26_2020")
 NotificationCenter.default.addObserver(forName: Central.CentralManagerWillRestoreState, object: Central.sharedInstance, queue: nil, using: restoreState(notification:))
 }
 
 @objc func restoreState(notification:Notification) {
 if let restoredPeripherals = notification.userInfo?["peripherals"] as? [Peripheral] {
 for perifri in restoredPeripherals {
 if perifri.name?.uppercased().contains("BEACON") == true {
 BLEManager.shared.add(peripheral: perifri)
 }
 print("restored Peripheral: \(perifri)")
 }
 }
 }
 
 func scanPeripherals(){
 let uuids = Product.getAllProducts().products.map { product -> String in
 return product.id
 }
 
 SwiftyBluetooth.scanForPeripherals(withServiceUUIDs: [CBUUID(string: "0x1802")], options: nil, timeoutAfter: 10) { (scanResult) in
 switch scanResult {
 case .scanStarted: break
 case .scanResult(let peripheral, let advertisementData, _):
 if uuids.contains(peripheral.identifier.uuidString) {
 let isInManager = BLEManager.shared.myPeripherals.contains { (perifri) -> Bool in
 perifri.identifier == peripheral.identifier
 }
 if !isInManager {
 BLEManager.shared.add(peripheral: peripheral)
 }
 }
 case .scanStopped(let error): break
 }
 }
 }
 }
 */


fileprivate extension AppDelegate {
    func notificatinoSetup(){
        
        UNUserNotificationCenter.current().delegate = self
        
        let notificationCenter = UNUserNotificationCenter.current()
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        notificationCenter.requestAuthorization(options: options) {
            (didAllow, error) in
            if !didAllow {
                print("User has declined notifications")
            }
        }
    }
}
