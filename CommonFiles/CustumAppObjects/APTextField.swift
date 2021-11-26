//
//  APTextFieldUI.swift
//  TheICERegister
//
//  Created by abbas on 5/22/20.
//  Copyright © 2020 abbas. All rights reserved.
//

import UIKit
class APTextField: UITextField {
    
    var color: TextColors = .darkText
    var weight: FontWeight = .regular
    var size: FontSize! = .font15
    
    let placeHolder:APLabel = {
        let label = APLabel()
        label.customize(.font15, .regular, .grayText)
        return label
    }()
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.customization()
        leftRightViews()
        delegate = self
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.customization()
        leftRightViews()
        delegate = self
    }
    
    convenience init(fontSize:FontSize, color:TextColors = .darkText, weight:FontWeight = .regular ) {
        self.init(frame: CGRect())
        customize(fontSize, weight, color)
        leftRightViews()
    }
    
    func customize(_ fontSize: FontSize, _ weight: FontWeight, _ color: TextColors) {
        self.size = fontSize
        self.weight = weight
        self.color = color
        customization()
    }
    
    fileprivate func leftRightViews() {
        let lView = UIView()
        lView.addSubview(placeHolder)
        leftView = lView
        leftViewMode = .always
        
        let rView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: 40))
        rightView = rView
        rightViewMode = .always
        
        let constraints = [
            placeHolder.topAnchor.constraint(equalTo: lView.topAnchor),
            placeHolder.bottomAnchor.constraint(equalTo: lView.bottomAnchor),
            placeHolder.rightAnchor.constraint(equalTo: lView.rightAnchor, constant: -15),
            placeHolder.leftAnchor.constraint(equalTo: lView.leftAnchor, constant: 10)
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
    fileprivate func customization(){
        translatesAutoresizingMaskIntoConstraints = false
        font = Theme.Font.ofSize(self.size, weight: self.weight)
        textColor = self.color.value
        tintColor = Theme.Colors.tint
        backgroundColor = Theme.Colors.whiteText
        //borderStyle = .none
        
        addShadow(yOffset: 0.5, shadowColor: Theme.Colors.darkText.cgColor)
        textAlignment = .right
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        self.setRoundCorners()
    }
    
    func setRoundCorners(){
        layer.cornerRadius = self.frame.size.height / 2
    }
}


extension APTextField {
    
    @IBInspectable var setPlaceHolder:String {
        set {
            self.placeHolder.text = newValue
        }
        
        get {
            return self.placeHolder.text ?? ""
        }
    }
    
    @IBInspectable var setWeight:String {
        set {
            self.weight = FontWeight(rawValue: newValue.lowercased()) ?? FontWeight.regular
            self.customization()
        }
        
        get {
            return self.weight.value
        }
    }
    
    @IBInspectable var setSize:Int {
        set {
            self.size = FontSize(rawValue: newValue) ?? FontSize.font17
            self.customization()
        }
        get {
            return self.size.value
        }
    }
    
    @IBInspectable var setColor:String {
        set {
            self.color = TextColors(rawValue: newValue) ?? TextColors.darkText
            self.customization()
        }
        get {
            return self.color.raw
        }
    }
}
extension APTextField:UITextFieldDelegate{
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.textAlignment = .left
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        UIView.animate(withDuration: 0.2) {
            self.textAlignment = .right
            self.layoutSubviews()
        }
    }
}

/*
enum TextFieldType:Int {
    case simple
    case `default`
    case `disabled`
    
}
*/
