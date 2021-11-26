//
//  ProfileViewController.swift
//  NOUR
//
//  Created by abbas on 6/5/20.
//  Copyright © 2020 abbas. All rights reserved.
//

import UIKit
import Firebase

class ProfileViewController: BaseViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var txtName: APTextField!
    @IBOutlet weak var txtNumber: APTextField!
    @IBOutlet weak var txtAddress: APTextField!
    @IBOutlet weak var txtCountry: APTextField!
    @IBOutlet weak var txtEmail: APTextField!
    @IBOutlet weak var btnChangePWD: APButton!
    
    @IBOutlet weak var btnAddImage: UIButton!
    var ref: DatabaseReference!
    
    var imagePicker:ImgPicker!
    
    var isInEditMode = false {
        didSet {
            setMode()
        }
    }
    
    let user = Signup.getUserBy(email: UserDefaults.standard.string(forKey: "loginEmail") ?? "").signup
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = Database.database().reference()
        
        txtNumber.keyboardType = .phonePad
        if let imdata = Data(base64Encoded: user?.image ?? "") {
            self.imageView.image = UIImage(data: imdata)
            //btnAddImage.setImage(, for: .normal)
            //btnAddImage.setImage(UIImage(data: imdata), for: .disabled)
        }
        txtName.text = user?.name ?? ""
        txtNumber.text = user?.phone ?? ""
        txtAddress.text = user?.address ?? ""
        txtCountry.text = user?.country ?? ""
        txtEmail.text = user?.email ?? ""
        
        txtEmail.textColor = Theme.Colors.grayText
        txtEmail.isEnabled = false
        imagePicker = ImgPicker(target: self)
        setMode()
        btnAddImage.isEnabled = false
        btnAddImage.tintColor = .clear
        
        txtName.delegate = self
        txtCountry.delegate = self
    }
    
    @IBAction func btnAddImagePressed(_ sender: UIButton) {
        imagePicker.pick(sender: sender) { (image) in
            self.imageView.image = image
            //sender.setImage(image, for: .normal)
            //sender.setImage(image, for: .disabled)
        }
    }
    
    func setMode() {
        btnAddImage.isEnabled = isInEditMode
        switch isInEditMode {
        case true:
            txtName.isEnabled = true
            txtNumber.isEnabled = true
            txtAddress.isEnabled = true
            txtCountry.isEnabled = true
            
            txtName.textColor = Theme.Colors.darkText
            txtNumber.textColor = Theme.Colors.darkText
            txtAddress.textColor = Theme.Colors.darkText
            txtCountry.textColor = Theme.Colors.darkText
            
            txtName.becomeFirstResponder()
            btnChangePWD.setTitle("Save", for: .normal)
        case false:
            txtName.isEnabled = false
            txtNumber.isEnabled = false
            txtAddress.isEnabled = false
            txtCountry.isEnabled = false
            
            txtName.textColor = Theme.Colors.grayText
            txtNumber.textColor = Theme.Colors.grayText
            txtAddress.textColor = Theme.Colors.grayText
            txtCountry.textColor = Theme.Colors.grayText
            btnChangePWD.setTitle("Logout", for: .normal)
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        imageView.layer.cornerRadius = imageView.frame.size.height / 2
        //btnAddImage.cornerRadius = btnAddImage.frame.size.height / 2
    }
    
    @IBAction func btnEditPressed(_ sender: Any) {
        isInEditMode = !isInEditMode
    }
    
    @IBAction func btnChangePwdPressed(_ sender: Any) {
        if isInEditMode == true { // is in edit mode
            isInEditMode = false
            
            var imStr = ""
            if let image = imageView.image {
                if let imData = image.jpegData(compressionQuality: 0.5) {
                    //UIImage(data: imData)
                    
                    imStr = imData.base64EncodedString()
                }
            }
    
            let oldUser = Signup.getUserBy(email: txtEmail.text ?? "").signup
            
            let user = Signup()
            user.image = imStr
            user.name = txtName.text ?? ""
            user.phone = txtNumber.text ?? ""
            user.address = txtAddress.text ?? ""
            user.country = txtCountry.text ?? ""
            user.uid = oldUser?.uid
            user.email = oldUser?.email
            
            
            let userData:[String:String] = [
                "address":user.address ?? "",
                "country":user.country ?? "",
                "email":oldUser?.email ?? "",
                "image":imStr,
                "phoneNumber":user.phone ?? "",
                "userId":user.uid ?? "",
                "userName": user.name ?? ""
            ]
            
            self.showProgress()
            self.ref.child("users").child(user.uid ?? "").setValue(userData) { (error, _) in
                
                self.dismissProgress()
                
                if let error = error {
                    self.showToast(error.localizedDescription, type: .error)
                } else {
                    let result = user.writeUpdate()
                    self.showToast("Profile updated successfulfy", type: .success)
                }
            }
        } else { // now it will work as logout
            UserDefaults.standard.set("", forKey: "loginEmail")
            UserDefaults.standard.set("", forKey: "loginPwd")
            UserDefaults.standard.set(false, forKey:"isLoggedIn")
            self.dismiss(animated: true, completion: nil)
            
        }
    }
}

extension ProfileViewController:UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.text = textField.text?.trimmed.capitalized
    }
}
