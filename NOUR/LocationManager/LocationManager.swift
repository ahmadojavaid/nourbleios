//
//  LocationManager.swift
//  NOUR
//
//  Created by abbas on 7/2/20.
//  Copyright © 2020 abbas. All rights reserved.
//

import UIKit
import CoreLocation

class LocationManager: NSObject {
    
    static var shared = LocationManager()
    
    var locationManager:CLLocationManager
    
    var completionGetLocation: ((Bool, CLLocation?, String) -> Void)?
    var completionRequestAuth: ((Bool, String) -> Void)?
    var completionRegionMonitor: ((Bool, CLRegionState, String) -> Void)?
    
    var regions:Set<CLRegion> {
        return locationManager.monitoredRegions
    }
    
    override init() {
        locationManager = CLLocationManager()
        super.init()
        initialCongigration()
    }
    
    func getCurrontLocation(completion completionGetLocation: ((Bool, CLLocation?, String)->Void)?){
        self.completionGetLocation = completionGetLocation
        if isAuthorized() {
            self.locationManager.requestLocation()
        } else {
            requestAuthoriztion { (isSuccess, message) in
                if isSuccess {
                    self.locationManager.requestLocation()
                } else {
                    self.completionGetLocation?(false, nil, message)
                }
            }
        }
    }
    
    func monitorRegions(completion completionRegionMonitor: ((Bool, CLRegionState, String) -> Void)?){
        if let completion = completionRegionMonitor {
            self.completionRegionMonitor = completion
        }
        if isAuthorized() {
            self.monitorRegions()
        } else {
            requestAuthoriztion { (isSuccess, message) in
                if isSuccess {
                    self.monitorRegions()
                } else {
                    self.completionRegionMonitor?(false, .unknown, "")
                }
            }
        }
    }
    
}

// location authorization delegate
extension LocationManager:CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .denied, .restricted:
            if let completion = self.completionRequestAuth {
                completion(false, "App is not authorized to access phone location")
            }
            print("User Denayed Access for location")
        case .authorizedAlways, .authorizedWhenInUse:
            if let completion = self.completionRequestAuth {
                completion(true, "Location access granted")
            }
        //self.startBeacon()
        default:
            break
        }
    }
}
// gps location access delegates
extension LocationManager {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.completionGetLocation?(true, locations[0], "Location updated")
        print("\(locations[0].coordinate)")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.completionGetLocation?(false, nil, error.localizedDescription)
        print("Error Updating Location:" + error.localizedDescription)
    }
}

// Region Monitoring delegates
extension LocationManager {
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        manager.requestState(for: region)
    }
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        /*
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
         */
    }
    
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        
        self.completionRegionMonitor?(true, state, region.identifier)
        switch state {
        case .inside: break
            //let beaconState = UserDefaults.standard.integer(forKey: "BeaconState")
            //if  beaconState != 0 && beaconState != 1 {
            //self.scheduleNotification(title: "Beacon Detected", body: "Phone is inside the iBeacon reagion.", isDefauld: true)
            //}
        //UserDefaults.standard.set(1, forKey: "BeaconState")
        case .outside: break
            //let beaconState = UserDefaults.standard.integer(forKey: "BeaconState")
            //if  beaconState != 0 && beaconState != 2 {
            //manager.requestLocation()
            //loadAndPlayAlarm()
            //self.scheduleNotification(title: "Beacon Exit", body: "Phone is outside the iBeacon region.")
            //UserDefaults.standard.set(false, forKey: "isInside")
            //}
        //UserDefaults.standard.set(2, forKey: "BeaconState")
        case .unknown: break
            //let beaconState = UserDefaults.standard.integer(forKey: "BeaconState")
            //if  beaconState != 0 && beaconState != 3 {
            //    self.scheduleNotification(title: "Beacon is Far", body: "Phone is far from the iBeacon with unknown distance.", isDefauld: true)
            //}
            //UserDefaults.standard.set(3, forKey: "BeaconState")
            break
        }
        //let uuid  = UUID(uuidString: Config.getBeaconData(identifier: peripheral.identifier.uuidString).uuidString)!
        /*
         var identity:CLBeaconIdentityConstraint!
         if #available(iOS 13.0, *) {
         identity = CLBeaconIdentityConstraint(uuid: UUID()) //uuid)
         } else {
         
         }
         if state == .inside {
         manager.startRangingBeacons(satisfying: identity)
         return
         }
         manager.stopRangingBeacons(satisfying: identity)
         */
    }
}

// supporitng methods
extension LocationManager{
    func isAuthorized() -> Bool {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse, .authorizedAlways:
            return true
        default:
            return false
        }
    }
    
    func requestAuthoriztion(completion completionRequestAuth: ((Bool, String)->Void)?){
        
        self.completionRequestAuth = completionRequestAuth
        switch CLLocationManager.authorizationStatus() {
        case .denied, .restricted:
            self.completionRequestAuth?(false, "Location access is restricted. This can be configured in settings.")
        default:
            self.locationManager.requestAlwaysAuthorization()
        }
    }
    
    fileprivate func monitorRegions() {
        let result = Product.getAllProducts()
        result.products.forEach { (product) in
            let identifier = product.getIdentifierRegion()
            let uuid = UUID(uuidString: product.beaconUUID())!
            
            let beaconRegion = CLBeaconRegion(proximityUUID: uuid, identifier: identifier)
            beaconRegion.notifyOnExit = true
            beaconRegion.notifyEntryStateOnDisplay = true
            beaconRegion.notifyOnEntry = true
            guard locationManager.monitoredRegions.contains(beaconRegion) else {
                self.locationManager.startMonitoring(for: beaconRegion)
                return
            }
            
            //if regions.contains(where: { $0.identifier == identifier }) == false {
            //beaconRegion.notifyEntryStateOnDisplay = true
            //beaconRegion.notifyOnEntry = true
            //}
        }
    }
    
    func openSettings() {
        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
    }
}

//Private Methods
fileprivate extension LocationManager {
    func initialCongigration() {
        locationManager.delegate = self
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
}

struct BeaconRegion {
    var uuid:String
    var major:UInt16
    var minor:UInt16
    
    init(uuid:String, major:UInt16, minor:UInt16) {
        self.uuid = uuid
        self.major = major
        self.minor = minor
    }
}
