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

    func setData(title:String){
        button.setTitle(title, for: .normal)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
}
