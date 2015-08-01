//
//  Enums.swift
//  Nightscouter
//
//  Created by Peter Ina on 6/16/15.
//  Copyright © 2015 Peter Ina. All rights reserved.
//
import Foundation

struct Constants {
    struct CellIdentifiers {
        static let SiteTableViewStyle = "siteCell"
    }
    
    struct StandardTimeFrame {
        static let OneMinuteInSeconds: NSTimeInterval = 60
        static let FiveMinutesInSeconds: NSTimeInterval = OneMinuteInSeconds * 5
        static let TenMinutesInSeconds: NSTimeInterval = OneMinuteInSeconds * 10
        static let ThirtyMinutesInSeconds: NSTimeInterval = OneMinuteInSeconds * 30
        static let OneHourInSeconds: NSTimeInterval = OneMinuteInSeconds * 60
        static let TwoHoursInSeconds: NSTimeInterval = OneMinuteInSeconds * 120
    }
    
    struct NotableTime {
        static let StaleDataTimeFrame = StandardTimeFrame.TenMinutesInSeconds
        static let StandardRefreshTime = StandardTimeFrame.FiveMinutesInSeconds
    }
    
    struct EntryCount {
        static let NumberForChart = 100
        static let LowerLimitForValidSGV = 39
        static let UpperLimitForValidSGV = 400
    }
    
    struct Notification {
        static let DataIsStaleUpdateNow = "com.nothingonline.nightscouter.data.stale.update"
    }
    
    struct ActivityType {
        static let sites = AppDataManager.sharedInstance.bundleIdentifier?.stringByAppendingPathExtension("sites")
        static let site = AppDataManager.sharedInstance.bundleIdentifier?.stringByAppendingPathExtension("site")
        static let new = AppDataManager.sharedInstance.bundleIdentifier?.stringByAppendingPathExtension("new")
    }

    struct ActivityKey {
        static let ActivitySitesKey = "nightscouter.sites.key"
        static let ActivitySiteKey  = "nightscouter.site.key"
    }
//    let ActivityVersionKey = "shopsnap.version.key"
//    let ActivityVersionValue = "1.0"

    
    struct LocalizedString {
        static let tableViewCellRemove = "tableViewCellRemove"
        static let tableViewCellLoading = "tableViewCellLoading"
//        static let localNotificationMessage = "localNotificationMessage" // not implemented.
//        static let localNotificationAlertButton = "localNotificationAlertButton" // not implemented.
//        static let batteryLabel = "batteryLabel" // not implemented.
//        static let rawLabel = "rawLabel" // not implemented.
        static let lastUpdatedDateLabel = "lastUpdatedDateLabel"
//        static let lastReadingLabel = "lastReadingLabel" // not implemented.
        static let generalEditLabel = "generalEditLabel"
        static let generalCancelLabel = "generalCancelLabel"
        static let generalRetryLabel = "generalRetryLabel"
        static let generalYesLabel = "generalYesLabel"
        static let generalNoLabel = "generalNoLabel"
        static let uiAlertBadSiteMessage = "uiAlertBadSiteMessage"
        static let uiAlertBadSiteTitle = "uiAlertBadSiteTitle"
        static let uiAlertScreenOverrideTitle = "uiAlertScreenOverrideTitle"
        static let uiAlertScreenOverrideMessage = "uiAlertScreenOverrideMessage"
        
        static let sgvLowString = "sgvLowString"
    }
}