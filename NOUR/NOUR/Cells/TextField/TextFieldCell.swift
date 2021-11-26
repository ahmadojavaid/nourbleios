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
    
    func setData(placeHolder:String, text:String) {
        textField.setPlaceHolder = placeHolder
        textField.text = text
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    
}
