//
//  AppConfiguration.swift
//  Nightscouter
//
//  Created by Peter Ina on 1/11/16.
//  Copyright © 2016 Nothingonline. All rights reserved.
//

import Foundation


public extension Notification.Name {
    static public let NightscoutDataUpdatedNotification = Notification.Name("com.nothingonline.nightscouter.data.updated")
    static public let NightscoutDataStaleNotification = Notification.Name("com.nothingonline.nightscouter.data.stale")

}

public typealias ArrayOfDictionaries = [[String: AnyObject]]


// TODO: Locallize these strings and move them to centeral location so all view can have consistent placeholder text.
public struct PlaceHolderStrings {
    public static let displayName: String = "----"
    public static let urlName: String = "- --- ---"
    public static let sgv: String = "---"
    public static let date: String = "----"
    public static let delta: String = "- --/--"
    public static let deltaAltJ: String = "∆"
    public static let raw: String = "---"
    public static let battery: String = "--%"
    public static let appName: String = LocalizedString.nightscoutTitleString.localized
    public static let defaultColor: DesiredColorState = .notSet
}


public struct LinkBuilder {
    public enum LinkType: String {
        case link = "link"
    }
    
    public static var supportedSchemes: [String]? {
        if let info = Bundle.main.infoDictionary {
            var schemes = [String]() // Create an empty array we can later set append available schemes.
            if let bundleURLTypes = info["CFBundleURLTypes"] as? [AnyObject] {
                for (index, _) in bundleURLTypes.enumerated() {
                    if let urlTypeDictionary = bundleURLTypes[index] as? [String : AnyObject] {
                        if let urlScheme = urlTypeDictionary["CFBundleURLSchemes"] as? [String] {
                            schemes += urlScheme // We've found the supported schemes appending to the array.
                            return schemes
                        }
                    }
                }
            }
        }
        
        return nil
    }
    
    public static func buildLink(forType type: LinkType = .link, withViewController viewController: StoryboardIdentifier) -> URL {
        
        // should probably do somethning with the supportedSchemes here...
        return URL(string: "nightscouter://\(type.rawValue)/\(viewController.rawValue)")!
    }
}


/// These match what is in the info plist. Do not change without updating.
public enum CommonUseCasesForShortcuts: String {
    case ShowDetail, AddNew, AddNewWhenEmpty, ShowList
    
    public init?(shortcutItemString: String){
        
        let newString = shortcutItemString.components(separatedBy: ".")

        
        self = CommonUseCasesForShortcuts(rawValue: newString.last!)!
    }
    
    public func linkForUseCase() -> URL {
        switch self {
        case .ShowDetail: return LinkBuilder.buildLink(forType: .link, withViewController: .siteListPageViewController)
        case .ShowList: return LinkBuilder.buildLink(forType: .link, withViewController: .sitesTableViewController)
        case .AddNewWhenEmpty: return LinkBuilder.buildLink(forType: .link, withViewController: .formViewController)
        case .AddNew: return LinkBuilder.buildLink(forType: .link, withViewController: .formViewNavigationController)
        }
    }

    public var applicationShortcutItemType: String {
        return AppConfiguration.applicationName + "." + self.rawValue
    }
}

public enum StoryboardIdentifier: String, RawRepresentable {
    case formViewController, formViewNavigationController, sitesTableViewController, siteListPageViewController, siteDetailViewController, siteSettingsNavigationViewController
    public static let allValues = [formViewController, formViewNavigationController, sitesTableViewController, siteListPageViewController, siteDetailViewController, siteSettingsNavigationViewController]
    public static let deepLinkable = [formViewNavigationController, formViewController, siteListPageViewController, sitesTableViewController]
}

public class AppConfiguration {
    // MARK: Types
    
    public static let applicationName = "com.nothingonline.nightscouter"
    public static let sharedApplicationGroupSuiteName: String = "group.com.nothingonline.nightscouter"

//    public static var keychain: Keychain {
//        return Keychain(service: applicationName).synchronizable(true)
//    }
    
    private struct Defaults {
        static let firstLaunchKey = "AppConfiguration.Defaults.firstLaunchKey"
        static let storageOptionKey = "AppConfiguration.Defaults.storageOptionKey"
        static let storedUbiquityIdentityToken = "AppConfiguration.Defaults.storedUbiquityIdentityToken"
    }
    
    public struct Constant {
        public static let knownMilliseconds: Mills = 1268197200000
        public static let knownMgdl: MgdlValue = 100
    }
    
    /**
     Formatter used to display the date and time that data was last updated.
     Example output:
     ```
     Jan 12, 2007, 11:11:46 AM
     ```
     */
    public static let lastUpdatedDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .medium
        dateFormatter.dateStyle = .medium
        dateFormatter.timeZone = NSTimeZone.local
        return dateFormatter
    }()
    
    public static let lastUpdatedFromPhoneDateFormatter: DateFormatter = {
        // Create and use a formatter.
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .short
        dateFormatter.dateStyle = .short
        dateFormatter.timeZone = NSTimeZone.local
        
        return dateFormatter
    }()
    
    
    public static let serverTimeDateFormatter: DateFormatter = {
        // Sample String: "2016-01-13T15:31:11.023Z"
     //"2015-07-12T02:46:37.878Z"
        
        let formatString = "yyyy-MM-dd'T'HH:mm:Ss.sss'Z'"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = formatString
        return dateFormatter
    }()
 
    public static let serverDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        return formatter
    }()
}
