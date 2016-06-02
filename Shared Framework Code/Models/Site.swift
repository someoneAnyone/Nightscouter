//
//  Site.swift
//  Nightscouter
//
//  Created by Peter Ina on 6/25/15.
//  Copyright (c) 2015 Peter Ina. All rights reserved.
//
import Foundation

public class Site: NSObject, NSCoding, DictionaryConvertible {
    
    public struct PropertyKey {
        static let urlKey = "url"
        static let apiSecretKey = "apiSecret"
        static let siteKey = "site"
        static let allowNotificationsKey = "notifications"
        static let overrideScreenLockKey = "overrideScreenLock"
        static let disabledKey = "disabled"
        static let lastConnectedDateKey = "lastConnectedDate"
        
        static let sitesPlistKey = "sites.plist"
        public static let uuidKey = "uuid"
    }
    
    public var url: NSURL! {
        didSet {
            #if DEBUG
                print("Changed site URL to \(url) from \(oldValue)")
            #endif
            
            configuration = nil
            watchEntry = nil
            entries = nil
            disabled = false
        }
    }
    public var apiSecret: String? // set in keychain
    
    public var hasApiSecret: Bool {
        return (apiSecret?.isEmpty != nil)
    }
    
    public var configuration: ServerConfiguration? {
        didSet {
            lastConnectedDate = NSDate()
        }
    }
    public var watchEntry: WatchEntry?
    public var entries: [Entry]?
    public var allowNotifications: Bool
    public var overrideScreenLock: Bool
    
    public var complicationModels: [ComplicationModel] = []
    public var calibrations: [Calibration] = []
    
    public var disabled: Bool
    
    public private(set) var uuid: NSUUID
    public private(set) var lastConnectedDate: NSDate?
    
    public var nextRefreshDate: NSDate {
        let date = lastConnectedDate?.dateByAddingTimeInterval(Constants.NotableTime.StandardRefreshTime) ?? NSDate().dateByAddingTimeInterval(-10)
        print("iOS nextRefreshDate: " + date.description)
        return date
    }
    
    public var updateNow: Bool {
        return self.lastConnectedDate?.compare(self.nextRefreshDate) == .OrderedDescending
    }
    
    public override var description: String {
        return dictionary.description
    }
    
    public var dictionaryRep: [String: AnyObject] {

        var dict = Dictionary<String, AnyObject>()
      
        dict["urlString"] = url.absoluteString
        
        if let configuration = configuration {
            dict["displayName"] = configuration.displayName
        }
        
        return dict
    }
    
    public var viewModel: WatchModel {
        return WatchModel(fromSite: self)
    }
   
    // MARK: Initialization
    public init?(url: NSURL, apiSecret: String?, uuid: NSUUID = NSUUID()) {
        // Initialize stored properties.
        self.url = url
        self.apiSecret = apiSecret
        
        self.uuid = uuid
        self.overrideScreenLock = false
        self.disabled = false
        self.allowNotifications = true
        
        super.init()
        
        // Initialization should fail if there is no name.
        if url.absoluteString.isEmpty {
            return nil
        }
    }

    
    // MARK: NSCoding
    public func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(url, forKey: PropertyKey.urlKey)
        aCoder.encodeObject(apiSecret, forKey: PropertyKey.apiSecretKey)
        aCoder.encodeBool(allowNotifications, forKey: PropertyKey.allowNotificationsKey)
        aCoder.encodeObject(uuid.UUIDString, forKey: PropertyKey.uuidKey)
        aCoder.encodeBool(overrideScreenLock, forKey: PropertyKey.overrideScreenLockKey)
        aCoder.encodeBool(disabled, forKey: PropertyKey.disabledKey)
        aCoder.encodeObject(lastConnectedDate, forKey: PropertyKey.lastConnectedDateKey)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        let url = aDecoder.decodeObjectForKey(PropertyKey.urlKey) as! NSURL
        let apiSecret = aDecoder.decodeObjectForKey(PropertyKey.apiSecretKey) as? String
        let allowNotif = aDecoder.decodeBoolForKey(PropertyKey.allowNotificationsKey)
        let overrideScreen = aDecoder.decodeBoolForKey(PropertyKey.overrideScreenLockKey)
        let disabledSite = aDecoder.decodeBoolForKey(PropertyKey.disabledKey)
        let lastConnectedDate = aDecoder.decodeObjectForKey(PropertyKey.lastConnectedDateKey) as? NSDate
        
        if let uuidString = aDecoder.decodeObjectForKey(PropertyKey.uuidKey) as? String {
            self.uuid = NSUUID(UUIDString: uuidString)!
        } else {
            self.uuid = NSUUID()
        }
        
        self.url = url
        self.apiSecret = apiSecret
        self.allowNotifications =  allowNotif
        self.overrideScreenLock = overrideScreen
        self.lastConnectedDate = lastConnectedDate

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

extension Site {
    public convenience init?(dictionary: [String: AnyObject]) {

        guard let url = dictionary["url"] as? NSURL else {
            return nil
        }
        
        let api = dictionary["apiapiSecret"] as? String

        self.init(url: url, apiSecret: api)
        
        if let uuidString = dictionary["uuid"] as? String, uuid = NSUUID(UUIDString: uuidString) {
            self.uuid = uuid
        }
    }
}