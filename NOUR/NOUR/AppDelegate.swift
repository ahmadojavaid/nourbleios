//
//  AppDelegate.swift
//  NOUR
//
//  Created by abbas on 6/1/20.
//  Copyright © 2020 abbas. All rights reserved.
//

import UIKit
import IQKeyboardManagerSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.toolbarTintColor = Theme.Colors.tint
        
        return true
    }

}

