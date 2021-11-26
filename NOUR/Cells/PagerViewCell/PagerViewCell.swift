//
//  PagerViewCell.swift
//  NOUR
//
//  Created by abbas on 6/3/20.
//  Copyright © 2020 abbas. All rights reserved.
//

import UIKit
import FSPagerView
import CoreBluetooth
import Realm

class PagerViewCell: FSPagerViewCell {
    
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var itemName: APLabel!
    @IBOutlet weak var itenNumber: APLabel!
    @IBOutlet weak var comment: APLabel!
    @IBOutlet weak var icon: UILabel!
    @IBOutlet weak var date: APLabel!
    @IBOutlet weak var clock: UILabel!
    @IBOutlet weak var battery: APLabel!
    
    var isEnabledBattryNoti = false
    
    var peripheral:CBPeripheral?
    var batteryService:CBService?
    var batteryChar:CBCharacteristic?
    
    var productID:String = ""
    
    var icons = ["key", "wallet", "draw-square"]
    var isWhiteTheme = false
    
    func setData(productID:String){
        self.productID = productID
        guard let product = Product.getProductBy(id: productID).product else {
            return
        }
        
        itemName.text = product.name ?? ""
        itenNumber.text = product.id.subString(product.id.count - 12, product.id.count - 1)
        comment.text = product.other ?? ""
        icon.text = icons[((product.type ?? "") as NSString).integerValue]
        date.text = product.regDate ?? ""
        battery.text = (product.battery ?? "0") + "%"
        
        //if isEnabledBattryNoti == false {
        //    isEnabledBattryNoti = true
        //    guard let perifri = BLEManager.shared.getPeripheral(id: product.id) else {
        //        return
        //    }
        //    peripheral = perifri
        readValue()
        //setNotify()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        bgView.layer.borderColor = Theme.Colors.redText.cgColor
        bgView.layer.borderWidth = 2
    }
    
    func setTheme(isWhite:Bool = false) {
        if isWhiteTheme == isWhite {
            return
        }
        isWhiteTheme = isWhite
        UIView.animate(withDuration: 0.3) { [weak self] in
            if isWhite {
                self?.bgView.backgroundColor = Theme.Colors.whiteText
                self?.itemName.customize(.font18, .medium, .darkText)
                self?.itenNumber.customize(.font22, .italic, .darkText)
                self?.comment.customize(.font16, .regular, .darkText)
                
                self?.icon.textColor = Theme.Colors.redText
                self?.date.customize(.font15, .regular, .redText)
                self?.clock.textColor = Theme.Colors.redText
                
            } else {
                self?.bgView.backgroundColor = Theme.Colors.redText
                self?.itemName.customize(.font18, .medium, .whiteText)
                self?.itenNumber.customize(.font22, .italic, .whiteText)
                self?.comment.customize(.font16, .regular, .whiteText)
                
                self?.icon.textColor = Theme.Colors.whiteText
                self?.date.customize(.font15, .regular, .whiteText)
                self?.clock.textColor = Theme.Colors.whiteText
            }
        }
    }
}

extension PagerViewCell {
    func dataNotified(isSuccess:Bool, data:Data?, message:String) -> Bool {
            if isSuccess, let data = data {
                let battery = "\(Array<UInt8>(data)[0])"
                self.battery.text = "\(battery)%"
                print("Battery: \(battery)")
                let realm = AppDelegate.shared?.uiRealm
                let product = Product.getProductBy(id: self.productID).product
                try! realm?.write({
                    product?.battery = battery
                })
                //if let id = BLEManager.shared.getPeripheralID(by: self.productID) {
                //    BLEManager.shared.myPeripherals[id].readRSSI(completion: nil)
                //}
            } else {
                
            }
            return false
    }
    
    func readValue() {
        
        if let id = BLEManager.shared.getPeripheralID(by: self.productID) {
            BLEManager.shared.myPeripherals[id].readData(characUUID: CBConfig.batteryCharac, serviceUUID: CBConfig.batteryService, completion: dataNotified(isSuccess:data:message:))
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) { [weak self] in
            self?.readValue()
        }
    }
    
    fileprivate func setNotify() {
        //enableNotifications(peripheral:perifri)
        //}
        if let id = BLEManager.shared.getPeripheralID(by: self.productID) {
            BLEManager.shared.myPeripherals[id].setNotify(characUUID: CBConfig.batteryCharac, serviceUUID: CBConfig.batteryService) { (isSuccess, message) -> Bool in
                if isSuccess {
                    self.isEnabledBattryNoti = true
                    print("Notifications Enabeld")
                } else {
                    print(message)
                }
                return true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            if self?.isEnabledBattryNoti == false {
                self?.setNotify()
            }
        }
    }
}
