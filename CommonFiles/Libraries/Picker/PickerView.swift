//
//  PickerView.swift
//  Polse
//
//  Created by abbas on 2/20/20.
//  Copyright © 2020 abbas. All rights reserved.
//

import UIKit

class PickerView:UIPickerView {
    var completion: ((_ index:Int, _ element:String)->Void)?
    var data:[String] = [] {
        didSet {
            self.reloadAllComponents()
            self.tag = 0
        }
    }
    
    func getData() -> (index:Int, element:String){
        print("data \(data), tag \(tag)")
        return (self.tag, data.count > tag ? data[tag]:"")
    }
    
    init(data:Array<String>, completion:((_ index:Int, _ element:String)->Void)?) {
        super.init(frame: CGRect())
        delegate = self
        dataSource = self
        self.completion = completion
        self.data = data
        //if data.count > 0 {
        //    self.completion?(0)
        //}
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
extension PickerView:UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return data.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return data[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.tag = row
        self.completion?(row, data[row])
    }
}
