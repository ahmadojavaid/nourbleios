//
//  LinkProductController.swift
//  NOUR
//
//  Created by abbas on 6/28/20.
//  Copyright © 2020 abbas. All rights reserved.
//

import UIKit
import CoreBluetooth

class LinkProductController: BaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func btnPairPressed(_ sender: Any) {
        let vc = storyboard?.instantiateViewController(withIdentifier: "ScanDevicesController") as! ScanDevicesController
        vc.configure { peripheral in
            self.showAlert(message: "Product Successfully Paired. Please \nadd information on the next step.") {
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "LinkProductDetailsViewController") as! LinkProductDetailsViewController
                vc.peripheral = peripheral
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
        self.present(vc, animated: true, completion: nil)
    }
    
    @IBAction func btnBackPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    
}
