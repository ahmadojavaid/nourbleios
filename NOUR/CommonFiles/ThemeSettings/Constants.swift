//
//  Constants.swift
//  Movies
//
//  Created by Zuhair on 2/17/19.
//  Copyright © 2019 Zuhair Hussain. All rights reserved.
//

import UIKit

struct Constants {
    
    static let baseURL = "https://dev2.polse.jobesk.com" //UserLogin().baseURL
    
    static let appFont = "FiraSans"
    
    static var statusBarHeight: CGFloat {
        return UIApplication.shared.statusBarFrame.height
    }
    
    static var safeArea: UIEdgeInsets {
        return UIApplication.shared.keyWindow?.safeAreaInsets ?? UIEdgeInsets.zero
    }
    
}

