//
//  AppDataStore.swift
//  Nightscouter
//
//  Created by Peter Ina on 7/22/15.
//  Copyright (c) 2015 Peter Ina. All rights reserved.
//

import Foundation
import UIKit

class AppDataManager: NSObject, UIStateRestoring {
    
    var sites: [Site] = [Site]() {
        didSet {
            saveAppData()
        }
    }
    
    struct SavedPropertyKey {
        static let sitesArrayObjectsKey = "userSites"
        static let currentSiteIndexKey = "currentSiteIndex"
        static let shouldDisableIdleTimerKey = "shouldDisableIdleTimer"
    }
    
    let defaults: NSUserDefaults
    
    var currentSiteIndex: Int {
        set {
            defaults.setInteger(newValue, forKey: SavedPropertyKey.currentSiteIndexKey)
            defaults.synchronize()
        }
        get {
            return defaults.integerForKey(SavedPropertyKey.currentSiteIndexKey)
        }
    }
    
    var shouldDisableIdleTimer: Bool {
        set {
            #if DEBUG
                println("shouldDisableIdleTimer currently is: \(shouldDisableIdleTimer) and is changing to \(newValue)")
            #endif
            
            defaults.setBool(newValue, forKey: SavedPropertyKey.shouldDisableIdleTimerKey)
            UIApplication.sharedApplication().idleTimerDisabled = newValue
            defaults.synchronize()
        }
        get {
            
            #if DEBUG
                println("shouldDisableIdleTimer: \(shouldDisableIdleTimer)")
            #endif

            return defaults.boolForKey(SavedPropertyKey.shouldDisableIdleTimerKey)
        }
    }
    
    class var sharedInstance: AppDataManager {
        struct Static {
            static var onceToken: dispatch_once_t = 0
            static var instance: AppDataManager? = nil
        }
        dispatch_once(&Static.onceToken) {
            Static.instance = AppDataManager()
        }
        return Static.instance!
    }
    
    override init() {
        defaults  = NSUserDefaults.standardUserDefaults()

        super.init()

        if let arrayOfObjectsUnarchivedData = defaults.dataForKey(SavedPropertyKey.sitesArrayObjectsKey) {
            if let arrayOfObjectsUnarchived = NSKeyedUnarchiver.unarchiveObjectWithData(arrayOfObjectsUnarchivedData) as? [Site] {
                sites = arrayOfObjectsUnarchived
            }
        }
        
        /*
        if let  sitesData = NSKeyedUnarchiver.unarchiveObjectWithFile(Site.ArchiveURL.path!) as? NSData {
        if let sitesArray = NSKeyedUnarchiver.unarchiveObjectWithData(sitesData) as? [Site] {
        sites = sitesArray
        }
        }
        */
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func saveAppData() {
        
        // write to disk
        let data =  NSKeyedArchiver.archivedDataWithRootObject(sites)
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(data, toFile: Site.ArchiveURL.path!)
        
        #if DEBUG
        if !isSuccessfulSave {
            println("Failed to save sites...")
        }else{
            println("Successful save...")
        }
        #endif
        
        // write to defaults
        var arrayOfObjects = [Site]()
        var arrayOfObjectsData = NSKeyedArchiver.archivedDataWithRootObject(sites)
        defaults.setObject(arrayOfObjectsData, forKey: SavedPropertyKey.sitesArrayObjectsKey)
    }
    
    func addSite(site: Site, index: Int?) {
        if let indexOptional = index {
            if (sites.count >= indexOptional) {
                sites.insert(site, atIndex: indexOptional )
            }
        }else {
            sites.append(site)
        }
        
        saveAppData()
    }
    
    func deleteSiteAtIndex(index: Int) {
             let site = sites[index]
                
        for notifications in site.notifications {
            UIApplication.sharedApplication().cancelLocalNotification(notifications)
        }
        
//        
//        for notification in UIApplication.sharedApplication().scheduledLocalNotifications as! [UILocalNotification] { // loop through notifications...
//            if (notification.userInfo![Site.PropertyKey.uuidKey] as! String == item.UUID) { // ...and cancel the notification that corresponds to this TodoItem instance (matched by UUID)
//                UIApplication.sharedApplication().cancelLocalNotification(notification) // there should be a maximum of one match on UUID
//                break
//            }
//        }
        
        sites.removeAtIndex(index)

        saveAppData()
    }
    
    func loadSampleSites() -> Void {
        // Create a site URL.
        let demoSiteURL = NSURL(string: "https://nscgm.herokuapp.com")!
        // Create a site.
        let demoSite = Site(url: demoSiteURL, apiSecret: nil)!
        
        // Add it to the site Array
        sites = [demoSite]
    }
    
}