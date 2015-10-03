//
//  Enums.swift
//  Nightscouter
//
//  Created by Peter Ina on 6/16/15.
//  Copyright © 2015 Peter Ina. All rights reserved.
//
import Foundation

public struct Constants {
    
    public enum StoryboardName: String, CustomStringConvertible {
        case LaunchScreen = "LaunchScreen"
        case Main = "Main"
        case Labs = "Labs"
        
        public var description: String {
            return self.rawValue
        }
    }
    
    public enum SegueIdentifier: String, CustomStringConvertible {
        case EditSite = "EditSite"
        case ShowDetail = "ShowDetail"
        case AddNew = "AddNew"
        case AddNewWhenEmpty = "AddNewWhenEmpty"
        case LaunchLabs = "LaunchLabs"
        case ShowPageView = "ShowPageView"
        case UnwindToSiteList = "unwindToSiteList"
        
        public var description: String {
            return self.rawValue
        }
    }
    
    public enum StoryboardViewControllerIdentifier: String, CustomStringConvertible {
        case SiteListTableNavigationController = "SiteListTableNavigationController"
        case SiteListTableViewController = "SiteListTableViewController"
        case SiteListPageViewController = "SiteListPageViewController"
        case SiteDetailViewController = "SiteDetailViewController"
        case SiteFormViewNavigationController = "SiteFormViewNavigationController"
        case SiteFormViewController = "SiteFormViewController"
        
        public static let deepLinkableStoryboards = [SiteListTableViewController, SiteListPageViewController, SiteFormViewController]
        
        public var description: String {
            return self.rawValue
        }
    }
    
    public struct CellIdentifiers {
        public static let SiteTableViewStyle = "siteCell"
    }
    
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
        public static let LowerLimitForValidSGV = 39
        public static let UpperLimitForValidSGV = 400
    }
    
    public struct Notification {
        public static let DataIsStaleUpdateNow: String =  AppDataManager.sharedInstance.bundleIdentifier!.URLByAppendingPathExtension("data.stale.update").absoluteString
        public static let DataUpdateSuccessful = AppDataManager.sharedInstance.bundleIdentifier!.URLByAppendingPathExtension("data.update.successful").absoluteString
        // public static let DataUpdateFail = AppDataManager.sharedInstance.bundleIdentifier!.stringByAppendingString("data.update.fail")
    }
    
    public struct ActivityType {
        public static let sites = AppDataManager.sharedInstance.bundleIdentifier!.URLByAppendingPathExtension("sites")
        public static let site = AppDataManager.sharedInstance.bundleIdentifier!.URLByAppendingPathExtension("site")
        public static let new = AppDataManager.sharedInstance.bundleIdentifier!.URLByAppendingPathExtension("new")
    }

   public struct ActivityKey {
        public static let SitesKey = "nightscouter.sites.key"
        public static let SiteKey  = "nightscouter.site.key"
        public static let VesionValue = "1.0"
    }

    public struct LocalizedString {
        public static let tableViewCellRemove = "tableViewCellRemove"
        public static let tableViewCellLoading = "tableViewCellLoading"
        public static let lastUpdatedDateLabel = "lastUpdatedDateLabel"
        public static let generalEditLabel = "generalEditLabel"
        public static let generalCancelLabel = "generalCancelLabel"
        public static let generalRetryLabel = "generalRetryLabel"
        public static let generalYesLabel = "generalYesLabel"
        public static let generalNoLabel = "generalNoLabel"
        public static let uiAlertBadSiteMessage = "uiAlertBadSiteMessage"
        public static let uiAlertBadSiteTitle = "uiAlertBadSiteTitle"
        public static let uiAlertScreenOverrideTitle = "uiAlertScreenOverrideTitle"
        public static let uiAlertScreenOverrideMessage = "uiAlertScreenOverrideMessage"
        public static let sgvLowString = "sgvLowString"
        
        // static let localNotificationMessage = "localNotificationMessage" // not implemented.
        // static let localNotificationAlertButton = "localNotificationAlertButton" // not implemented.
        // static let batteryLabel = "batteryLabel" // not implemented.
        // static let rawLabel = "rawLabel" // not implemented.
        
        // static let lastReadingLabel = "lastReadingLabel" // not implemented.
    }
}