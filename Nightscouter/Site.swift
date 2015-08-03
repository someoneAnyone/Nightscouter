//
//  Site.swift
//  Nightscouter
//
//  Created by Peter Ina on 6/25/15.
//  Copyright (c) 2015 Peter Ina. All rights reserved.
//
import Foundation
import UIKit

class Site: NSObject, NSCoding {
    
    struct PropertyKey {
        static let urlKey = "url"
        static let apiSecretKey = "apiSecret"
        static let siteKey = "site"
        static let allowNotificationsKey = "notifications"
        static let uuidKey = "uuid"
        static let notificationKey = "notification"
        static let notificationCountKey = "notificationCount"
        static let overrideScreenLockKey = "overrideScreenLock"
        static let disabledKey = "disabled"
        
        static let sitesKey = "sites.plist"

    }
    
    // MARK: Archiving Paths
    static let DocumentsDirectory: AnyObject = NSFileManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.URLByAppendingPathComponent(PropertyKey.sitesKey)
    
    var url: NSURL! {
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
    var apiSecret: String?
    var configuration: ServerConfiguration?
    var watchEntry: WatchEntry?
    var entries: [Entry]?
    var allowNotifications: Bool = true // Fix this at somepoint.
    var overrideScreenLock: Bool

    var notifications: [UILocalNotification]
    var disabled: Bool
    
    private(set) var uuid: NSUUID
    
    // MARK: Initialization
    init?(url: NSURL, apiSecret: String?) {
        // Initialize stored properties.
        self.url = url
        self.apiSecret = apiSecret
        
        self.uuid = NSUUID()
        self.notifications = [UILocalNotification]()
        self.overrideScreenLock = false
        self.disabled = false
        
        super.init()
        
        // Initialization should fail if there is no name.
        if url.absoluteString!.isEmpty {
            return nil
        }
    }
    
    // MARK: NSCoding
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(url, forKey: PropertyKey.urlKey)
        aCoder.encodeObject(apiSecret, forKey: PropertyKey.apiSecretKey)
        aCoder.encodeBool(allowNotifications, forKey: PropertyKey.allowNotificationsKey)
        aCoder.encodeObject(uuid, forKey: PropertyKey.uuidKey)
        aCoder.encodeObject(notifications, forKey: PropertyKey.notificationKey)
        aCoder.encodeBool(overrideScreenLock, forKey: PropertyKey.overrideScreenLockKey)
        aCoder.encodeBool(disabled, forKey: PropertyKey.disabledKey)
    }

    required init(coder aDecoder: NSCoder) {
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
}
