//
//  ScanDevicesController.swift
//  NOUR
//
//  Created by abbas on 6/26/20.
//  Copyright © 2020 abbas. All rights reserved.
//

//import SwiftyBluetooth
import UIKit
import CoreBluetooth

class ScanDevicesController: BaseViewController {
    
    
    @IBOutlet weak var tableView: UITableView!
    
    fileprivate var manager:BLEManager!
    
    var completion:((_ peripheral:CBPeripheral)->Void)?
    
    var cells:[UITableViewCell] = []
    var peripherals: [[CBPeripheral]] = [[],[]]
    
    func configure(completion:((_ peripheral:CBPeripheral) -> Void)?) {
        self.modalPresentationStyle = .overCurrentContext
        self.modalTransitionStyle = .crossDissolve
        self.completion = completion
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.Colors.windowOver
        peripherals[0] = [] //BLEManager.shared.myPeripherals.map
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        reloadData()
        scanPeripherals()
    }
    
    @IBAction func btnColosePressed(_ sender: Any) {
        self.dismiss(animated: false, completion: nil)
    }
    
    @objc func btninfoPressed(){
        print("btninfoPressed")
    }
    
    func reloadData() {
        cells = []
        
        for (id, peripheralList) in peripherals.enumerated() {
            let cell1 = ListDevicesCell.getInstance(nibName: "ListDevicesCell") as! ListDevicesCell
            cell1.setData(textL: id==0 ? "My Devices":"Other Devices")
            cells.append(cell1)
            for peripheral in peripheralList {
                let cell = ListDevicesCell.getInstance(nibName: "ListDevicesCell") as! ListDevicesCell
                let txtR = peripheral.state == .connected ? "Connected":"Not Connected"
                cell.setData(textL: peripheral.name ?? "\(peripheral.identifier)", textR: txtR, target: self, selector: #selector(btninfoPressed))
                cells.append(cell)
            }
        }
        
        tableView.reloadData()
    }
    
    fileprivate func isInPeriphera(peripheral:CBPeripheral) -> (sec:Int, id:Int, isFound:Bool) {
        for (sec, perifriList) in peripherals.enumerated() {
            for (id, perifir) in perifriList.enumerated() {
                if perifir.identifier == peripheral.identifier {
                    return (sec, id, true)
                }
            }
        }
        return (0, 0, false)
    }
    
    func scanPeripherals(){
        manager = BLEManager { (isReady, message) -> Bool in
            if isReady {
                self.manager.scanPeripherals(time: 30) { (isSuccess, peripheral, advertisementData, message) -> Bool in
                    let name = (advertisementData["kCBAdvDataLocalName"] as? String ?? "") + (peripheral.name ?? "")
                    if name.uppercased().contains("BEACON") {
                        let prfri = self.isInPeriphera(peripheral: peripheral)
                        if prfri.isFound {
                            if prfri.sec == 1 {
                                self.peripherals[1][prfri.id] = peripheral
                                self.reloadData()
                            }
                        } else {
                            self.peripherals[1].append(peripheral)
                            self.reloadData()
                        }
                    }
                    return false
                }
            return true
            } else {
                self.showToast(message, type: .error)
                return false
            }
        }
    }
}

extension ScanDevicesController:UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cells.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return cells[indexPath.row]
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: false)
        if indexPath.row > 0 {
            
            var id = 0
            if indexPath.row <= peripherals[0].count {
                id = indexPath.row - 1
            } else if indexPath.row == (peripherals[0].count + 1) {
                return
            } else {
                id = indexPath.row - 2
            }
            let row = id >= peripherals[0].count ? 1:0
            let coll = id >= peripherals[0].count ? id - peripherals[0].count:id
            let peripheral = peripherals[row][coll]
            manager.connect(peripheral: peripheral) { (isSuccess, message) in
                if isSuccess {
                    self.dismiss(animated: true) {
                        self.completion?(peripheral)
                    }
                } else {
                    self.showToast(message, type: .error)
                }
                return true
            }
        }
    }
}
