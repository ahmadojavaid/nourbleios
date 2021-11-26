//
//  APButton.swift
//  TheICERegister
//
//  Created by abbas on 5/13/20.
//  Copyright © 2020 abbas. All rights reserved.
//

import UIKit
open class APButton:UIButton {

    var image:UIImage?
    var buttonStyle:ButtonStyle = .simple
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        self.customization()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.customization()
    }
    
    convenience init(style:ButtonStyle, image:UIImage? = nil) {
        self.init(frame: CGRect())
        self.image = image
        self.buttonStyle = style
        customization()
    }
    
    func customize(_ title:String? = nil, _ fontSize: FontSize, _ weight: FontWeight, _ color: TextColors, for state:UIControl.State) {
        if let title = title {
            setTitle(title, for: state)
        }
        titleLabel?.font = Theme.Font.ofSize(fontSize, weight: weight)
        setTitleColor(color.value, for: state)
    }
    
    fileprivate func customization(){
        translatesAutoresizingMaskIntoConstraints = false
        setImage(nil, for: .normal)
        setBackgroundImage(nil, for: .normal)
        backgroundColor = .clear
        layer.borderWidth = 0
        isEnabled = true
        
        switch buttonStyle {
        case .simple:
            setTitleColor(Theme.Colors.darkText, for: .normal)
            titleLabel?.font = Theme.Font.ofSize(.font14, weight: .regular)
        case .redSimple:
            setTitleColor(Theme.Colors.redText, for: .normal)
            titleLabel?.font = Theme.Font.ofSize(.font14, weight: .semiBold)
        case .redSolid:
            setTitleColor(Theme.Colors.whiteText, for: .normal)
            titleLabel?.font = Theme.Font.ofSize(.font14, weight: .regular)
            backgroundColor = Theme.Colors.redText
            clipsToBounds = true
        case .redBorder:
            setTitleColor(Theme.Colors.redText, for: .normal)
            titleLabel?.font = Theme.Font.ofSize(.font14, weight: .regular)
            backgroundColor = .white
            clipsToBounds = true
            layer.borderWidth = 1
            layer.borderColor = Theme.Colors.redText.cgColor
        case .image:
            setBackgroundImage(image, for: .normal)
            break
        }
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        if buttonStyle == .redBorder || buttonStyle == .redSolid {
            self.setRoundCorners()
        }
    }
    
    func setRoundCorners(){
        layer.cornerRadius = self.frame.size.height / 2
    }
}

extension APButton {
    func setStyle(_ buttonStyle: ButtonStyle) {
        self.buttonStyle = buttonStyle
        self.customization()
    }
    @IBInspectable var setStyle:Int {
        set {
            setStyle(ButtonStyle(rawValue: newValue) ?? ButtonStyle.simple)
        }
        get {
            return self.buttonStyle.rawValue
        }
    }
}

@objc enum ButtonStyle:Int {
    case simple = 0
    case redSimple = 1
    case redSolid = 2
    case redBorder = 3
    case image = 4
    
    var value:Int {
        return self.rawValue
    }
}
