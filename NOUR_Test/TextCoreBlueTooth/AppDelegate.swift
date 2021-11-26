//
//  AppDelegate.swift
//  TextCoreBlueTooth
//
//  Created by abbas on 3/14/20.
//  Copyright © 2020 abbas. All rights reserved.
//

import UIKit
import CoreLocation
import CoreBluetooth
import AVFoundation

//import SwiftyBeaver
//let log = SwiftyBeaver.self


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var uuid:UUID {
        return UUID(uuidString: Config.getBeaconData(identifier: "Default").uuidString)! // update it
    }
    
    static var shared:AppDelegate? {
        return (UIApplication.shared.delegate as? AppDelegate)
    }
    
    let locationManager = CLLocationManager()
    var alarmSound: AVAudioPlayer?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        //configureForRemoteLog()
        locationManagerSetup()
        beaconSetup()
        notificatinoSetup()
        return true
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

//MARK: - CLocationManager Delegate Methods
extension AppDelegate: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways:
            print("authorizedAlways")
        case .authorizedWhenInUse:
            print("authorizedWhenInUse")
        case .denied:
            print("denied")
        case .restricted:
            print("restricted")
        case .notDetermined:
            print("notDetermined")
        @unknown default:
            print("default")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        manager.requestState(for: region)
    }
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
    }
    
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        
        switch state {
        case .inside:
            let beaconState = UserDefaults.standard.integer(forKey: "BeaconState")
            //if  beaconState != 0 && beaconState != 1 {
                self.scheduleNotification(title: "Beacon Detected", body: "Phone is inside the iBeacon reagion.", isDefauld: true)
            //}
            UserDefaults.standard.set(1, forKey: "BeaconState")
        case .outside:
            let beaconState = UserDefaults.standard.integer(forKey: "BeaconState")
            //if  beaconState != 0 && beaconState != 2 {
                manager.requestLocation()
                loadAndPlayAlarm()
                self.scheduleNotification(title: "Beacon Exit", body: "Phone is outside the iBeacon region.")
                UserDefaults.standard.set(false, forKey: "isInside")
            //}
            UserDefaults.standard.set(2, forKey: "BeaconState")
        case .unknown:
            //let beaconState = UserDefaults.standard.integer(forKey: "BeaconState")
            //if  beaconState != 0 && beaconState != 3 {
            //    self.scheduleNotification(title: "Beacon is Far", body: "Phone is far from the iBeacon with unknown distance.", isDefauld: true)
            //}
            //UserDefaults.standard.set(3, forKey: "BeaconState")
            break
        }
        let identity = CLBeaconIdentityConstraint(uuid: self.uuid)
        if state == .inside {
            manager.startRangingBeacons(satisfying: identity)
            //manager.startRangingBeacons(in: region as! CLBeaconRegion)
        } else {
            //manager.stopRangingBeacons(in: region as! CLBeaconRegion)
            manager.stopRangingBeacons(satisfying: identity)
        }
        
 
    }
    
    func locationManager(_ manager: CLLocationManager, didRange beacons: [CLBeacon], satisfying beaconConstraint: CLBeaconIdentityConstraint) {
        let nearestBeacon = beacons.first
        if beacons.count > 0 {
            //print("Found With proximaty: \(nearestBeacon?.proximity), Beacon: \(nearestBeacon)")
        }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("\(locations[0].coordinate)")
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error Updating Location:" + error.localizedDescription)
    }
}


//extension NSObject {
//    func print(_ str:String) {
//        NSLog(str)
//        log.info(str + "\n")
//    }
//}

extension AppDelegate {
    func beaconSetup(){
        let beaconRegion: CLBeaconRegion = CLBeaconRegion(uuid: uuid, identifier: "IBCard!")
        beaconRegion.notifyEntryStateOnDisplay = true
        beaconRegion.notifyOnExit = true
        beaconRegion.notifyOnEntry = true
        
        self.locationManager.delegate = self
        self.locationManager.startMonitoring(for: beaconRegion)
    }
    
