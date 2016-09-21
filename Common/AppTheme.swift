//
//  AppTheme.swift
//  Nightscouter
//
//  Created by Peter Ina on 8/4/15.
//  Copyright (c) 2015 Peter Ina. All rights reserved.
//

import UIKit

public struct Theme {
    public struct AppColor {
        public static let windowTintColor = Color(red: 0.851, green: 0.851, blue: 0.851, alpha: 1.000)// NightscouterAssetKit.predefinedNeutralColor
        public static let headerTextColor = Color.white.withAlphaComponent(0.5)
        public static let labelTextColor = Color.white
        public static let navBarColor: Color = Color(red: 0.000, green: 0.451, blue: 0.812, alpha: 1.000)
//NightscouterAssetKit.darkNavColor
        public static let navBarTextColor: Color = Color.white
    }
    
    public struct Font {
        public static let navBarTitleFont = UIFont(name: "HelveticaNeue-Thin", size: 20.0)
    }
    
    public static func customizeAppAppearance(sharedApplication application:UIApplication, forWindow window: UIWindow?) {
        application.statusBarStyle = .lightContent
        // Change the font and size of nav bar text.
        window?.tintColor = Theme.AppColor.windowTintColor
        
        if let navBarFont = Theme.Font.navBarTitleFont {
            
            let navBarColor: UIColor = Theme.AppColor.navBarColor
            UINavigationBar.appearance().barTintColor = navBarColor
            UINavigationBar.appearance().tintColor = Theme.AppColor.windowTintColor
            
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName: Theme.AppColor.navBarTextColor,
                NSFontAttributeName: navBarFont
            ]
            
            UINavigationBar.appearance().titleTextAttributes = navBarAttributesDictionary
        }
    }
}
