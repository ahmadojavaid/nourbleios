//
//  HomeViewController.swift
//  NOUR
//
//  Created by abbas on 6/3/20.
//  Copyright © 2020 abbas. All rights reserved.
//

import UIKit
import MapKit
import FSPagerView
import CoreBluetooth
import Firebase

extension HomeViewController {
    fileprivate func selectButton(id:Int){
        switch id {
        case 0: // Select Home
            lblHOme.font = UIFont.fontAwesome(ofSize: .font26, weight: .solid)
            lblProfile.font = UIFont.fontAwesome(ofSize: .font26, weight: .regular)
            homeView.backgroundColor = Theme.Colors.redText
            profileView.backgroundColor = Theme.Colors.whiteText
            lblHOme.textColor = Theme.Colors.whiteText
            lblProfile.textColor = Theme.Colors.grayText
        default:
            lblHOme.font = UIFont.fontAwesome(ofSize: .font26, weight: .regular)
            lblProfile.font = UIFont.fontAwesome(ofSize: .font26, weight: .solid)
            homeView.backgroundColor = Theme.Colors.whiteText
            profileView.backgroundColor = Theme.Colors.redText
            lblHOme.textColor = Theme.Colors.grayText
            lblProfile.textColor = Theme.Colors.whiteText
        }
    }
}

class HomeViewController: BaseViewController {
    var isSignedIn = false
    @IBOutlet weak var lblHOme: UILabel!
    @IBOutlet weak var homeView: UIView!
    @IBOutlet weak var lblProfile: UILabel!
    @IBOutlet weak var profileView: UIView!
    @IBOutlet weak var globalProgressView: UIView!
    @IBOutlet weak var globalProgressLabel: APLabel!
    
    @IBOutlet weak var pagerView: FSPagerView!
    @IBOutlet weak var pagerCenterxConstraint: NSLayoutConstraint!
    @IBOutlet weak var noCardView: UIView!
    
    @IBOutlet weak var lblConnected: APLabel!
    @IBOutlet weak var lblName: APLabel!
    @IBOutlet weak var lblLastUpdate: APLabel!
    @IBOutlet weak var lblComment: APLabel!
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var btnRingitOutlet: APButton!
    
    @IBOutlet weak var profileContainer: UIView!
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    fileprivate var latitude:Double = 0
    fileprivate var longitude:Double = 0
    
    fileprivate var bleStateObserver:NSKeyValueObservation!
    fileprivate var peripheralStateObserver:NSKeyValueObservation!
    fileprivate var myPeripheralsObserver:NSKeyValueObservation!
    
    var products:[Product] = [] {
        didSet {
            didChangePages()
            setupData()
        }
    }
    var ref: DatabaseReference!
    
    var prevCell:Int = 0
    var isChanged = false
    var currentCell:Int = 0 {
        didSet {
            animateNewCell()
            setupData()
            updateObserver()
        }
    }
    
    func disableShortly() {
        btnRingitOutlet.isEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            self.btnRingitOutlet.isEnabled = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
         ref = Database.database().reference()
        
        initialSetup()
        updateLocationsOnMap()
        AppDelegate.shared?.readRSSI()
        //disableShortly()
        //NotificationCenter.default.addObserver(self, selector: #selector(locationDidUpdated), name: NSNotification.Name.LocationDidUpdated, object: nil)
        //DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
        //    BLEManager.shared.retrivePeripherals { (isSuccess) in
        //        print("Retrived")
        //    }
        //}
        btnRingitOutlet.setTitleColor(Theme.Colors.grayText, for: .disabled)
        BLEManager.shared.configure()
        
        //self.showProgress(text: "Loading...")
        //dismissLoadingProgress()
    }
    
    
    func addMyPeripheralsObserver() {
        guard BLEManager.shared.centralManager.state == .poweredOn else {
            return
        }
        self.myPeripheralsObserver?.invalidate()
        self.myPeripheralsObserver = BLEManager.shared.observe(\BLEManager.myPeripherals, options: .new) { (manager, change) in
            if manager.myPeripherals.count > 0 {
                self.updateObserver()
            }
        }
    }
    
