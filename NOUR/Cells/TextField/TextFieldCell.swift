//
//  TextFieldCell.swift
//  NOUR
//
//  Created by abbas on 6/2/20.
//  Copyright © 2020 abbas. All rights reserved.
//

import UIKit

class TextFieldCell: UITableViewCell {
    
    @IBOutlet weak var textField: APTextField!
    
    /*
    ["Name", ""],
    ["Phone", ""],
    ["Address", ""],
    ["Country", ""],
    ["Email", ""],
    ["Password", ""],
    ["Repeat Password", ""],
    ["Sign up", ""]
    */
    
    func setData(placeHolder:String, text:String) {
        if "Country Name".contains(placeHolder) == true {
            textField.delegate = self
        }
        if "Phone".contains(placeHolder) == true {
            textField.keyboardType = .phonePad
        }
        if "Email".contains(placeHolder) == true {
            textField.keyboardType = .emailAddress
        }
        if placeHolder.contains("Password") == true {
            textField.isSecureTextEntry = true
        }
        textField.setPlaceHolder = placeHolder
        textField.text = text
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
}

extension TextFieldCell:UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.text = textField.text?.trimmed.capitalized
    }
}
