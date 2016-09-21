//
//  iCloudStore.swift
//  Nightscouter
//
//  Created by Peter Ina on 2/2/16.
//  Copyright © 2016 Nothingonline. All rights reserved.
//

import Foundation

class iCloudKeyValueStore: NSObject, SessionManagerType {
  
    private let iCloudKeyValueStore: NSUbiquitousKeyValueStore
    
    override init() {
        iCloudKeyValueStore = NSUbiquitousKeyValueStore.default()
        
        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(ubiquitousKeyValueStoreDidChange(_:)),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: iCloudKeyValueStore)
    }
    
    func ubiquitousKeyValueStoreDidChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: AnyObject], let changeReason = userInfo[NSUbiquitousKeyValueStoreChangeReasonKey] as? NSNumber else {
            return
        }
        
        let reason = changeReason.intValue
        
        if (reason == NSUbiquitousKeyValueStoreServerChange || reason == NSUbiquitousKeyValueStoreInitialSyncChange) {
            let changedKeys = userInfo[NSUbiquitousKeyValueStoreChangedKeysKey] as! [String]
            let iCloudStore = NSUbiquitousKeyValueStore.default()
            print("iCloud has the following changed keys to sync: \(changedKeys)")
            
            guard let store = store else {
                print("No Store")
                
                return
            }
            
            var syncedChanged = [String: Any]()
            
            for key in changedKeys {
                // Update Data Source
                // print(key)
                // print(iCloudStore.objectForKey(key))
                syncedChanged[key] = iCloudStore.object(forKey: key)
            }
            
            store.handleApplicationContextPayload(syncedChanged)
        }
    }
    
    var store: SiteStoreType?
    
    func startSession() {
        let lazyMap = Array(iCloudKeyValueStore.dictionaryRepresentation.keys)
        print("keys in \(iCloudKeyValueStore): " + lazyMap.description)
        
        iCloudKeyValueStore.synchronize()
    }
    
    func updateApplicationContext(_ applicationContext: [String : Any]) throws {
        for (key, object) in applicationContext where key != DefaultKey.lastDataUpdateDateFromPhone.rawValue {
            iCloudKeyValueStore.set(object, forKey: key)
        }
        
        iCloudKeyValueStore.synchronize()
    }
    }