    func locationManagerSetup(){
        locationManager.requestAlwaysAuthorization()
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
}

fileprivate extension AppDelegate {
    
    func loadAndPlayAlarm(){
        do {
             try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playAndRecord, options: [.duckOthers, .defaultToSpeaker])
             try AVAudioSession.sharedInstance().setActive(true)
            UIApplication.shared.beginReceivingRemoteControlEvents()
        } catch {
             NSLog("Audio Session error: \(error)")
        }
        
        let path = Bundle.main.path(forResource: "Alarm2.mp3", ofType:nil)!
        let url = URL(fileURLWithPath: path)
        do {
            alarmSound = try AVAudioPlayer(contentsOf: url)
            alarmSound?.play()
        } catch {
            // couldn't load file :(
        }
    }
    
    func notificatinoSetup(){
        
        let notificationCenter = UNUserNotificationCenter.current()
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        notificationCenter.requestAuthorization(options: options) {
            (didAllow, error) in
            if !didAllow {
                print("User has declined notifications")
            }
        }
        /* To check if user authorized to notify user
        notificationCenter.getNotificationSettings { (settings) in
          if settings.authorizationStatus != .authorized {
            // Notifications not allowed
          }
        }
        */
    }
    
    func scheduleNotification(title:String, body: String, isDefauld:Bool = false) {
        let notificationCenter = UNUserNotificationCenter.current()
        
        let content = UNMutableNotificationContent() // Содержимое уведомления
        content.title = title
        content.body = body
        content.badge = (UIApplication.shared.applicationIconBadgeNumber + 1) as NSNumber
        if isDefauld {
            content.sound = UNNotificationSound.default
        } else {
            let sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "Alarm2.mp3"))
            content.sound = sound
        }
        
        //Create a trigger from date components
        let date = Date(timeIntervalSinceNow: 2)
        let triggerDate = Calendar.current.dateComponents([.hour,.minute,.second,], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        //let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: false)
        /*
        //To send notifications weekly at the same time, we need weekday days of the week
        let date = Date(timeIntervalSinceNow: 3600)
        let triggerWeekly = Calendar.current.dateComponents([.weekday, .hour, .minute, .second,], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerWeekly, repeats: true)
        //Send notification by location
        //This trigger is triggered at the moment when the user enters a specific location or vice versa leaves it. The location is determined by CoreLocation using CLRegion:
        let trigger = UNLocationNotificationTrigger(triggerWithRegion: region, repeats:false)
        //let trigger = UNLocationNotificationTrigger(triggerWithRegion: region, repeats:false)
        */
        
        let identifier = "Local Notification"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        notificationCenter.add(request) { (error) in
            if let error = error {
                print("Error \(error.localizedDescription)")
            }
        }
    }
    /*
    func configureForRemoteLog() {
        // add log destinations. at least one is needed!
        let console = ConsoleDestination()  // log to Xcode Console
        let file = FileDestination()  // log to default swiftybeaver.log file
        let cloud = SBPlatformDestination(appID: "LQnBL0",
                                          appSecret: "szOWgilabnu9q4pgdjswwr6kEengtabf",
                                          encryptionKey: "1wo0zJWxegvuxdfBZ5IbsPtdzoZkkhns") // to cloud
        // use custom format and set console output to short time, log level & message
        console.format = "$DHH:mm:ss$d $L $M"
        // or use this for JSON output: console.format = "$J"
        // add the destinations to SwiftyBeaver
        log.addDestination(console)
        log.addDestination(file)
        log.addDestination(cloud)
    }
    */
}

//MARK: - Supporting Methods

extension AppDelegate {
    class func getCurrentVC() -> UIViewController? {

        // If the root view is a navigation controller, we can just return the visible ViewController
        if let navigationController = getNavigationController() {

            return navigationController.visibleViewController
        }
        // Otherwise, we must get the root UIViewController and iterate through presented views
        if let rootController = UIApplication.shared.keyWindow?.rootViewController {

            var currentController: UIViewController! = rootController

            // Each ViewController keeps track of the view it has presented, so we
            // can move from the head to the tail, which will always be the current view
            while( currentController.presentedViewController != nil ) {

                currentController = currentController.presentedViewController
            }
            return currentController
        }
        return nil
    }

    // Returns the navigation controller if it exists
    class func getNavigationController() -> UINavigationController? {

        if let navigationController = UIApplication.shared.keyWindow?.rootViewController  {

            return navigationController as? UINavigationController
        }
        return nil
    }
}
