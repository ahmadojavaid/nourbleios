//
//  User.swift
//  NOUR
//
//  Created by abbas on 6/22/20.
//  Copyright © 2020 abbas. All rights reserved.
//

import UIKit
import RealmSwift

class Signup: Object {
    
    @objc dynamic var name: String? = ""
    @objc dynamic var phone: String? = ""
    @objc dynamic var address: String? = ""
    @objc dynamic var country: String? = ""
    @objc dynamic var email: String? = ""
    @objc dynamic var password: String? = ""
    @objc dynamic var image: String? = ""
    @objc dynamic var uid: String? = ""
    
    convenience init(user:[String:String]) {
        self.init()
        name = user["userName"]
        phone = user["phoneNumber"]
        address = user["address"]
        country = user["country"]
        image = user["image"]
        email = user["email"]
        uid = user["userId"]
    }
    
    override static func primaryKey() -> String? {
        return "email"
    }
    
    static func getUserBy(email:String) -> (signup:Signup?, message:String) {
        
        //let realmm = RealmManager.realm
        //guard let realm = realmm.realm else {
        //    return (nil, realmm.message)
        //}
        let realm = AppDelegate.shared!.uiRealm
        let users = realm.objects(Signup.self).filter("email = %@", email)
        return (users.first, "")
    }
    static func getUserBy(uid:String) -> (signup:Signup?, message:String) {
        
        //let realmm = RealmManager.realm
        //guard let realm = realmm.realm else {
        //    return (nil, realmm.message)
        //}
        let realm = AppDelegate.shared!.uiRealm
        let users = realm.objects(Signup.self).filter("uid = %@", uid)
        return (users.first, "")
    }
    
    func writeUpdate() -> (isSuccess:Bool, message:String) {
            
        //let realmm = RealmManager.realm
        //guard let realm = realmm.realm else {
        //    return (false, realmm.message)
        //}
        let realm = AppDelegate.shared!.uiRealm
        
        do {
            try realm.write { realm.add(self, update: .all) }
            return (true, "Success")
        } catch {
            return (false, error.localizedDescription)
        }
    }
    
    func write() -> (isSuccess:Bool, message:String) {
        
        guard Signup.getUserBy(email: self.email ?? "").signup == nil else {
            return (false, "A user with the given emailid is already registered")
        }
        
        //let realmm = RealmManager.realm
        //guard let realm = realmm.realm else {
        //    return (false, realmm.message)
        //}
        let realm = AppDelegate.shared!.uiRealm
        
        do {
            try realm.write {
                realm.add(self)
            }
            return (true, "Success")
        } catch {
            return (false, error.localizedDescription)
        }
    }
    
    static func validateUser(email:String, password:String) -> (isSuccess:Bool, message:String) {
        
        //let realmm = RealmManager.realm
        //guard let realm = realmm.realm else {
        //    return (false, realmm.message)
        //}
        let realm = AppDelegate.shared!.uiRealm
        
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
}
