//
//  AppTheme.swift
//  Nightscouter
//
//  Created by Peter Ina on 8/4/15.
//  Copyright (c) 2015 Peter Ina. All rights reserved.
//

import UIKit

public struct Theme {
    public struct Color {
        public static let windowTintColor =  NSAssetKit.predefinedNeutralColor
        public static let headerTextColor = UIColor(white: 1.0, alpha: 0.5)
        public static let labelTextColor = UIColor.whiteColor()
        public static let navBarColor: UIColor = NSAssetKit.darkNavColor
        public static let navBarTextColor: UIColor = UIColor.whiteColor()
    }
    
    public struct Font {
        static let navBarTitleFont = UIFont(name: "HelveticaNeue-Thin", size: 20.0)
    }
}

public class AppThemeManager: NSObject {
    public class var themeApp: AppThemeManager {
        struct Static {
            static var onceToken: dispatch_once_t = 0
            static var instance: AppThemeManager? = nil
        }
        dispatch_once(&Static.onceToken) {
            Static.instance = AppThemeManager()
        }
        return Static.instance!
    }
    
    override init() {
        // UIApplication.sharedApplication().keyWindow?.tintColor = Theme.Color.windowTintColor
        // UIWindow.appearance().tintColor = UIColor.redColor()
        // window?.tintColor = NSAssetKit.predefinedNeutralColor

        UINavigationBar.appearance().tintColor = Theme.Color.windowTintColor
        // Change the font and size of nav bar text.
        if let navBarFont = Theme.Font.navBarTitleFont {
            
            let navBarColor: UIColor = Theme.Color.navBarColor
            UINavigationBar.appearance().barTintColor = navBarColor
            
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName: Theme.Color.navBarTextColor,
                NSFontAttributeName: navBarFont
            ]
            
            UINavigationBar.appearance().titleTextAttributes = navBarAttributesDictionary
        }

        super.init()
    
    }

}