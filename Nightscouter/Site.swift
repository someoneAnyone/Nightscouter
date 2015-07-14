//
//  Site.swift
//  Nightscouter
//
//  Created by Peter Ina on 6/25/15.
//  Copyright (c) 2015 Peter Ina. All rights reserved.
//

import UIKit

class Site: NSObject, NSCoding {
    
    struct PropertyKey {
        static let urlKey = "url"
        static let apiSecretKey = "apiSecret"
        static let siteKey = "site"
        static let allowNotificationsKey = "notifications"
    }
    
    var url: NSURL
    var apiSecret: String?
    var configuration: ServerConfiguration?
    var watchEntry: WatchEntry?
    var entries: [Entry]?
    
    var allowNotifications: Bool = false
    
    var uuid: Int! {
        get {
            return self.hash
        }
    }
    // MARK: Archiving Paths
    static let DocumentsDirectory: AnyObject = NSFileManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.URLByAppendingPathComponent(PropertyKey.siteKey)
    
    // MARK: Initialization
    init?(url: NSURL, apiSecret: String?) {
        // Initialize stored properties.
        self.url = url
        self.apiSecret = apiSecret
        
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
    }
    
    /*
    convenience required init(coder aDecoder: NSCoder) {
        let url = aDecoder.decodeObjectForKey(PropertyKey.urlKey) as! NSURL
        let apiSecretKey = aDecoder.decodeObjectForKey(PropertyKey.apiSecretKey) as? String
        
        self.init(url: url, apiSecret: apiSecret)
    }
    */
    
    required init(coder aDecoder: NSCoder) {
        let url = aDecoder.decodeObjectForKey(PropertyKey.urlKey) as! NSURL
        let apiSecret = aDecoder.decodeObjectForKey(PropertyKey.apiSecretKey) as? String
        let allowNotif = aDecoder.decodeBoolForKey(PropertyKey.allowNotificationsKey)
        self.url = url
        self.apiSecret = apiSecret
        self.allowNotifications =  allowNotif
    }
    
}