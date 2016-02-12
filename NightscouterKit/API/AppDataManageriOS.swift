//
//  AppDataStore.swift
//  Nightscouter
//
//  Created by Peter Ina on 7/22/15.
//  Copyright (c) 2015 Peter Ina. All rights reserved.
//
import Foundation

public class AppDataManageriOS: NSObject, BundleRepresentable {
    
    public struct SharedAppGroupKey {
        static let NightscouterGroup = "group.com.nothingonline.nightscouter"
    }
    
    public let defaults = NSUserDefaults(suiteName: SharedAppGroupKey.NightscouterGroup)!
    
    // Sites are containers of raw data...
    public var sites: [Site] = [] {
        didSet {
            #if DEBUG
                // print("sites has been set with: \(sites)")
            #endif
            
            // Create NSData and store it to nsdefaults.
             let userSitesData =  NSKeyedArchiver.archivedDataWithRootObject(self.sites)
             defaults.setObject(userSitesData, forKey: DefaultKey.sitesArrayObjectsKey)
            
            let models: [[String : AnyObject]] = sites.flatMap( { $0.viewModel.dictionary } )
            defaults.setObject(models, forKey: DefaultKey.modelArrayObjectsKey)
        }
    }
    
    public var currentSiteIndex: Int {
        set {
            
            #if DEBUG
                print("currentSiteIndex is: \(currentSiteIndex) and is changing to \(newValue)")
            #endif
            
            defaults.setInteger(newValue, forKey: DefaultKey.currentSiteIndexKey)
        }
        get {
            return defaults.integerForKey(DefaultKey.currentSiteIndexKey)
        }
    }
    
    public var defaultSite: NSUUID? {
        set {
            defaults.setObject(newValue?.UUIDString, forKey: DefaultKey.defaultSiteKey)
        }
        get {
            guard let uuidString = defaults.objectForKey(DefaultKey.defaultSiteKey) as? String else {
                if let firstModel = sites.first {
                    return firstModel.uuid
                }
                return nil
            }
            
            return NSUUID(UUIDString: uuidString)
        }
    }
    
    public static let sharedInstance = AppDataManageriOS()
    
    private override init() {
        super.init()
        
        if #available(iOSApplicationExtension 9.0, *) {
            WatchSessionManager.sharedManager.startSession()
        }
        
        if let models = defaults.objectForKey(DefaultKey.modelArrayObjectsKey) as? [[String : AnyObject]] {
            sites = models.flatMap( { WatchModel(fromDictionary: $0)?.generateSite() } )
        }
        defaults.setObject("iOS", forKey: "osPlatform")
        
        // Register for settings changes as store might have changed
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: Selector("userDefaultsDidChange:"),
            name: NSUserDefaultsDidChangeNotification,
            object: nil)
    }
    
    public func addSite(site: Site, index: Int?) {
        
        if sites.isEmpty {
            defaultSite = site.uuid
        }
        
        if let indexOptional = index {
            if (sites.count >= indexOptional) {
                sites.insert(site, atIndex: indexOptional )
            }
        }else {
            sites.append(site)
        }
    }
    
    public func updateSite(site: Site)  ->  Bool {
        if let index = sites.indexOf(site) {
            sites[index] = site
            return true
        }
        
        return false
    }
    
    public func deleteSiteAtIndex(index: Int) {
        
        let siteToBeRemoved = sites[index]
        
        if siteToBeRemoved.uuid == defaultSite {
            defaultSite = nil
        }
        
        if sites.isEmpty {
            currentSiteIndex = 0
        }
        
        sites.removeAtIndex(index)
    }
    
    private func loadSampleSites() -> Void {
        // Create a site URL.
        let demoSiteURL = NSURL(string: "https://nscgm.herokuapp.com")!
        // Create a site.
        let demoSite = Site(url: demoSiteURL, apiSecret: nil)!
        
        // Add it to the site Array
        sites = [demoSite]
    }
    
    // MARK: Extras
    
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
    
    
    func processApplicationContext(context: [String : AnyObject]) -> Bool {
        print("processApplicationContext \(context)")
        
        guard let _ = WatchAction(rawValue: (context[WatchModel.PropertyKey.actionKey] as? String)!) else {
            print("No action was found, didReceiveMessage: \(context)")
            return false
        }
        
        guard let payload = context[WatchModel.PropertyKey.contextKey] as? [String: AnyObject] else {
            print("No payload was found.")
            
            print(context)
            return false
            
        }
        
        if let defaultSiteString = payload[DefaultKey.defaultSiteKey] as? String, uuid = NSUUID(UUIDString: defaultSiteString)  {
            defaultSite = uuid
        }
        
        if let currentIndex = payload[DefaultKey.currentSiteIndexKey] as? Int {
            currentSiteIndex = currentIndex
        }
        
        if let siteArray = payload[DefaultKey.modelArrayObjectsKey] as? [[String: AnyObject]] {
            sites = siteArray.flatMap{ WatchModel(fromDictionary: $0)?.generateSite() }
        }
        
        return true
    }
    
    public func updateWatch(withAction action: WatchAction, withContext context:[String: AnyObject]? = nil) {
        #if DEBUG
            print(">>> Entering \(__FUNCTION__) <<<")
            // print("Please \(action) the watch with the \(sites)")
        #endif
        
        // Create a generic context to transfer to the watch.
        var payload = [String: AnyObject]()
        
        // Tag the context with an action so that the watch can handle it if needed.
        // ["action" : "WatchAction.Create"] for example...
        payload[WatchModel.PropertyKey.actionKey] = action.rawValue
        
        // WatchOS connectivity doesn't like custom data types and complex properties. So bundle this up as an array of standard dictionaries.
        payload[WatchModel.PropertyKey.contextKey] = context ?? defaults.dictionaryRepresentation()
        
        if #available(iOSApplicationExtension 9.0, *) {
            
            switch action {
            case .AppContext:
                WatchSessionManager.sharedManager.sendMessage(payload, replyHandler: { (reply) -> Void in
                    print("recieved reply: \(reply)")
                    }) { (error) -> Void in
                        print("recieved an error: \(error)")
                        
                        WatchSessionManager.sharedManager.transferCurrentComplicationUserInfo(payload)
                }
                
            default:
                WatchSessionManager.sharedManager.transferCurrentComplicationUserInfo(payload)
                lastWatchUpdateDate = NSDate()
            }
        }
        
    }
    
    public func siteForComplication() -> Site? {
        return self.sites.filter({ (model) -> Bool in
            return model.uuid == defaultSite
        }).first
    }
    
    public func generateDataForAllSites() -> Void {
        
        for siteToLoad in sites {
            
            fetchSiteData(forSite: siteToLoad, forceRefresh: true, handler: { (reloaded, returnedSite, returnedIndex, returnedError) -> Void in
                self.updateSite(returnedSite)
                return
            })
        }
    }
    
    var lastWatchUpdateDate: NSDate = NSDate().dateByAddingTimeInterval(Constants.NotableTime.StandardRefreshTime.inThePast)
    var nextWatchUpdateDate: NSDate {
        return lastWatchUpdateDate.dateByAddingTimeInterval(60.0 * 1)
    }
    
    func userDefaultsDidChange(notification: NSNotification) {
        if let defaultObject = notification.object as? NSUserDefaults {
            print("Defaults Changed")
            updateWatch(withAction: WatchAction.UserInfo, withContext: defaultObject.dictionaryRepresentation())
        }
    }
    
}