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
        static let OneHourInSeconds: NSTimeInterval = OneMinuteInSeconds * 60
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
    
    struct LocalizedString {
        static let tableViewCellRemove = "tableViewCellRemove"
        static let tableViewCellLoading = "tableViewCellLoading"
        static let localNotificationMessage = "localNotificationMessage" // not implemented.
        static let localNotificationAlertButton = "localNotificationAlertButton" // not implemented.
        static let batteryLabel = "batteryLabel" // not implemented.
        static let rawLabel = "rawLabel" // not implemented.
        static let lastUpdatedDateLabel = "lastUpdatedDateLabel"
        static let lastReadingLabel = "lastReadingLabel" // not implemented.
    }
}

extension String {
    var localized: String {
        return NSLocalizedString(self, tableName: nil, bundle: NSBundle.mainBundle(), value: "", comment: "")
    }
    func localizedWithComment(comment:String) -> String {
        return NSLocalizedString(self, tableName: nil, bundle: NSBundle.mainBundle(), value: "", comment: comment)
    }
}