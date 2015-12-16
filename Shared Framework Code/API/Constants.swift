//
//  Constants.swift
//  Nightscouter
//
//  Created by Peter Ina on 11/18/15.
//  Copyright © 2015 Peter Ina. All rights reserved.
//

import Foundation

public struct DefaultKey {
    public static let sitesArrayObjectsKey = "userSitesData"
    public static let currentSiteIndexKey = "currentSiteIndexInt"
    public static let shouldDisableIdleTimerKey = "shouldDisableIdleTimerBool"
    public static let modelArrayObjectsKey = "siteModelsArray"
}

public struct Constants {
    
    public struct StandardTimeFrame {
        public static let OneMinuteInSeconds: NSTimeInterval = 60
        public static let TwoAndHalfMinutesInSeconds: NSTimeInterval = OneMinuteInSeconds * 2.5
        public static let FiveMinutesInSeconds: NSTimeInterval = OneMinuteInSeconds * 5
        public static let TenMinutesInSeconds: NSTimeInterval = OneMinuteInSeconds * 10
        public static let ThirtyMinutesInSeconds: NSTimeInterval = OneMinuteInSeconds * 30
        public static let OneHourInSeconds: NSTimeInterval = OneMinuteInSeconds * 60
        public static let TwoHoursInSeconds: NSTimeInterval = OneMinuteInSeconds * 120
    }
    
    public struct NotableTime {
        public static let StaleDataTimeFrame = StandardTimeFrame.TenMinutesInSeconds
        public static let StandardRefreshTime = StandardTimeFrame.FiveMinutesInSeconds
    }
    
    public struct EntryCount {
        public static let NumberForChart = 100
        public static let NumberForComplication = 288
        public static let LowerLimitForValidSGV = 39
        public static let UpperLimitForValidSGV = 400
    }
    
}