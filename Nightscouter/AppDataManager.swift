//
//  AppDataStore.swift
//  Nightscouter
//
//  Created by Peter Ina on 7/22/15.
//  Copyright (c) 2015 Peter Ina. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
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
            return defaults.boolForKey(SavedPropertyKey.shouldDisableIdleTimerKey)
        }
    }
    
    var infoDictionary: [String: AnyObject]? {
        return NSBundle.mainBundle().infoDictionary as? [String : AnyObject] // Grab the info.plist dictionary from the main bundle.
    }
    
    var bundleIdentifier: String? {
        if let dictionary = infoDictionary {
            return dictionary["CFBundleIdentifier"] as? String
        }
        return nil
    }
    
    var supportedSchemes: [String]? {
        if let info = infoDictionary {
            var schemes = [String]() // Create an empty array we can later set append available schemes.
            if let bundleURLTypes = info["CFBundleURLTypes"] as? [AnyObject] {
                for (index, object) in enumerate(bundleURLTypes) {
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
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {

        // write to disk
        let data =  NSKeyedArchiver.archivedDataWithRootObject(self.sites)
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
        var arrayOfObjectsData = NSKeyedArchiver.archivedDataWithRootObject(self.sites)
        self.defaults.setObject(arrayOfObjectsData, forKey: SavedPropertyKey.sitesArrayObjectsKey)
        })
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
    
    func updateSite(site: Site)  ->  Bool {
        if let index = find(AppDataManager.sharedInstance.sites, site) {
            self.sites[index] = site
            return true
        }
        return false
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
    
    func setupAudioPlayerWithFile(file: String, type: String) -> AVAudioPlayer  {
        //1
        
//        let filePath = NSBundle.mainBundle().pathForResource(file, ofType: "mp3", inDirectory: "audio")
//        let defaultDBPath =  NSBundle.mainBundle().resourcePath?.stringByAppendingPathComponent("audio")

        
        let path = NSBundle.mainBundle().pathForResource(file, ofType: type, inDirectory:"audio")
//        var path = NSBundle.mainBundle().pathForResource(file, ofType:type)
        var url = NSURL.fileURLWithPath(path!)
        
        //2
        var error: NSError?
        
        //3
        var audioPlayer: AVAudioPlayer?
        audioPlayer = AVAudioPlayer(contentsOfURL: url, error: &error)
        
        //4
        return audioPlayer!
    }
    
}