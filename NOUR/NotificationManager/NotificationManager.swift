//
//  NotificationManager.swift
//  NOUR
//
//  Created by abbas on 7/2/20.
//  Copyright © 2020 abbas. All rights reserved.
//

import UIKit

class NotificationManager: NSObject {
    static var shared = NotificationManager()
    /*
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
    */
    override init() {
        super.init()
        self.notificatinoSetup()
    }
    fileprivate func notificatinoSetup(){
        
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
    
}
