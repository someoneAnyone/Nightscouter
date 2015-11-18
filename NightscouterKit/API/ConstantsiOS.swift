//
//  Enums.swift
//  Nightscouter
//
//  Created by Peter Ina on 6/16/15.
//  Copyright © 2015 Peter Ina. All rights reserved.
//
import Foundation

extension Constants {
    
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