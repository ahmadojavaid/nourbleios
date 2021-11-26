//
//  RealmManager.swift
//  NOUR
//
//  Created by abbas on 6/22/20.
//  Copyright © 2020 abbas. All rights reserved.
//

import UIKit
import RealmSwift

class RealmManager: NSObject {
    
    static var shared = RealmManager()
    var realm: Realm!
    
    override init() {
        super.init()
        
        self.realm = AppDelegate.shared!.uiRealm
        //if realm == nil {
        //    realm = try! Realm()
        //}
    }
    
    var signInInfo: Signup {
        set {
            if realm == nil {
                realm = try! Realm()
            }
            try! realm.write() {
                realm.add(newValue)
            }
        }
        
        get {
            if realm == nil {
                realm = try! Realm()
            }
            return realm.objects(Signup.self).first ?? Signup()
        }
    }
    
    

    func validateUser(email:String, password:String) -> (isSuccess:Bool, message:String) {
        
        if realm == nil {
            realm = try! Realm()
        }
        
        let users = realm.objects(Signup.self).filter("email = %@", email)
        print("Step 1 \(users.first?.name ?? "nil")")
        
        guard let user = users.first else {
            return (false, "No user exists with the specified id.")
        }
        
        guard user.password == password else {
            return (false, "Invalid credentials")
        }
        
        return (true, "Success")
    }
    
    
    
    
    
    
    static var realm:(message:String,realm:Realm?) {
        do {
            return ("",try Realm())
        } catch let error{
            print(error)
            return (error.localizedDescription, nil)
        }
    }
}
