//
//  AppDataStore.swift
//  Nightscouter
//
//  Created by Peter Ina on 7/22/15.
//  Copyright (c) 2015 Peter Ina. All rights reserved.
//
import Foundation

public class AppDataManager: NSObject {
    
    internal struct SavedPropertyKey {
        static let sitesArrayObjectsKey = "userSites"
        static let currentSiteIndexKey = "currentSiteIndex"
        static let shouldDisableIdleTimerKey = "shouldDisableIdleTimer"
    }
    
    public struct SharedAppGroupKey {
        static let NightscouterGroup = "group.com.nothingonline.nightscouter"
    }
    
    public var sites: [Site] = [Site]()
    
    public var currentSiteIndex: Int {
        set {
            defaults.setInteger(newValue, forKey: SavedPropertyKey.currentSiteIndexKey)
            defaults.synchronize()
        }
        get {
            return defaults.integerForKey(SavedPropertyKey.currentSiteIndexKey)
        }
    }
    
    public var shouldDisableIdleTimer: Bool {
        set {
            #if DEBUG
                println("shouldDisableIdleTimer currently is: \(shouldDisableIdleTimer) and is changing to \(newValue)")
            #endif
            
            defaults.setBool(newValue, forKey: SavedPropertyKey.shouldDisableIdleTimerKey)
            defaults.synchronize()
        }
        get {
            return defaults.boolForKey(SavedPropertyKey.shouldDisableIdleTimerKey)
        }
    }
    
    public let defaults: NSUserDefaults
    
    lazy var applicationDocumentsDirectory: NSURL? = {
        return NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier(SharedAppGroupKey.NightscouterGroup) ?? nil
        }()
    
    public var sitesFileURL: NSURL {
        get {
            let groupURL = applicationDocumentsDirectory
            let fileURL = groupURL?.URLByAppendingPathComponent(Site.PropertyKey.sitesPlistKey)
            
            return fileURL!
        }
    }
    
    public class var sharedInstance: AppDataManager {
        struct Static {
            static var onceToken: dispatch_once_t = 0
            static var instance: AppDataManager? = nil
        }
        dispatch_once(&Static.onceToken) {
            Static.instance = AppDataManager()
        }
        return Static.instance!
    }
    
    internal override init() {
        defaults  = NSUserDefaults(suiteName: SharedAppGroupKey.NightscouterGroup)!
        
        super.init()
        
        if let  sitesData = NSKeyedUnarchiver.unarchiveObjectWithFile(sitesFileURL.path!) as? NSData {
            if let sitesArray = NSKeyedUnarchiver.unarchiveObjectWithData(sitesData) as? [Site] {
                sites = sitesArray
                
                saveAppData()
            }
        }
        
    }
    
    public func saveAppData() {
        // write to disk
        let data =  NSKeyedArchiver.archivedDataWithRootObject(self.sites)
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
            let fileDiskSave = NSKeyedArchiver.archiveRootObject(data, toFile: self.sitesFileURL.path!)
            #if DEBUG
                if !fileDiskSave {
                    println("Failed to save sites...")
                }else{
                    println("Successful save...")
                }
            #endif
        })
    }
    
    public func addSite(site: Site, index: Int?) {
        if let indexOptional = index {
            if (sites.count >= indexOptional) {
                sites.insert(site, atIndex: indexOptional )
            }
        }else {
            sites.append(site)
        }
        saveAppData()
    }
    
    public func updateSite(site: Site)  ->  Bool {
        if let index = find(AppDataManager.sharedInstance.sites, site) {
            self.sites[index] = site
            saveAppData()
            return true
        }
        
        return false
    }
    
    public func deleteSiteAtIndex(index: Int) {
        let site = sites[index]
        sites.removeAtIndex(index)
        saveAppData()
    }
    
    public func loadSampleSites() -> Void {
        // Create a site URL.
        let demoSiteURL = NSURL(string: "https://nscgm.herokuapp.com")!
        // Create a site.
        let demoSite = Site(url: demoSiteURL, apiSecret: nil)!
        
        // Add it to the site Array
        sites = [demoSite]
    }
    
    // MARK: Extras
    
    public var sharedGroupIdentifier: String {
        let group = "group"
        return group.stringByAppendingPathExtension(bundleIdentifier!)!
    }
    
    public var infoDictionary: [String: AnyObject]? {
        return NSBundle.mainBundle().infoDictionary as? [String : AnyObject] // Grab the info.plist dictionary from the main bundle.
    }
    
    public var bundleIdentifier: String? {
        return NSBundle.mainBundle().bundleIdentifier
    }
    
    public var supportedSchemes: [String]? {
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
    
}