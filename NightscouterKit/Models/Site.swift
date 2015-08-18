//
//  Site.swift
//  Nightscouter
//
//  Created by Peter Ina on 6/25/15.
//  Copyright (c) 2015 Peter Ina. All rights reserved.
//
import Foundation
import UIKit

public class Site: NSObject, NSCoding {
    
    public struct PropertyKey {
        static let urlKey = "url"
        static let apiSecretKey = "apiSecret"
        static let siteKey = "site"
        static let allowNotificationsKey = "notifications"
        public static let uuidKey = "uuid"
        static let notificationKey = "notification"
        static let notificationCountKey = "notificationCount"
        static let overrideScreenLockKey = "overrideScreenLock"
        static let disabledKey = "disabled"
        
        static let sitesPlistKey = "sites.plist"

    }
    
    // MARK: Archiving Paths
//    static let DocumentsDirectory: AnyObject = NSFileManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
//    static let ArchiveURL = DocumentsDirectory.URLByAppendingPathComponent(PropertyKey.sitesKey)
    
    public var url: NSURL! {
        didSet {
            #if DEBUG
                println("Changed site URL to \(url) from \(oldValue)")
            #endif
            
            configuration = nil
            watchEntry = nil
            entries = nil
            disabled = false
        }
    }
    public var apiSecret: String?
    public var configuration: ServerConfiguration?
    public var watchEntry: WatchEntry?
    public var entries: [Entry]?
    public var allowNotifications: Bool
    public var overrideScreenLock: Bool

    public var notifications: [UILocalNotification]
    public var disabled: Bool
    
    public private(set) var uuid: NSUUID
    
    // MARK: Initialization
    public init?(url: NSURL, apiSecret: String?) {
        // Initialize stored properties.
        self.url = url
        self.apiSecret = apiSecret
        
        self.uuid = NSUUID()
        self.notifications = [UILocalNotification]()
        self.overrideScreenLock = false
        self.disabled = false
        self.allowNotifications = true
        
        super.init()
        
        // Initialization should fail if there is no name.
        if url.absoluteString!.isEmpty {
            return nil
        }
    }
    
    // MARK: NSCoding
    public func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(url, forKey: PropertyKey.urlKey)
        aCoder.encodeObject(apiSecret, forKey: PropertyKey.apiSecretKey)
        aCoder.encodeBool(allowNotifications, forKey: PropertyKey.allowNotificationsKey)
        aCoder.encodeObject(uuid, forKey: PropertyKey.uuidKey)
        aCoder.encodeObject(notifications, forKey: PropertyKey.notificationKey)
        aCoder.encodeBool(overrideScreenLock, forKey: PropertyKey.overrideScreenLockKey)
        aCoder.encodeBool(disabled, forKey: PropertyKey.disabledKey)
    }

    required public init(coder aDecoder: NSCoder) {
        let url = aDecoder.decodeObjectForKey(PropertyKey.urlKey) as! NSURL
        let apiSecret = aDecoder.decodeObjectForKey(PropertyKey.apiSecretKey) as? String
        let allowNotif = aDecoder.decodeBoolForKey(PropertyKey.allowNotificationsKey)
        let overrideScreen = aDecoder.decodeBoolForKey(PropertyKey.overrideScreenLockKey)
        let disabledSite = aDecoder.decodeBoolForKey(PropertyKey.disabledKey)
        
        if let uuid = aDecoder.decodeObjectForKey(PropertyKey.uuidKey) as? NSUUID {
            self.uuid = uuid
        } else {
            self.uuid = NSUUID()
        }
        
        self.url = url
        self.apiSecret = apiSecret
        self.allowNotifications =  allowNotif
        self.overrideScreenLock = overrideScreen
        
        if let notification = aDecoder.decodeObjectForKey(PropertyKey.notificationKey) as? [UILocalNotification] {
            self.notifications = notification
        } else {
            self.notifications = [UILocalNotification]()
        }
        
        self.disabled = disabledSite
    }
    
    public override func isEqual(object: AnyObject?) -> Bool {
        if let object = object as? Site {
            return uuid == object.uuid
        } else {
            return false
        }
    }
}