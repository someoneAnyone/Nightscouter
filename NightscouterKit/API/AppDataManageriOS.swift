//
//  AppDataStore.swift
//  Nightscouter
//
//  Created by Peter Ina on 7/22/15.
//  Copyright (c) 2015 Peter Ina. All rights reserved.
//
import Foundation

public class AppDataManager: NSObject {
    
    public struct SavedPropertyKey {
        public static let sitesArrayObjectsKey = "userSites"
        static let currentSiteIndexKey = "currentSiteIndex"
        static let shouldDisableIdleTimerKey = "shouldDisableIdleTimer"
    }
    
    public struct SharedAppGroupKey {
        static let NightscouterGroup = "group.com.nothingonline.nightscouter"
    }
    
    public let defaults = NSUserDefaults(suiteName: SharedAppGroupKey.NightscouterGroup)!
    
    public var sites: [Site] = [Site]() {
        didSet {
            
            #if DEBUG
                // print("sites has been set with: \(sites)")
            #endif
            
            let data =  NSKeyedArchiver.archivedDataWithRootObject(self.sites)
            
            defaults.setObject(data, forKey: SavedPropertyKey.sitesArrayObjectsKey)
            defaults.synchronize()
        }
    }
    
    public var currentSiteIndex: Int {
        set {
            
            #if DEBUG
               // print("currentSiteIndex is: \(currentSiteIndex) and is changing to \(newValue)")
            #endif
            
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
               // print("shouldDisableIdleTimer currently is: \(shouldDisableIdleTimer) and is changing to \(newValue)")
            #endif
            
            defaults.setBool(newValue, forKey: SavedPropertyKey.shouldDisableIdleTimerKey)
            defaults.synchronize()
        }
        get {
            return defaults.boolForKey(SavedPropertyKey.shouldDisableIdleTimerKey)
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
        super.init()
        
        if #available(iOSApplicationExtension 9.0, *) {
            WatchSessionManager.sharedManager.startSession()
        }
        
        if let  sitesData = defaults.dataForKey(SavedPropertyKey.sitesArrayObjectsKey) {
            if let sitesArray = NSKeyedUnarchiver.unarchiveObjectWithData(sitesData) as? [Site] {
                sites = sitesArray
            }
        }
        
        if sites.isEmpty {
            updateWatch(withAction: .AppContext, withSite: [])
        }
        
         updateWatch(withAction: .UserInfo, withSite: sites)
    }
    
    public func addSite(site: Site, index: Int?) {
        if let indexOptional = index {
            if (sites.count >= indexOptional) {
                sites.insert(site, atIndex: indexOptional )
            }
        }else {
            sites.append(site)
        }
        
        updateWatch(withAction:.Create, withSite: [site])
    }
    
    public func updateSite(site: Site)  ->  Bool {
        if let index = AppDataManager.sharedInstance.sites.indexOf(site) {
            self.sites[index] = site
            updateWatch(withAction: .Update, withSite: [site])
            
            return true
        }
        
        return false
    }
    
    public func deleteSiteAtIndex(index: Int) {
        
        updateWatch(withAction: .Delete, withSite: [sites[index]])
        
        sites.removeAtIndex(index)
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
        let group = NSURL(string: "group")
        
        return (group?.URLByAppendingPathExtension((bundleIdentifier?.absoluteString)!).absoluteString)!
    }
    
    public var infoDictionary: [String: AnyObject]? {
        return NSBundle.mainBundle().infoDictionary as [String : AnyObject]? // Grab the info.plist dictionary from the main bundle.
    }
    
    public var bundleIdentifier: NSURL? {
        return NSURL(string: NSBundle.mainBundle().bundleIdentifier!)
    }
    
    public var supportedSchemes: [String]? {
        if let info = infoDictionary {
            var schemes = [String]() // Create an empty array we can later set append available schemes.
            if let bundleURLTypes = info["CFBundleURLTypes"] as? [AnyObject] {
                for (index, _) in bundleURLTypes.enumerate() {
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

extension AppDataManager {
    public func updateWatch(withAction action: WatchAction, withSite sites: [Site]) {
        #if DEBUG
            print(">>> Entering \(__FUNCTION__) <<<")
            // print("Please \(action) the watch with the \(sites)")
        #endif
        
        var context = [String: AnyObject]()
        context[WatchModel.PropertyKey.actionKey] = action.rawValue
        var models:[[String: AnyObject]] = []
        
        for site in sites {
            if let watchModel = WatchModel(fromSite: site) {
                models.append(watchModel.dictionary)
            }
        }
        context[WatchModel.PropertyKey.modelsKey] = models
        
        if #available(iOSApplicationExtension 9.0, *) {
            
            switch action {
            case .AppContext:
                do {
                    // print("sending context: \(context)")
                    try WatchSessionManager.sharedManager.updateApplicationContext(context)
                } catch let error{
                    print("updateContextError: \(error)")
                }
                
            case .UserInfo:
                WatchSessionManager.sharedManager.transferUserInfo(context)
            default:
                WatchSessionManager.sharedManager.sendMessage(context, replyHandler: { (reply) -> Void in
                    print("recieved reply: \(reply)")
                    }) { (error) -> Void in
                        print("recieved an error: \(error)")
                }
            }
            
        }
    }
}