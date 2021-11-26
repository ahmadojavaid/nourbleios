//
//  ListDevicesCell.swift
//  NOUR
//
//  Created by abbas on 6/26/20.
//  Copyright © 2020 abbas. All rights reserved.
//

import UIKit

class ListDevicesCell: UITableViewCell {
    
    @IBOutlet weak var lblLeft: APLabel!
    @IBOutlet weak var lblRight: APLabel!
    @IBOutlet weak var btnInfo: UIButton!
    
    func setData(
        textL:String,
        textR:String? = nil,
        target:Any? = nil,
        selector:Selector? = nil) {
        
        lblLeft.text = textL
        if let text = textR {
            lblRight.text = text
            btnInfo.addTarget(target, action: selector!, for: .touchUpInside)
            backgroundColor = Theme.Colors.whiteText
        } else {
            backgroundColor = .clear
            lblRight.isHidden = true
            btnInfo.isHidden = true
            lblLeft.customize(.font16, .regular, .grayText)
        }
        
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        lblRight.customize(.font16, .regular, .darkText)
        lblRight.customize(.font15, .regular, .grayText)
    }
    
}