    func addBLEStateObserver() {
        self.bleStateObserver?.invalidate()
        updateBLEState(state: BLEManager.shared.centralManager.state)
        self.bleStateObserver = BLEManager.shared.centralManager.observe(\CBCentralManager.state, options: .new) { (manager, change) in
            self.updateBLEState(state: manager.state)
        }
    }
    
    fileprivate func updateBLEState(state:CBManagerState){
        switch state {
        case .poweredOff, .unauthorized:
            self.myPeripheralsObserver?.invalidate()
            self.peripheralStateObserver?.invalidate()
            self.dismissProgress()
            self.showGlobalProgress(text: state == .poweredOff ? "Phone bluetooth is Off.":"Bluetooth access to Nour was restricted. This can be configured in phone settings.")
        case .poweredOn:
            self.addMyPeripheralsObserver()
            self.updateObserver()
            self.hideGlobalProgress()
        default:
            break
        }
    }
    
    func updateObserver() {
        guard BLEManager.shared.centralManager.state == .poweredOn else {
            return
        }
        self.hideGlobalProgress()
        guard BLEManager.shared.myPeripherals.count > 0 else {
            self.showGlobalProgress(text: "Not Connected")
            return
        }
        guard let index = BLEManager.shared.getPeripheralID(by: self.products[self.currentCell].id) else {
            self.showGlobalProgress(text: "Not Connected")
            return
        }
        self.peripheralStateObserver?.invalidate()
        self.peripheralStateObserver = BLEManager.shared.myPeripherals[index].observe(\APPeripheralManager.state, options: .new) { (manager, change) in
            switch manager.state {
            case .disconnected, .disconnecting, .unknown, .connecting:
                self.dismissProgress()
                self.showGlobalProgress(text: manager.state.message)
            case .discovering, .connected:
                self.hideGlobalProgress()
                self.showProgress()
            case .idleDiscoverd:
                self.hideGlobalProgress()
                self.dismissProgress()
            default:
                break
            }
        }
    }
    
    func locationDidUpdated() {
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //NotificationCenter.default.removeObserver(self, name: NSNotification.Name.LocationDidUpdated, object: nil)
        self.products = []
        self.myPeripheralsObserver?.invalidate()
        self.bleStateObserver?.invalidate()
        self.peripheralStateObserver?.invalidate()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.products = []
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.products = Product.getAllProducts().products
            self.addBLEStateObserver()
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        var size = pagerView.frame.size
        size.width = size.height * 287/143
        pagerView.itemSize = size
    }
    
    func setupData() {
        if products.count > self.currentCell {
            lblName.text = products[currentCell].name ?? ""
            lblComment.text = products[currentCell].other ?? ""
            lblLastUpdate.text = products[currentCell].lastUpdateDate ?? ""
        }
    }
    
