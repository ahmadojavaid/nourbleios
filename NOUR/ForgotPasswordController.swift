//
//  ForgotPasswordController.swift
//  NOUR
//
//  Created by Abbas on 30/11/2020.
//  Copyright © 2020 abbas. All rights reserved.
//

import UIKit
import Firebase

class ForgotPasswordController: BaseViewController {
    
    @IBOutlet weak var txtEmail: APTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func btnSendLink(_ sender: Any) {
        let eValidation = (txtEmail.text ?? "").validate(with: Constants.emailRegix)
        guard eValidation.isValid else {
            self.showToast(eValidation.message ?? "Please enter valid email address", type: .error)
            return
        }
        self.showProgress()
        Auth.auth().sendPasswordReset(withEmail: txtEmail.text ?? "") { error in
            self.dismissProgress()
            if error == nil {
                self.showToast("An email with recovery link is sent at the given address. Please follow the link for password recovery.", type: .success)
            } else {
                self.showToast(error!.localizedDescription, type: .error)
            }
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
