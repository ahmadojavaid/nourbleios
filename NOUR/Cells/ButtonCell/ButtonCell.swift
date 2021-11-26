//
//  ButtonCell.swift
//  NOUR
//
//  Created by abbas on 6/2/20.
//  Copyright © 2020 abbas. All rights reserved.
//

import UIKit

class ButtonCell: UITableViewCell {
    
    @IBOutlet weak var button: APButton!

    func setData(title:String, target:Any, selector:Selector){
        button.setTitle(title, for: .normal)
        button.addTarget(target, action: selector, for: .touchUpInside)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
}
