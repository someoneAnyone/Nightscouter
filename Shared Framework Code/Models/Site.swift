//
//  Site.swift
//  Nightscouter
//
//  Created by Peter Ina on 6/25/15.
//  Copyright (c) 2015 Peter Ina. All rights reserved.
//
import Foundation

open class Site: NSObject, NSCoding, DictionaryConvertible {
    
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
    
    open var url: URL! {
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
    open var apiSecret: String? // set in keychain
    
    open var hasApiSecret: Bool {
        return (apiSecret?.isEmpty != nil)
    }
    
    open var configuration: ServerConfiguration? {
        didSet {
            lastConnectedDate = Date()
        }
    }
    open var watchEntry: WatchEntry?
    open var entries: [Entry]?
    open var allowNotifications: Bool
    open var overrideScreenLock: Bool
    
    open var complicationModels: [ComplicationModel] = []
    open var calibrations: [Calibration] = []
    
    open var disabled: Bool
    
    open fileprivate(set) var uuid: UUID
    open fileprivate(set) var lastConnectedDate: Date?
    

    open var updateNow: Bool {
        let now = Date()
        let result = nextRefreshDate.compare(now) == .orderedAscending || configuration == nil || lastConnectedDate == nil
         print("updateNow calulcation: \(nextRefreshDate).comare(\(now)) == .OrderedAscending), result:\(result)")
        return result
    }

    
    open var nextRefreshDate: Date {
        let date = lastConnectedDate?.addingTimeInterval(Constants.NotableTime.StandardRefreshTime) ?? Date().addingTimeInterval(-10)
        print("iOS nextRefreshDate: " + date.description)
        return date
    }
    
    open override var description: String {
        return dictionary.description
    }
    
    open var dictionaryRep: [String: AnyObject] {

        var dict = Dictionary<String, AnyObject>()
      
        dict["urlString"] = url.absoluteString as AnyObject?
        
        if let configuration = configuration {
            dict["displayName"] = configuration.displayName as AnyObject?
        }
        
        return dict
    }
    
    open var viewModel: WatchModel {
        return WatchModel(fromSite: self)
    }
   
    // MARK: Initialization
    public init?(url: URL, apiSecret: String?, uuid: UUID = UUID()) {
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
    open func encode(with aCoder: NSCoder) {
        aCoder.encode(url, forKey: PropertyKey.urlKey)
        aCoder.encode(apiSecret, forKey: PropertyKey.apiSecretKey)
        aCoder.encode(allowNotifications, forKey: PropertyKey.allowNotificationsKey)
        aCoder.encode(uuid.uuidString, forKey: PropertyKey.uuidKey)
        aCoder.encode(overrideScreenLock, forKey: PropertyKey.overrideScreenLockKey)
        aCoder.encode(disabled, forKey: PropertyKey.disabledKey)
        aCoder.encode(lastConnectedDate, forKey: PropertyKey.lastConnectedDateKey)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        let url = aDecoder.decodeObject(forKey: PropertyKey.urlKey) as! URL
        let apiSecret = aDecoder.decodeObject(forKey: PropertyKey.apiSecretKey) as? String
        let allowNotif = aDecoder.decodeBool(forKey: PropertyKey.allowNotificationsKey)
        let overrideScreen = aDecoder.decodeBool(forKey: PropertyKey.overrideScreenLockKey)
        let disabledSite = aDecoder.decodeBool(forKey: PropertyKey.disabledKey)
        let lastConnectedDate = aDecoder.decodeObject(forKey: PropertyKey.lastConnectedDateKey) as? Date
        
        if let uuidString = aDecoder.decodeObject(forKey: PropertyKey.uuidKey) as? String {
            self.uuid = UUID(uuidString: uuidString)!
        } else {
            self.uuid = UUID()
        }
        
        self.url = url
        self.apiSecret = apiSecret
        self.allowNotifications =  allowNotif
        self.overrideScreenLock = overrideScreen
        self.lastConnectedDate = lastConnectedDate

        self.disabled = disabledSite
    }
    
    open override func isEqual(_ object: Any?) -> Bool {
        if let object = object as? Site {
            return uuid == object.uuid
        } else {
            return false
        }
    }
}

extension Site {
    public convenience init?(dictionary: [String: AnyObject]) {

        guard let url = dictionary["url"] as? URL else {
            return nil
        }
        
        let api = dictionary["apiapiSecret"] as? String

        self.init(url: url, apiSecret: api)
        
        if let uuidString = dictionary["uuid"] as? String, let uuid = UUID(uuidString: uuidString) {
            self.uuid = uuid
        }
    }
}
