//
//  Theme.swift
//  HireSecurity
//
//  Created by abbas on 1/30/20.
//  Copyright © 2020 abbas. All rights reserved.
//

import UIKit

class Theme {
    private static let standardHeight:CGFloat = 414.0 // iPhone 11 Pro Max Width
    private static let standardHeightT:CGFloat = 896.0
    
    static func screenWidth() -> CGFloat {
        return UIScreen.main.bounds.size.width
    }
    static func screenHeight() -> CGFloat {
        return UIScreen.main.bounds.size.height
    }
    
    private static func screenSize(_ isTrue:Bool = false) -> CGFloat {
        let h = screenHeight()
        let w = screenWidth()
        if isTrue {
            return h > w ? h:w
        } else {
            return h < w ? h:w
        }
    }
    
    static func standardRatio()->CGFloat{
        return screenSize()/standardHeight
    }
    
    static func standardRatioH()->CGFloat{
        return screenSize(true)/standardHeightT
    }
    
    static func adjustRatio(_ value:CGFloat) -> CGFloat {
        return (value * 0.75) + (value * 0.25 * standardRatio())
    }
    static func adjustRatioH(_ value:CGFloat) -> CGFloat {
        return (value * 0.5) + (value * 0.5 * standardRatioH())
    }
    
    static var standerdSpace:CGFloat = adjustRatio(10)
    static var standerdSpaceH:CGFloat = adjustRatioH(10)
    
    class Colors {
        static var tint:UIColor = darkText
        static var whiteText:UIColor = #colorLiteral(red: 0.9881282449, green: 0.9882970452, blue: 0.988117516, alpha: 1)
        static var backGround:UIColor = whiteText
        
        static var darkText:UIColor = #colorLiteral(red: 0.1137315854, green: 0.1138764545, blue: 0.1055296734, alpha: 1)
        static var grayText:UIColor = #colorLiteral(red: 0.6235638261, green: 0.6196319461, blue: 0.6194853187, alpha: 1) // ??
        static var disabled:UIColor = #colorLiteral(red: 0.854808569, green: 0.8549557328, blue: 0.8547992706, alpha: 1) // ??
        static var goldText:UIColor = #colorLiteral(red: 0.7963936925, green: 0.6219727397, blue: 0.3873476982, alpha: 1)
        static var redText:UIColor =  #colorLiteral(red: 0.753674686, green: 0.06874708831, blue: 0.1020690575, alpha: 1)
 
        static var lightGray:UIColor = #colorLiteral(red: 0.9333360195, green: 0.9294541478, blue: 0.929254353, alpha: 1) // ???
        static var primary:UIColor = redText
        static var secondry:UIColor = goldText
        static var borderColor:UIColor = redText
        
        static var windowOver = UIColor(red: 0, green: 0, blue: 0, alpha: 0.4)
        
        //static var blueText:UIColor =  Colors.tint
        //static var redBorder:UIColor = #colorLiteral(red: 0.9780651927, green: 0.4207268357, blue: 0.3205661774, alpha: 1)
        //static var lightBlue:UIColor = Colors.secondry
    }
    
    class Font {
        static func ofSize(_ size:FontSize = .font17, weight:FontWeight) -> UIFont {
            //let fontName = "\(Constants.appFont)\(weight.value == "Regular" ? "":"-\(weight.value)")"
            let fontName = "\(Constants.appFont)-\(weight.value)"
            let fontSize = Theme.adjustRatio(CGFloat(size.value))
            let selectedFont = UIFont.init(name: fontName, size: fontSize)
            print("AppFont: \(String(describing: selectedFont)), FontName: \(fontName) FontSize:\(fontSize)")
            //let fPicker = FontPicker()
            //print(fPicker.familyNames)
            if selectedFont != nil {
                return selectedFont!
            } else if let weight = weight.sysWeight(){
                return UIFont.systemFont(ofSize: fontSize, weight: weight)
            } else {
                return UIFont.italicSystemFont(ofSize: fontSize)
            }
        }
    }
}

extension FontWeight {
    func sysWeight() -> UIFont.Weight? {
        switch self {
        case .light:
            return UIFont.Weight.light
        case .regular:
            return UIFont.Weight.regular
        case .medium:
            return UIFont.Weight.medium
        case .bold:
            return UIFont.Weight.bold
        case .extraBold:
            return UIFont.Weight.heavy
        case .heavy:
            return UIFont.Weight.black
        default:
            return nil
        }
    }
}
