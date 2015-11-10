//
//  ExtensionDelegate.swift
//  NightscouterNow Extension
//
//  Created by Peter Ina on 10/4/15.
//  Copyright © 2015 Peter Ina. All rights reserved.
//

import WatchKit
import NightscouterWatchOSKit

class ExtensionDelegate: NSObject, WKExtensionDelegate {
    
    func applicationDidFinishLaunching() {
        // Perform any final initialization of your application.
        WatchSessionManager.sharedManager.startSession()
    }
    
    func applicationDidBecomeActive() {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillResignActive() {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, etc.
    }
}

public func colorForDesiredColorState(desiredState: DesiredColorState) -> UIColor {
    switch (desiredState) {
    case .Neutral:
        return NSAssetKitWatchOS.predefinedNeutralColor
    case .Alert:
        return NSAssetKitWatchOS.predefinedAlertColor
    case .Positive:
        return NSAssetKitWatchOS.predefinedPostiveColor
    case .Warning:
        return NSAssetKitWatchOS.predefinedWarningColor
    }
}