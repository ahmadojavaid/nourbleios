//
//  ModifyProductViewController.swift
//  NOUR
//
//  Created by abbas on 6/5/20.
//  Copyright © 2020 abbas. All rights reserved.
//

import UIKit
import Firebase

class ModifyProductViewController: BaseViewController {
    
    var product:Product!
    var ref: DatabaseReference!
    
    @IBOutlet weak var bgViewKey: UIView!
    @IBOutlet weak var bgViewWallet: UIView!
    @IBOutlet weak var bgViewOther: UIView!
    @IBOutlet weak var btnKey: UIButton!
    @IBOutlet weak var btnWellet: UIButton!
    @IBOutlet weak var btnOther: UIButton!
    @IBOutlet weak var lblOther: UILabel!
    
    @IBOutlet weak var otherView: UIView!
    
    @IBOutlet weak var txtName: APTextField!
    @IBOutlet weak var txtOther: UITextView!
    @IBOutlet weak var txtDated: APTextField!
    @IBOutlet weak var txtID: APTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //addTxtWaletRightView()
        configureOtherViews()
        
        ref = Database.database().reference()
        
        btnKey.setTitleColor(Theme.Colors.whiteText, for: .selected)
        btnKey.setTitleColor(Theme.Colors.redText, for: .normal)
        btnWellet.setTitleColor(Theme.Colors.whiteText, for: .selected)
        btnWellet.setTitleColor(Theme.Colors.redText, for: .normal)
        btnOther.setTitleColor(Theme.Colors.whiteText, for: .selected)
        btnOther.setTitleColor(Theme.Colors.redText, for: .normal)
        
        txtDated.text = product.regDate ?? ""
        let id = product.id 
        txtID.text = id.subString(id.count - 12, id.count - 1)
        txtDated.textColor = Theme.Colors.grayText
        txtID.textColor = Theme.Colors.grayText
        
        txtName.text = product.name ?? ""
        txtOther.text = product.other
        selectButton(id: ((product.type ?? "0") as NSString).integerValue )
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        otherView.cornerRadius = txtName.frame.size.height / 2
    }
    
    @IBAction func btnKeyPressed(_ sender: Any) {
        selectButton(id: 0)
    }
    @IBAction func btnWalledPressed(_ sender: Any) {
        selectButton(id: 1)
    }
    @IBAction func btnOtherPressed(_ sender: Any) {
        selectButton(id: 2)
    }
    
    @IBAction func btnSavePressed(_ sender: Any) {
        self.showProgress()
        let name = txtName.text ?? ""
        let other = txtOther.text ?? ""
        let type = btnKey.isSelected ? "0":(btnWellet.isSelected ? "1":"2")
        
        product.update(name:name, type:type, other:other)
        
        self.showToast("Details updated successfully", type: .success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.dismissProgress()
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func btnTrashPressed(_ sender: Any) {
        self.showProgress()
        let user = Signup.getUserBy(email: UserDefaults.standard.string(forKey: "loginEmail") ?? "").signup
        self.ref.child("UsersDevices").child(user?.uid ?? "").child(self.product.id).removeValue()
        
        if let index = BLEManager.shared.getPeripheralID(by: product.id) {
            BLEManager.shared.myPeripherals.remove(at: index)
        }
        
        let result = product.delete()
        if result.isSuccess {
            self.showToast(result.message, type: .success)
        } else {
            self.showToast(result.message, type: .error)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.dismissProgress()
            self.navigationController?.popViewController(animated: true)
        }
        
    }
    
    @IBAction func btnBackPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
}

extension ModifyProductViewController {
    
    fileprivate func selectButton(id:Int){
        switch id {
        case 0:
            btnKey.isSelected = true
            btnWellet.isSelected = false
            btnOther.isSelected = false
            bgViewKey.backgroundColor = Theme.Colors.redText
            bgViewWallet.backgroundColor = Theme.Colors.whiteText
            bgViewOther.backgroundColor = Theme.Colors.whiteText
            lblOther.textColor = Theme.Colors.redText
        case 1:
            btnKey.isSelected = false
            btnWellet.isSelected = true
            btnOther.isSelected = false
            bgViewKey.backgroundColor = Theme.Colors.whiteText
            bgViewWallet.backgroundColor = Theme.Colors.redText
            bgViewOther.backgroundColor = Theme.Colors.whiteText
            lblOther.textColor = Theme.Colors.redText
        default:
            btnKey.isSelected = false
            btnWellet.isSelected = false
            btnOther.isSelected = true
            bgViewKey.backgroundColor = Theme.Colors.whiteText
            bgViewWallet.backgroundColor = Theme.Colors.whiteText
            bgViewOther.backgroundColor = Theme.Colors.redText
            lblOther.textColor = Theme.Colors.whiteText
        }
    }
    
    fileprivate func addTxtWaletRightView() {
        //et rtview = UIView()
        
        //let tlabel:UILabel = {
        //    let label = UILabel()
        //    label.translatesAutoresizingMaskIntoConstraints = false
        //    label.text = "angle-down"
        //    label.font = UIFont.fontAwesome(ofSize: .font24, weight: .regular)
        //    label.textColor = Theme.Colors.redText
        //    return label
        //}()
        
        //rtview.addSubview(tlabel)
        //txtWallet.rightView = rtview
        //txtWallet.rightViewMode = .always
        /*
        let constraints = [
            tlabel.topAnchor.constraint(equalTo: rtview.topAnchor),
            tlabel.bottomAnchor.constraint(equalTo: rtview.bottomAnchor),
            tlabel.rightAnchor.constraint(equalTo: rtview.rightAnchor, constant: -15),
            tlabel.leftAnchor.constraint(equalTo: rtview.leftAnchor, constant: 10)
        ]
        
        NSLayoutConstraint.activate(constraints)
        */
    }
    
    fileprivate func configureOtherViews() {
        txtOther.font = Theme.Font.ofSize(.font15, weight: .regular)
        txtOther.textColor = Theme.Colors.darkText
        otherView.clipsToBounds = true
    }
    
}