    func updateLocationsOnMap() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.updateLocationsOnMap()
        }
        guard products.count > currentCell else {
            return
        }
        let pruduct = Product.getProductBy(id: products[currentCell].id).product
        self.latitude = ((pruduct?.latitude ?? "0") as NSString).doubleValue
        self.longitude = ((pruduct?.longitude ?? "0") as NSString).doubleValue
        let location = CLLocation (
            latitude: CLLocationDegrees(latitude),
            longitude: CLLocationDegrees(longitude)
        )
        mapView.centerToLocation(location)
    }
    
    @IBAction func btnRingIt(_ sender: Any) {
        //disableShortly()
        guard let pIndex = BLEManager.shared.getPeripheralID(by: products[currentCell].id) else {
            self.showToast("Card not connected.", type: .error)
            return
        }
        
        guard BLEManager.shared.centralManager.state != .poweredOff else {
            self.showToast("Bluetooth is powered off.", type: .error)
            return
        }
        
        let data = Data([UInt8(2)])
        self.showProgress(text: "Sending Command...")
        //DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
        //    self.dismissProgress()
        //}
        BLEManager.shared.myPeripherals[pIndex].writeValue(characUUID: CBConfig.buzzerCharac, serviceUUID: CBConfig.buzzerService, data: data, responseOption: .withoutResponse) { (isSuccess, message) -> Bool in
            self.dismissProgress()
            if isSuccess {
                self.showAlert(message: "Ringing.....!", completion: nil)
            } else {
                if message.contains("not permitted") {
                    self.showToast("Peripherals Device is busy. Please try again in few seconds.", type: .default)
                } else {
                    self.showToast(message, type: .error)
                }
            }
            return true
        }
    }
    
    @IBAction func btnOpeninmaps(_ sender: Any) {
        guard products.count > currentCell else {
            return
        }
        
        openMap(lattitude: self.latitude, longitude: self.longitude)
    }
    
    @IBAction func btnModify(_ sender: Any) {
        let vc = storyboard!.instantiateViewController(withIdentifier: "ModifyProductViewController") as! ModifyProductViewController
        vc.product = products[currentCell]
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func btnAddProduct(_ sender: Any) {
        
        /*
        let user = Signup.getUserBy(email: UserDefaults.standard.string(forKey: "loginEmail") ?? "").signup
        let pid = UUID().uuidString
        
        let newProduct:[String:String] = [
            "id":pid,
            "deviceTitle":"E-wallet",
            "type":"Wallet",
            "battery":"67",
            "comment":"This is my E wallet",
            "deviceAddress":"",
            "lastUpdated":Date().toString("dd-MM-yyyy"),
            "latitude":"31.4627783",
            "longitude":"74.2721737",
            "rssi":"0",
            "timePaired":Date().toString("dd-MM-yyyy")
            
            //"user": user?.uid ?? ""
        ]
        
        self.showProgress()
        self.ref.child("UsersDevices").child(user?.uid ?? "").child(pid).setValue(newProduct) { (error, _) in
            self.dismissProgress()
            if error != nil {
                self.showToast(error!.localizedDescription, type: .error)
            }
        }
        
        return
        */
        let vc = storyboard!.instantiateViewController(withIdentifier: "LinkProductController")
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func btnTabHomePressed(_ sender: Any) {
        profileContainer.isHidden = true
        selectButton(id: 0)
    }
    
    @IBAction func btnTabProfilePressed(_ sender: Any) {
        profileContainer.isHidden = false
        selectButton(id: 1)
    }
}

extension HomeViewController:FSPagerViewDelegate, FSPagerViewDataSource {
    func numberOfItems(in pagerView: FSPagerView) -> Int {
        return products.count
    }
    
    func pagerView(_ pagerView: FSPagerView, cellForItemAt index: Int) -> FSPagerViewCell {
        let cell = pagerView.dequeueReusableCell(withReuseIdentifier: "PagerViewCell", at: index) as! PagerViewCell
        cell.backgroundColor = .clear
        cell.imageView?.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
        cell.backgroundView?.backgroundColor = .clear
        cell.setData(productID: products[index].id)
        return cell
    }
    
    func pagerViewWillBeginDragging(_ pagerView: FSPagerView) {
        //isChanged = prevCell != pagerView.currentIndex
        prevCell = pagerView.currentIndex
        print("DDD WillBeginDragging :\(pagerView.currentIndex)")
    }
    
    //func pagerViewWillEndDragging(_ pagerView: FSPagerView, targetIndex: Int) {
    //    print("DDD WillEndDragging: \(pagerView.currentIndex) targetIndex: \(targetIndex)")
    //    if targetIndex != 0 {
    //        currentCell = targetIndex
    //    }
    //}
    
    func pagerViewDidEndDecelerating(_ pagerView: FSPagerView) {
        //if pagerView.currentIndex != currentCell {
        currentCell = pagerView.currentIndex
        //}
        print("DDD DidEndDecelerating: \(pagerView.currentIndex)")
    }
    
    func pagerView(_ pagerView: FSPagerView, willDisplay cell: FSPagerViewCell, forItemAt index: Int) {
        if index == currentCell {
            (cell as? PagerViewCell)?.setTheme(isWhite: false)
        } else {
            (cell as? PagerViewCell)?.setTheme(isWhite: true)
        }
    }
}

fileprivate extension HomeViewController {
    func didChangePages() {
        if self.products.count == 0 {
            self.pagerView.isHidden = true
            self.noCardView.isHidden = false
            self.scrollView.isHidden = true
        } else {
            self.pagerView.reloadData()
            self.pagerView.isHidden = false
            self.noCardView.isHidden = true
            self.scrollView.isHidden = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                self.pagerView.selectItem(at: 0, animated: false)
                self.currentCell = 0
            }
        }
    }
    
    func animateNewCell() {
        if self.prevCell != self.currentCell {
            (self.pagerView.cellForItem(at: self.currentCell) as? PagerViewCell)?.setTheme(isWhite: false)
            (self.pagerView.cellForItem(at: self.prevCell) as? PagerViewCell)?.setTheme(isWhite: true)
            UIView.animate(withDuration: 0.5) {
                switch self.currentCell {
                case 0:
                    let const = (self.view.frame.size.width - self.pagerView.frame.size.height * 287/143)/2 - 20
                    self.pagerCenterxConstraint.constant = -const
                    self.view.layoutIfNeeded()
                case self.products.count - 1:
                    let const = (self.view.frame.size.width - self.pagerView.frame.size.height * 287/143)/2 - 20
                    self.pagerCenterxConstraint.constant = const
                    self.view.layoutIfNeeded()
                default:
                    self.pagerCenterxConstraint.constant = 0
                    self.view.layoutIfNeeded()
                }
            }
        }
    }
}

