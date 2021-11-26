//
//  LinkProductDetailsViewController.swift
//  NOUR
//
//  Created by abbas on 6/5/20.
//  Copyright © 2020 abbas. All rights reserved.
//

import UIKit
import CoreBluetooth
import Firebase

class LinkProductDetailsViewController: BaseViewController {
    
    var peripheral:CBPeripheral!
    var ref: DatabaseReference!
    
    @IBOutlet weak var otherView: UIView!

    @IBOutlet weak var txtProductName: APTextField!
    @IBOutlet weak var txtProductType: APTextField!
    @IBOutlet weak var txtComment: UITextView!
    @IBOutlet weak var txtDated: APTextField!
    @IBOutlet weak var txtIdentifier: APTextField!
    
    var myPeripheral:APPeripheralManager!
    
    let pData:[String] = ["Key", "Wallet", "Other"]
    
    var picker:PickerView!
    
    let product = Product()
    
    var isDone = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //self.showProgress()
        ref = Database.database().reference()
        product.id = peripheral.identifier.uuidString
        var beaconUUID = product.id
        
        //product.beaconUUID = UUID().uuidString
        //product.major = "\(UInt16.random(in: 1..<65535))"
        //product.minor = "\(UInt16.random(in: 1..<65535))"
        
        addTxtWaletRightView()
        configureOtherViews()
        txtDated.text = Date().toString("dd-MM-yyyy")
        let id = self.peripheral!.identifier.uuidString
        txtIdentifier.text = id.subString(id.count - 12, id.count - 1)
        txtDated.textColor = Theme.Colors.grayText
        txtIdentifier.textColor = Theme.Colors.grayText
        
        picker = PickerView(data: pData, completion: { (id, pType) in
            self.txtProductType.text = pType
            self.product.type = "\(id)"
        })
        
        txtProductType.inputView = picker
        txtProductType.delegate = self
        

        //self.showProgress(text: "Loading...")
        myPeripheral = APPeripheralManager(peripheral)
        //myPeripheral.discoverServicesChars { (isSuccess, message) -> Bool in
        //    self.dismissProgress()
        //    return true
        //}
        
        //NotificationCenter.default.addObserver(self, selector: #selector(self.showSpinningWheel(_:)), name: NSNotification.Name(rawValue: "notificationName"), object: nil)
        /*
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if BLEManager.shared.isProcessing == false && self.isDone == false {
                self.dismissProgress()
                self.peripheral = BLEManager.shared.myPeripherals.first(where: { $0.identifier == self.peripheral.identifier })
            }
        }
        */
    }
    
    /*
    @objc func showSpinningWheel(_ notification: NSNotification) {
        print(notification.userInfo ?? "")
        self.dismissProgress()
        if let dict = notification.userInfo as NSDictionary? {
            if let isSuccess = dict["isSuccess"] as? Bool{
                if isSuccess {
                    self.showToast("Your are ready to go", type: .success)
                } else {
                    self.showToast("Something went wrong", type: .error)
                }
                
                //self.peripheral = BLEManager.shared.myPeripherals.first(where: {$0.identifier == peripheral.identifier} )
            }
        }
    }
    */
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        otherView.cornerRadius = txtProductType.frame.size.height / 2
    }
    
    @IBAction func btnSavePressed(_ sender: Any) {
        let valid = validate()
        guard valid.isValid else {
            self.showToast(valid.message, type: .error)
            return
        }
        writeConfigData()
        
    }
    
    @IBAction func btnBackPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}

