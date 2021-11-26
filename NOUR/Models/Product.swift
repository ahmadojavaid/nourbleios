//
//  Products.swift
//  NOUR
//
//  Created by abbas on 6/30/20.
//  Copyright © 2020 abbas. All rights reserved.
//

import UIKit
import RealmSwift
import CoreLocation

class Product: Object {
    @objc dynamic var id: String = ""
    @objc dynamic var name: String? = ""
    @objc dynamic var type: String? = "0"
    @objc dynamic var other: String? = ""
    @objc dynamic var battery: String? = "92"
    @objc dynamic var regDate: String? = ""
    
    @objc dynamic var latitude: String? = "0"
    @objc dynamic var longitude: String? = "0"
    @objc dynamic var lastUpdateDate: String? = ""
    
    @objc dynamic var status: String? = "0" // 0:Unknown, 1:Inside, 2:Outside
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    convenience init(data:[String:String]) {
        self.init()
        self.id = data["id"] ?? ""
        self.name = data["deviceTitle"]
        self.type = data["type"]
        self.battery = data["battery"]
        self.other = data["comment"]
        self.lastUpdateDate = data["lastUpdated"]
        self.latitude = data["latitude"]
        self.longitude = data["longitude"]
        self.regDate = data["timePaired"]
    }
        
    static func updateProduct (data:[String:String]) {
        
        if let product = Product.getProductBy(id: data["id"] ?? "").product {
            if let pDate = product.lastUpdateDate?.toDate("dd-MM-yyyy"), let fDate = data["lastUpdated"]?.toDate("dd-MM-yyyy"), fDate > pDate {
                        let realm = AppDelegate.shared!.uiRealm
                do {
                    try realm.write {
                        product.name = data["deviceTitle"]
                        product.type = data["type"]
                        product.battery = data["battery"]
                        product.other = data["comment"]
                        product.lastUpdateDate = data["lastUpdated"]
                        product.latitude = data["latitude"]
                        product.longitude = data["longitude"]
                        product.regDate = data["timePaired"]
                    }
                } catch {
                    print(error.localizedDescription)
                }
            }
        } else {
            let product = Product()
            product.id = data["id"] ?? ""
            product.name = data["deviceTitle"]
            product.type = data["type"]
            product.battery = data["battery"]
            product.other = data["comment"]
            product.lastUpdateDate = data["lastUpdated"]
            product.latitude = data["latitude"]
            product.longitude = data["longitude"]
            product.regDate = data["timePaired"]
            
            let realm = AppDelegate.shared!.uiRealm
            do {
                try realm.write { product }
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func beaconUUID() -> String {
        var uid = self.id
        for _ in 0..<6 { uid.removeFirst() }
        return "25D5D7" + uid
    }
    func major() -> String {
        return "10"
    }
    func minor() -> String {
        return "20"
    }
    
    func getIdentifierRegion() -> String {
        return "\(beaconUUID())_\(major())_\(minor())".uppercased()
    }
    
    func updateStatus(status:String) {
        let realm = AppDelegate.shared!.uiRealm
        do {
            try realm.write {
                self.status = status
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func update(name:String, type:String, other:String) {
        let realm = AppDelegate.shared!.uiRealm
        do {
            try realm.write {
                self.name = name
                self.type = type
                self.other = other
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    static func getProductby(identifier:String) -> Product? {
        let products = Product.getAllProducts().products
        for product in products {
            if product.getIdentifierRegion() == identifier {
                return product
            }
        }
        return nil
    }
    
    static func updateStatus(identifier:String, status:String) {
        let products = Product.getAllProducts().products
        products.forEach { (product) in
            if product.getIdentifierRegion() == identifier {
                product.updateStatus(status: status)
            }
        }
    }
    
    func updateLocation(latitude:CGFloat, longitude:CGFloat) {
        let realm = AppDelegate.shared!.uiRealm
        do {
            try realm.write {
                self.latitude = "\(latitude)"
                self.longitude = "\(longitude)"
                self.lastUpdateDate = Date().toString("dd-MM-yyyy")
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    static func updateLocations(latitude:CGFloat, longitude:CGFloat) {
        let products = Product.getAllProducts().products
        products.forEach { (product) in
            if product.status == "1" {
                product.updateLocation(latitude: latitude, longitude: longitude)
            }
        }
    }
    
    static func updateLocationWith(identifier:String, latitude:CGFloat, longitude:CGFloat) {
        let products = Product.getAllProducts().products
        products.forEach { (product) in
            if product.getIdentifierRegion() == identifier {
                product.updateLocation(latitude: latitude, longitude: longitude)
            }
        }
    }
    
    func updateBattery(battery:String) {
        let realm = AppDelegate.shared!.uiRealm
        do {
            try realm.write {
                self.battery = battery
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    static func getProductBy(id:String) -> (product:Product?, message:String) {
        
        let realm = AppDelegate.shared!.uiRealm
        
        let product = realm.objects(Product.self).filter("id = %@", id)
        return (product.first, "")
    }
    
    static func getAllProducts() -> (products:[Product], message:String) {
        
        let realm = AppDelegate.shared!.uiRealm
        
        let products:[Product] = realm.objects(Product.self).map { $0 }
        return (products, "")
    }
    
    func write() -> (isSuccess:Bool, message:String) {
        
        guard Product.getProductBy(id: self.id).product == nil else {
            return (false, "Product was added previously")
        }
        
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
    func writeUpdate() -> (isSuccess:Bool, message:String) {
        let realm = AppDelegate.shared!.uiRealm
        do {
            try realm.write {
                realm.add(self, update: .all)
            }
            return (true, "Success")
        } catch {
            return (false, error.localizedDescription)
        }
    }
    
    func delete() -> (isSuccess:Bool, message:String){
        let realm = AppDelegate.shared!.uiRealm
        do {
            try realm.write {
                realm.delete(self)
            }
            return (true, "Deleted Successfully")
        } catch {
            return (false, error.localizedDescription)
        }
    }
    
    func updateDetails() -> (isSuccess:Bool, message:String) {
        
        let realm = AppDelegate.shared!.uiRealm
        
        do {
            try realm.write {
                realm.add(self, update: .modified)
            }
            return (true, "Success")
        } catch {
            return (false, error.localizedDescription)
        }
    }
    
    static func validateProduct(id:String) -> (isSuccess:Bool, message:String) {
        
        let realm = AppDelegate.shared!.uiRealm
        
        let prods = realm.objects(Product.self).filter("id = %@", id)
        
        guard let prod = prods.first else {
            return (false, "No user exists with the specified id.")
        }
        
        guard prod.id == id else {
            return (false, "Product not found")
        }
        
        return (true, "Found")
    }
}
