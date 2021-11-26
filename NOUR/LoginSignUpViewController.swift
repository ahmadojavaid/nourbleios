//
//  ViewController.swift
//  NOUR

//  Created by abbas on 6/1/20.
//  Copyright © 2020 abbas. All rights reserved.

import UIKit

class LoginSignUpViewController: BaseViewController {
    
    var email:String?
    var pwd:String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        FontManager.searchFont(keyWord: "Fira")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if UserDefaults.standard.bool(forKey: "isLoggedIn") {
            // navigate to home...
            let vc = storyboard!.instantiateViewController(withIdentifier: "HomeViewController") as! HomeViewController
            vc.isSignedIn = true
            let nvc = UINavigationController(rootViewController: vc)
            nvc.modalPresentationStyle = .fullScreen
            nvc.modalTransitionStyle = .flipHorizontal
            self.present(nvc, animated: true, completion: nil)
        }
        
    }
    
    @IBAction func btnLoginPressed(_ sender: Any) {
        let vc = storyboard!.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
        vc.email = email
        vc.pwd = pwd
        self.present(vc, animated: true, completion: nil)
    }
    
    @IBAction func btnSignPressed(_ sender: Any) {
        let vc = storyboard!.instantiateViewController(withIdentifier: "SignUpViewController") as! SignUpViewController
        vc.completion = { (email, pwd) in
            self.email = email
            self.pwd = pwd
            self.btnLoginPressed(1)
        }
        self.present(vc, animated: true, completion: nil)
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
     }
     }
     }
     */
}