fileprivate extension LinkProductDetailsViewController {
    func writeConfigData() {
        self.showProgress(text: "Configuring...")
        let data = encodeConfigData(uuidString: product.beaconUUID(),
                                    major: ((product.major()) as NSString).integerValue,
                                    minor: ((product.minor()) as NSString).integerValue,
                                    interval: 500)
        
        myPeripheral.writeValue(characUUID: CBConfig.readWriteDataCharac, serviceUUID: CBConfig.peripheralService, data: data) { (isSuccess, message) -> Bool in
            self.dismissProgress()
            if isSuccess {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    self.sendCommand()
                }
                return false
            } else {
                self.showToast(message, type: .error)
                return true
            }
        }
    }
    
    func sendCommand() {
        self.showProgress()
        myPeripheral.writeValue(characUUID: CBConfig.writeCommandCharac, serviceUUID: CBConfig.peripheralService, data: Data(Array<UInt8>([5]))) { (isSuccess, message) -> Bool in
            self.dismissProgress()
            if isSuccess {
                self.readConfigData()
            } else {
                self.showToast(message, type: .error)
            }
            return true
        }
    }
    
    func readConfigData() {
        self.showProgress(text: "Verifying...")
        myPeripheral.readData(characUUID: CBConfig.readWriteDataCharac, serviceUUID: CBConfig.peripheralService) { (isSuccess, data, message) -> Bool in
            self.dismissProgress()
            if isSuccess, let data = data {
                self.verifyConfigration(data)
            } else {
                self.showToast(message, type: .error)
            }
            return true
        }
    }

    
    func encodeConfigData(uuidString:String, major:Int, minor:Int, interval:Int) -> Data {
        let uuidPrefix = Array("uuid:".utf8).map{UInt8($0)}
        let MJPre = Array("mj:".utf8).map{UInt8($0)}
        let MIPre = Array("mi:".utf8).map{UInt8($0)}
        let INPre = Array("in:".utf8).map{UInt8($0)}
        
        let uuidUInt = uuidString.replacingOccurrences(of: "-", with: "").map{UInt8($0.hexDigitValue!)}
        var uuidUInt8:[UInt8] = Array(repeating: 0, count: 16)
        for i in 0...15 {
            uuidUInt8[i] = 16 * uuidUInt[i * 2] + uuidUInt[i * 2 + 1]
        }
        let MJ:[UInt8] = [UInt8(major/256), UInt8(major%256)]
        let MI:[UInt8] = [UInt8(minor/256), UInt8(minor%256)]
        let IN:[UInt8] = [UInt8(interval/256), UInt8(interval%256)]
        
        var configData = ((uuidPrefix + uuidUInt8) + (MJPre + MJ))
        configData = configData + ((MIPre + MI) + (INPre + IN))
        
        return Data(configData)
    }
    
    func verifyConfigration(_ data:Data) {
        if data.count >= 44 {
            let uuidString = String(data: Data(Array<UInt8>(data)[0...31]), encoding: .utf8) ?? ""
            //let mjArray = (String(data: Data(Array(Array<UInt8>(data)[32...35])), encoding: .utf8) ?? "").map{$0.hexDigitValue ?? 0}
            //let major = mjArray[0] * 16 * 16 * 16 + mjArray[1] * 16 * 16 + mjArray[2] * 16 + mjArray[3]
            //let miArray = (String(data: Data(Array(Array<UInt8>(data)[36...39])), encoding: .utf8) ?? "").map{$0.hexDigitValue ?? 0}
            //let minor = miArray[0] * 16 * 16 * 16 + miArray[1] * 16 * 16 + miArray[2] * 16 + miArray[3]
            //let tiArray = (String(data: Data(Array(Array<UInt8>(data)[40...43])), encoding: .utf8) ?? "").map{$0.hexDigitValue ?? 0}
            //let interval = tiArray[0] * 16 * 16 * 16 + tiArray[1] * 16 * 16 + tiArray[2] * 16 + tiArray[3]
            //print("mjArray:\(mjArray), miArray:\(miArray), tiArray:\(tiArray)")
            
            if uuidString == (product.beaconUUID()).replacingOccurrences(of: "-", with: "").uppercased() {
                // Success
                // self.startBeacon()
                self.saveProductInfo()
            } else {
                self.showToast("Failed to verify beacon configrations", type: .error)
                // Error
            }
        }
    }
    
    func saveProductInfo() {
        
        self.showProgress(text: "Saving...")
        if let location = LocationManager.shared.locationManager.location {
            product.latitude = "\(location.coordinate.latitude)"
            product.longitude = "\(location.coordinate.longitude)"
        }
        product.name = txtProductName.text ?? ""
        //product.type = txtProductType.text ?? "0"
        product.other = txtComment.text ?? ""
        product.regDate = Date().toString("dd-MM-yyyy")
        product.lastUpdateDate = Date().toString("dd-MM-yyyy")
        
        self.linkProductDetailsWithDB { (error) in
            if error == nil {
                let result = self.product.write()
                if result.isSuccess {
                    self.dismissProgress()
                    //_ = BLEManager.shared.add(peripheral: myPeripheral)
                    BLEManager.shared.setAsPowerdOn()
                    LocationManager.shared.monitorRegions(completion: nil)
                    //self.showToast("", type: .success)
                    
                    self.showAlert(message: "Product Added Successfully! \nRelaunch APP for better results?", leftButton: "Not Now?", rightButton: "Relaunch?", leftCompletion: {
                        self.showProgress()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            self.popToHome()
                            self.dismissProgress()
                        }
                    }) {
                        exit(1)
                    }
                } else {
                    self.dismissProgress()
                    self.showToast(result.message, type: .error)
                }
            } else {
                self.dismissProgress()
                self.showToast(error!.localizedDescription, type: .error)
            }
        }
    }
    
    func addTxtWaletRightView() {
        let rtview = UIView()
        
        let tlabel:UILabel = {
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.text = "angle-down"
            label.font = UIFont.fontAwesome(ofSize: .font24, weight: .regular)
            label.textColor = Theme.Colors.redText
            return label
        }()
    
        rtview.addSubview(tlabel)
        txtProductType.rightView = rtview
        txtProductType.rightViewMode = .always
        let constraints = [
            tlabel.topAnchor.constraint(equalTo: rtview.topAnchor),
            tlabel.bottomAnchor.constraint(equalTo: rtview.bottomAnchor),
            tlabel.rightAnchor.constraint(equalTo: rtview.rightAnchor, constant: -15),
            tlabel.leftAnchor.constraint(equalTo: rtview.leftAnchor, constant: 10)
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
    func configureOtherViews() {
        txtProductType.font = Theme.Font.ofSize(.font15, weight: .regular)
        txtProductType.textColor = Theme.Colors.darkText
        otherView.clipsToBounds = true
    }
    
    func validate() -> (isValid:Bool, message:String) {
        if (txtProductName.text?.trimmed ?? "") == "" {
            return (false, "Product name is required")
        }
        
        if (txtProductType.text?.trimmed ?? "") == "" {
            return (false, "Product type is required")
        }
        
        return (true, "")
    }
}

extension LinkProductDetailsViewController:UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        //if (textField.text ?? "" == "") {
        let row = picker.selectedRow(inComponent: 0)
        textField.text = pData[row]
        product.type = "\(row)"
        //}
    }
    /*
    func linkProductWithUser(completion:((_ error:Error?)->Void)?) {
        let user = Signup.getUserBy(email: UserDefaults.standard.string(forKey: "loginEmail") ?? "").signup
        self.showProgress()
        self.ref.child("UsersDevices").child(user?.uid ?? "").child(self.product.id).setValue(true) { (error, _) in
            self.dismissProgress()
            completion?(error)
        }
    } */
}

extension LinkProductDetailsViewController {
    func linkProductDetailsWithDB(completion:((_ error:Error?)->Void)?) {
        let user = Signup.getUserBy(email: UserDefaults.standard.string(forKey: "loginEmail") ?? "").signup
        
        let newProduct:[String:String] = [
            "id":self.product.id,
            "deviceTitle":self.product.name ?? "",
            "type":self.product.type ?? "",
            "battery":self.product.battery ?? "",
            "comment":self.product.other ?? "",
            "deviceAddress":"",
            "lastUpdated":product.lastUpdateDate ?? "",
            "latitude":product.latitude ?? "",
            "longitude":product.longitude ?? "",
            "rssi":"0",
            "timePaired":Date().toString("dd-MM-yyyy")
            
            //"user": user?.uid ?? ""
        ]
        
        self.showProgress()
        self.ref.child("UsersDevices").child(user?.uid ?? "").child(self.product.id).setValue(newProduct) { (error, _) in
            self.dismissProgress()
            completion?(error)
        }
    }
    
}


