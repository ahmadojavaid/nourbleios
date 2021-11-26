//
//  ScanViewController.swift
//  TextCoreBlueTooth
//
//  Created by abbas on 3/24/20.
//  Copyright © 2020 abbas. All rights reserved.
//

import UIKit
import CoreBluetooth
import CoreLocation

class ScanViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var lblStatus: UILabel!
    //private let locationManager: CLLocationManager = CLLocationManager()
    
    var centralManager: CBCentralManager!
    var bluePeripheral: [CBPeripheral] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialSetup()
        
    }
    
    @objc func searchDevices() {
        centeralStateMessage(centralManager.state)
    }
    @objc fileprivate func btnConnectPressed(_ sender: UIButton) {
        if bluePeripheral[sender.tag].state != .connected {
            print("CM will connect to: \(bluePeripheral[sender.tag])")
            centralManager?.connect(bluePeripheral[sender.tag], options: nil)
            tableView.reloadData()
            //sender.isEnabled = false
        } else {
            //sender.isSelected = true
            centralManager?.cancelPeripheralConnection(bluePeripheral[sender.tag])
            tableView.reloadData()
            print("CM Disconnected with: \(bluePeripheral[sender.tag])")
        }
    }
    
}

// MARK: - Centeral Manager Delegate
extension ScanViewController:CBCentralManagerDelegate{
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        centeralStateMessage(central.state)
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        //let isBeacon = Array(advertisementData.values).contains { ($0 as? String)?.contains("beacon") ?? false }
        //if isBeacon || (peripheral.name?.contains("beacon") ?? false) {
        //let found = bluePeripheral.first{ $0.identifier == peripheral.identifier }
        
        let name = (advertisementData["kCBAdvDataLocalName"] as? String ?? "") + (peripheral.name ?? "")
        if name.uppercased().contains("BEACON") {
            //bluePeripheral = peripheral
            //centralManager.stopScan()
            //blueConnect()
            //print("Device Printing..........................")
            //print("peripheral:\(peripheral)")
            //print("advertisementData:\(advertisementData)")
            //print("Device Printed...........................")
            //}
            
            if let index = bluePeripheral.firstIndex(where: { $0.identifier == peripheral.identifier }) {
                bluePeripheral[index] = peripheral
            } else {
                bluePeripheral.append(peripheral)
                print("New Peripheral DidDiscoverd \nPeripheral: \(peripheral) \nWithAdvertisementData: \(advertisementData)")
            }
            tableView.reloadData()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        tableView.reloadData()
        //peripheral.readRSSI()
        //print("RSSI: \(peripheral.rssi ?? 0.0)")
        logServices(peripheral: peripheral)
        
        let vc = storyboard?.instantiateViewController(identifier: "BeaconViewController") as! BeaconViewController
        vc.peripheral = peripheral
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        tableView.reloadData()
        if let error = error {
            self.showAlertMessage(title: "", message: error.localizedDescription)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        tableView.reloadData()
        if let error = error {
            self.showAlertMessage(title: "", message: error.localizedDescription)
        }
    }
    
}

//MARK: - Private Methods
extension ScanViewController {
    fileprivate func initialSetup() {
        centralManager = CBCentralManager(delegate: self, queue: nil)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "BeaconCell", bundle: .main), forCellReuseIdentifier: "BeaconCell")
        let scanButton = UIBarButtonItem(title: "Re-scan", style: .plain, target: self, action: #selector(searchDevices))
        self.navigationItem.rightBarButtonItem = scanButton
        self.navigationItem.rightBarButtonItem?.isEnabled = false
    }
    
    fileprivate func centeralStateMessage(_ centralState: CBManagerState) {
        switch centralState {
        case .unknown:
            print("CentralStateError: Please contact support. Unknown error occured while scaning for bluetooth Peripherals.")
        case .resetting:
            self.showAlertMessage(title: "", message: "Central.state is .resetting")
            print("Central.state is .resetting")
        case .unsupported:
            print("Central.state Unsupported device")
        case .unauthorized:
            self.showAlertMessage(title: "", message: "Central.state Go to settings and allow this App to access phone bluetooth.")
            print("Central.state go to settings and allow this ppp to access phone bluetooth.")
        case .poweredOff:
            self.showAlertMessage(title: "Bluetooth Off", message: "Please turn on phone bluetooth from settings")
            print("Central.state powerdOff")
        case .poweredOn:
            
            blueScan()
            print("central.state is .poweredOn\n CM Will Start Scanning...")
        @unknown default:
            fatalError()
        }
    }
    
    fileprivate func blueScan() {
        bluePeripheral = []
        print("Scanning...")
        self.navigationItem.rightBarButtonItem?.isEnabled = false
        //bluePeripheral = []
        self.lblStatus.text = "Scanning..."
        //let peripheralService = "edfec62e-9910-0bac-5241-d8bda6932a2f"
        //let serviceList = [CBUUID(string: peripheralService)]
        centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey:false])
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
            print("CM will end Scanning...")
            self.navigationItem.rightBarButtonItem?.isEnabled = true
            self.centralManager.stopScan()
            self.lblStatus.text = ""
            print("Scanning Stopped!")
        }
    }
    
    /*
     @objc fileprivate func btnConfig(_ sender: UIButton) {
     let peri = periferiCells[sender.tag]
     if peri.peripheral.state == .connected {
     let vc = storyboard?.instantiateViewController(identifier: "BeaconViewController") as! BeaconViewController
     vc.cell = peri
     self.navigationController?.pushViewController(vc, animated: true)
     print("User DiD Moved to Configrations")
     } else {
     self.showAlertMessage(title: "", message: "Device is not connected")
     }
     
     }
     */
}

//MARK: - TableView Delegate and DataSource
extension ScanViewController:UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        bluePeripheral.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BeaconCell") as! BeaconCell
        cell.setData(peripheral: bluePeripheral[indexPath.row], tag: indexPath.row, btConnect: (selctor: #selector(btnConnectPressed(_:)), targetVC: self))
        //cell.setData(peripheral: bluePeripheral[indexPath.row], tag: indexPath.row, btConnect: (selctor: #selector(btnConnectPressed(_:)), targetVC: self), btConfigureSelector: #selector(btnConfig(_:)))
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if bluePeripheral[indexPath.row].state == .connected {
            let vc = storyboard?.instantiateViewController(identifier: "BeaconViewController") as! BeaconViewController
            vc.peripheral = bluePeripheral[indexPath.row]
            self.navigationController?.pushViewController(vc, animated: true)
        } else {
            let button = UIButton()
            button.tag = indexPath.row
            btnConnectPressed(button)
        }
    }
    
    //func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    //(cell as? BeaconCell)?.adjustCellHeight()
    //}
}
//MARK: - Log Methods
extension ScanViewController {
    fileprivate func logServices(peripheral: CBPeripheral) {
        var strServices = ""
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            peripheral.services?.forEach { (service) in
                var char = ""
                service.characteristics?.forEach{ (charis) in
                    char += " \(charis.uuid),"
                }
                strServices += ("\(service.uuid) :\(char)\n")
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            print("Peripheral List of Services:Chars\n\(strServices)")
        }
    }
}
