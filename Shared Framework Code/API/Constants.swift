//
//  Constants.swift
//  Nightscouter
//
//  Created by Peter Ina on 11/18/15.
//  Copyright © 2015 Peter Ina. All rights reserved.
//

import Foundation

public let AppDataManagerDidChangeNotification: String = "com.nothingonline.nightscouter.appDataManager.DidChange.Notification"

/*
public struct DefaultKey {
    public static let sitesArrayObjectsKey = "userSitesData"
    public static let currentSiteIndexKey = "currentSiteIndexInt"
    public static let modelArrayObjectsKey = "siteModelArray"
    public static let defaultSiteKey = "defaultSiteKey"
    
    public static let calibrations = "calibrations"
    public static let complicationModels = "complicationModels"
    public static let complicationLastUpdateStartDate = "lastUpdateStartDate"
    public static let complicationLastUpdateDidChangeComplicationDate = "lastUpdateDidChangeDate"
    public static let complicationNextRequestedStartDate = "nextRequestedStartDate"
    public static let complicationRequestedUpdateBudgetExhaustedDate = "requestedUpdateBudgetExhaustedDate"
    public static let complicationUpdateEndedOnDate = "complicationUpdateEndedOnDate"
    
    public static let osPlatform = "osPlatform"
}
 */

public enum DefaultKey: String, RawRepresentable, CustomStringConvertible {
    case sites, lastViewedSiteIndex, primarySiteUUID, lastDataUpdateDateFromPhone, updateData, action, error, osPlatform, siteURLForWatch

    static var payloadPhoneUpdate: [String : String] {
        return [DefaultKey.action.rawValue: DefaultKey.updateData.rawValue]
    }
    
    static var payloadPhoneUpdateError: [String : String] {
        return [DefaultKey.action.rawValue: DefaultKey.error.rawValue]
    }
    
    public var description: String {
        return self.rawValue
    }
}


public struct Constants {
    
    public struct StandardTimeFrame {
        public static let OneMinuteInSeconds: TimeInterval = 60.0
        public static let TwoAndHalfMinutesInSeconds: TimeInterval = OneMinuteInSeconds * 2.5
        public static let FourMinutesInSeconds: TimeInterval = OneMinuteInSeconds * 4
        public static let TenMinutesInSeconds: TimeInterval = OneMinuteInSeconds * 10
        public static let ThirtyMinutesInSeconds: TimeInterval = OneMinuteInSeconds * 30
        public static let OneHourInSeconds: TimeInterval = OneMinuteInSeconds * 60
        public static let TwoHoursInSeconds: TimeInterval = OneMinuteInSeconds * 120
    }
    
    public struct NotableTime {
        public static let StaleDataTimeFrame = StandardTimeFrame.TenMinutesInSeconds
        public static let StandardRefreshTime = StandardTimeFrame.FourMinutesInSeconds
    }
    
    public struct EntryCount {
        public static let NumberForChart = 100
        public static let NumberForComplication = 288
        public static let LowerLimitForValidSGV = 39
        public static let UpperLimitForValidSGV = 400
    }
    
}
