//
//  SignUpViewController.swift
//  NOUR
//
//  Created by abbas on 6/2/20.
//  Copyright © 2020 abbas. All rights reserved.
//

import UIKit

class SignUpViewController: UIViewController {
    
    @IBOutlet weak var btnAddImage: APButton!
    @IBOutlet weak var tableView: UITableView!
    
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
        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        
        for (id, data) in mataData.enumerated() {
            switch id {
            case mataData.count - 1:
                let cell = ButtonCell.getInstance(nibName: "ButtonCell") as! ButtonCell
                cell.setData(title: data[0])
                cells.append(cell)
            default:
                let cell = TextFieldCell.getInstance(nibName: "TextFieldCell") as! TextFieldCell
                cell.setData(placeHolder: data[0], text: data[1])
                cells.append(cell)
            }
        }
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
