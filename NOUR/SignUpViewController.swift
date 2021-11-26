//
//  SignUpViewController.swift
//  NOUR
//
//  Created by abbas on 6/2/20.
//  Copyright © 2020 abbas. All rights reserved.
//

import UIKit
import Firebase

class SignUpViewController: BaseViewController {
    
    @IBOutlet weak var btnAddImage: APButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var imageView: UIImageView!
    
    var ref: DatabaseReference!
    
    var completion:((String, String)->Void)?
    
    var imagePicker:ImgPicker!
    
    var mataData:[[String]] = [
        ["Name", ""],
        ["Phone", ""],
        ["Address", ""],
        ["Country", ""],
        ["Email", ""],
        ["Password", ""],
        ["Repeat Password", ""],
        ["Sign up", ""]
    ]
    
    var cells:[UITableViewCell] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = Database.database().reference()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        
        for (id, data) in mataData.enumerated() {
            switch id {
            case mataData.count - 1:
                let cell = ButtonCell.getInstance(nibName: "ButtonCell") as! ButtonCell
                cell.setData(title: data[0], target: self, selector: #selector(btnSignupPressed)) //(title: )
                cells.append(cell)
            default:
                let cell = TextFieldCell.getInstance(nibName: "TextFieldCell") as! TextFieldCell
                cell.setData(placeHolder: data[0], text: data[1])
                cells.append(cell)
            }
        }
        imagePicker = ImgPicker(target: self)
    }
    
    @IBAction func btnAddImagePressed(_ sender: UIButton) {
        imagePicker.pick(sender: sender) { (image) in
            self.imageView.image = image
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        //btnAddImage.cornerRadius = btnAddImage.frame.size.height / 2
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.imageView.cornerRadius = self.imageView.frame.size.height / 2
        }
        self.view.layoutIfNeeded()
    }
    
    @objc func btnSignupPressed() {
        
        let valid = validate()
        guard valid.isValid else {
            self.showToast(valid.message, type: .error)
            return
        }
        self.showProgress()
        
        var imStr = ""
        if let image = imageView.image {
            if let imData = image.jpegData(compressionQuality: 0.5) {
                //UIImage(data: imData)
                
                imStr = imData.base64EncodedString()
            }
        }
        
        let user = Signup()
        user.image = imStr
        user.name = (cells[0] as? TextFieldCell)?.textField.text ?? ""
        user.phone = (cells[1] as? TextFieldCell)?.textField.text ?? ""
        user.address = (cells[2] as? TextFieldCell)?.textField.text ?? ""
        user.country = (cells[3] as? TextFieldCell)?.textField.text ?? ""
        user.email = (cells[4] as? TextFieldCell)?.textField.text ?? ""
        user.password = (cells[5] as? TextFieldCell)?.textField.text ?? ""
        
        Auth.auth().createUser(withEmail: user.email ?? "", password: user.password ?? "") { authResult, error in
            self.dismissProgress()
            if error == nil {
                user.uid = authResult?.user.uid
                let result = user.writeUpdate()
                if result.isSuccess {
                    //self.ref.child("TestUsers").child("HelloTestId").setValue(["username": "UserName123"])
                    let userData:[String:String] = [
                        "address":user.address ?? "",
                        "country":user.country ?? "",
                        "email":user.email ?? "",
                        "image":user.image ?? "",
                        "phoneNumber":user.phone ?? "",
                        "userId":user.uid ?? "",
                        "userName": user.name ?? ""
                    ]
                    
                    self.showToast("Registerd Successfully", type: .success)
                    self.showProgress()
                    self.ref.child("users").child(user.uid!).setValue(userData) { (error, _) in
                        
                        self.dismissProgress()
                        self.dismiss(animated: true) {
                                self.completion? (
                                    (self.cells[4] as? TextFieldCell)?.textField.text ?? "",
                                    (self.cells[5] as? TextFieldCell)?.textField.text ?? "" )
                        }
                        
                        if let error = error {
                            self.showToast(error.localizedDescription, type: .error)
                        }
                    }
                } else {
                    self.showToast(result.message, type: .error)
                }
            } else {
                self.showToast(error!.localizedDescription, type: .error)
            }
        }
        
        

        //RealmManager.shared.signInInfo = user
        
        
        /*
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            
        } */
    }
}

extension SignUpViewController:UITableViewDelegate,UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cells.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return cells[indexPath.row]
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
        case mataData.count - 1:
            return Theme.adjustRatioH(48) + 40
        default:
            return Theme.adjustRatioH(48) + 18
        }
    }
}

extension SignUpViewController {
    func validate() -> (isValid:Bool, message:String) {
        //if ((cells[0] as? TextFieldCell)?.textField.text ?? "").count == 0 {
        //    return (false, "Name is required")
        //}
        //if ((cells[1] as? TextFieldCell)?.textField.text ?? "").count == 0 {
        //    return (false, "Phone is required")
        //}
        //if ((cells[2] as? TextFieldCell)?.textField.text ?? "").count == 0 {
        //    return (false, "Address is required")
        //}
        //if ((cells[3] as? TextFieldCell)?.textField.text ?? "").count == 0 {
        //    return (false, "Country is required")
        //}
        if ((cells[4] as? TextFieldCell)?.textField.text ?? "").count == 0 {
            return (false, "Email is required")
        }
        
        let emailValidation = ((cells[4] as? TextFieldCell)?.textField.text ?? "").validate(with: Constants.emailRegix)
        if emailValidation.isValid == false {
            return(false, emailValidation.message ?? "The email address entered seems to be invalid")
        }
        
        if ((cells[5] as? TextFieldCell)?.textField.text ?? "").count == 0 {
            return (false, "Password is required")
        }
        if ((cells[5] as? TextFieldCell)?.textField.text ?? "") != ((cells[6] as? TextFieldCell)?.textField.text ?? "")  {
            return (false, "Passwords don't match")
        }
        
        return (true, "Success")
    }
}
