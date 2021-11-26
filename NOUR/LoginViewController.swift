//
//  LoginViewController.swift
//  NOUR
//
//  Created by abbas on 6/22/20.
//  Copyright © 2020 abbas. All rights reserved.

import UIKit
import Firebase

class LoginViewController: BaseViewController {
    
    var email:String?
    var pwd:String?
    
    var ref: DatabaseReference!
    
    @IBOutlet weak var txtUserName: APTextField!
    @IBOutlet weak var txtPassword: APTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = Database.database().reference()
        
        if let email = email, let pwd = pwd {
            txtUserName.text = email
            txtPassword.text = pwd
        } else {
            txtUserName.text = UserDefaults.standard.string(forKey: "loginEmail")
            txtPassword.text = UserDefaults.standard.string(forKey: "loginPwd")
        }
    }
    
    @IBAction func btnLoginPressed(_ sender: Any) {
        //let realm = AppDelegate.shared?.uiRealm
        //NotificationCenter.default.post(name: NSNotification.Name.ObjDidDeleted, object: nil)
        //try? realm?.write {
        //    realm?.delete(Product.getAllProducts().products)
        //}
        
        let email = txtUserName.text ?? ""
        let pwd = txtPassword.text ?? ""
        self.showProgress()
        Auth.auth().signIn(withEmail: email, password: pwd) { [weak self] authResult, error in
            guard let self = self else { return }
            if error == nil {
                let userID = Auth.auth().currentUser?.uid
                self.ref.child("users").child(userID!).observeSingleEvent(of: .value, with: { (snapshot) in
                    // Get user value
                    let userData = (snapshot.value as? [String:String]) ?? [:]
                    let user = Signup(user: userData)
                    user.email = self.txtUserName.text ?? ""
                    user.writeUpdate()
                    self.loadDataAndLogin()
                }) { (err) in
                    self.showToast(err.localizedDescription , type: .error)
                    self.dismissProgress()
                }
            } else {
                self.showToast(error!.localizedDescription, type: .error)
                self.dismissProgress()
            }
            
        }
        
         /*
         let result = Signup.validateUser(email: email, password: pwd)
         if result.isSuccess {
            logInUser()
         } else {
         self.showToast(result.message, type: .error)
         //self.showAlert(message: result.message, leftButton: "Ok", rightButton: "Cancel")
         } */
    }
    
    func loadDataAndLogin() {
        self.getUserProducts { (products, error) in
            if error == nil {
                products.values.forEach { (prod) in
                    let product = Product(data:prod)
                    product.writeUpdate()
                }
                self.logInUser()
            } else {
                self.showToast(error!.localizedDescription, type: .error)
            }
        }
    }
    
    fileprivate func logInUser() {
        //self.showProgress()
            UserDefaults.standard.set(self.txtUserName.text ?? "", forKey: "loginEmail")
            UserDefaults.standard.set(self.txtPassword.text ?? "", forKey: "loginPwd")
             UserDefaults.standard.set(true, forKey:"isLoggedIn")
             
            let vc = self.storyboard!.instantiateViewController(withIdentifier: "HomeViewController")
             let nvc = UINavigationController(rootViewController: vc)
             nvc.modalPresentationStyle = .fullScreen
             nvc.modalTransitionStyle = .flipHorizontal
             self.present(nvc, animated: true, completion: nil)
            
             DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.txtUserName.text = ""
                self.txtPassword.text = ""
                self.dismissProgress()
             }
    }
    
    @IBAction func btnForgetPwdPressed(_ sender: Any) {
        
    }
    
    
    func getUserProducts(completion:((_ products:[String:[String:String]],_ error:Error?)->Void)?) {
        //self.showProgress()
        let user = Signup.getUserBy(email: txtUserName.text ?? "").signup
        self.ref.child("UsersDevices").child(user?.uid ?? "").observeSingleEvent(of: .value, with: { (snapshot) in
            //let userProds:[String] = (snapshot.value as? [String:String])?.keys.map({$0}) ?? []
            let products:[String:[String:String]] = (snapshot.value as? [String:[String:String]]) ?? [:]
            completion?(products, nil)
            //self.dismissProgress()
        }) { (err) in
            completion?([:], err)
            self.dismissProgress()
        }
    }
    /*
    func getProductDetail(id:String, completion:((_ product:[String:String],_ error:Error?)->Void)?) {
        //let user = Signup.getUserBy(email: UserDefaults.standard.string(forKey: "loginEmail") ?? "").signup
        self.ref.child("Devices").child(id).observeSingleEvent(of: .value, with: { (snapshot) in
            let productDetail:[String:String] = (snapshot.value as? [String:String]) ?? [:]
            completion?(productDetail, nil)
        }) { (err) in
            completion?([:], err)
        }
    } */
}