fileprivate extension HomeViewController {
    func initialSetup() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let const = (self.view.frame.size.width - self.pagerView.frame.size.height * 287/143)/2 - 20
            self.pagerCenterxConstraint.constant = -const
            self.view.layoutIfNeeded()
        }
        
        globalProgressView.backgroundColor = Theme.Colors.windowOver
        
        navigationController?.setNavigationBarHidden(true, animated: true)
        pagerView.delegate = self
        pagerView.dataSource = self
        pagerView.backgroundColor = .clear
        pagerView.clipsToBounds = true
        pagerView.interitemSpacing = 16
        //pagerView.transformer = FSPagerViewTransformer(type: .linear)
        pagerView.register(UINib(nibName: "PagerViewCell", bundle: .main), forCellWithReuseIdentifier: "PagerViewCell")
    }
    
    func openMap(lattitude:Double, longitude:Double){
        if (UIApplication.shared.canOpenURL(URL(string:"comgooglemaps://")!)) {
            UIApplication.shared.open(URL(string:
                "comgooglemaps://?daddr=\(lattitude),\(longitude)&directionsmode=driving")!)
        } else if (UIApplication.shared.canOpenURL(URL(string:"http://maps.apple.com/")!)) {
            UIApplication.shared.open(URL(string: "http://maps.apple.com/?daddr=\(lattitude),\(longitude)&directionsmode=driving")!)
        } else {
            NSLog("Maps application not found//");
            self.showToast("Maps application not found", type: .error)
        }
    }
    func showGlobalProgress(text:String) {
        self.globalProgressView.isHidden = false
        self.globalProgressLabel.text = text
    }
    func hideGlobalProgress(){
        self.globalProgressView.isHidden = true
    }
}

private extension MKMapView {
    func centerToLocation(
        _ location: CLLocation,
        regionRadius: CLLocationDistance = 50000
    ) {
        let coordinateRegion = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: regionRadius,
            longitudinalMeters: regionRadius)
        setRegion(coordinateRegion, animated: true)
    }
}
