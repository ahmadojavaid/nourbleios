//
//  Enums.swift
//  Movies
//
//  Created by Zuhair on 2/17/19.
//  Copyright © 2019 Zuhair Hussain. All rights reserved.
//

import UIKit

enum NetworkStatus {
    case connected, disconnected
}

enum ToastType {
    case `default`, error, success
    
    var color: UIColor {
        switch self {
        case .default:
            return Theme.Colors.grayText
        case .error:
            return Theme.Colors.redText
        case .success:
            return Theme.Colors.secondry
        }
    }
}

enum ErrorMessages: String {
    case noNetwork = "Internet connection appears offline"
    case unknown = "Unable to communicate"
    case invalidRequest = "Invalid request"
    case invalidResponse = "Invalid response"
    case success = "Request completed successfully"
    case unauthenticated = "Unauthenticated"

    var localized: String {
        return NSLocalizedString(self.rawValue, comment: "")
    }
}

enum AnimationType {
    case fadeIn, fadeOut
}

enum FontWeight:String {
    case thin, extraLight, light, regular, medium, semiBold, bold, extraBold, heavy, thinItalic, extraLightItalic, lightItalic, italic, mediumItalic, semiBoldItalic, boldItalic, extraBoldItalic, heavyItalic
    
    var value:String {
        return self.rawValue.capitalized
    }
}

enum FontSize:Int {
    
    case font30 = 30, font28 = 28, font26 = 26, font24 = 24, font22 = 22, font20 = 20, font18 = 18, font17 = 17, font16 = 16, font15 = 15, font14 = 14, font13 = 13, font12 = 12, font8 = 8
    
    var value:Int {
        return self.rawValue
    }
    
}

enum TextColors:String {
    case tint, whiteText, backGround
    case darkText, grayText, redText, goldText, disabled
    case borderColor, primary, secondry, windowOver
    
    var value:UIColor {
        switch self {
        case .tint: return Theme.Colors.tint
        case .whiteText: return Theme.Colors.whiteText
        case .backGround: return Theme.Colors.backGround
        case .darkText: return Theme.Colors.darkText
        case .grayText: return Theme.Colors.grayText
        case .redText: return Theme.Colors.redText
        case .borderColor: return Theme.Colors.borderColor
        case .primary: return Theme.Colors.primary
        case .secondry: return Theme.Colors.secondry
        case .windowOver: return Theme.Colors.windowOver
        case .goldText: return Theme.Colors.goldText
        case .disabled: return Theme.Colors.disabled
        }
    }
    
    var raw:String {
        return self.rawValue
    }
}
