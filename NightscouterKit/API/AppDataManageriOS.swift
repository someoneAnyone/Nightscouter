//
//  AppDataStore.swift
//  Nightscouter
//
//  Created by Peter Ina on 7/22/15.
//  Copyright (c) 2015 Peter Ina. All rights reserved.
//
import Foundation

public let AppDataManagerDidChangeNotification: String = "com.nothingonline.nightscouter.appDataManager.DidChange.Notification"

public class AppDataManageriOS: NSObject, BundleRepresentable {
    
    public var sites: [Site] = [] {
        didSet{
            let models: [[String : AnyObject]] = sites.flatMap( { $0.viewModel.dictionary } )
            if models.isEmpty {
                defaultSiteUUID = nil
                currentSiteIndex = 0
                
                iCloudKeyStore.resetStorage()
            }
            
            defaults.setObject(models, forKey: DefaultKey.modelArrayObjectsKey)
            defaults.synchronize()
            
            iCloudKeyStore.setArray(models, forKey: DefaultKey.modelArrayObjectsKey)
            
            iCloudKeyStore.synchronize()
        }
    }
    
    
    //    public var sites: [Site] = [] {
    //        didSet{
    //
    //            if sites.isEmpty {
    //                defaultSiteUUID = nil
    //                currentSiteIndex = 0
    //
    //                resetStorage(forUbiquitousKeyValueStore: iCloudKeyStore)
    //            }
    //
    //            saveData()
    //
    //            NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
    //                NSNotificationCenter.defaultCenter().postNotificationName(AppDataManagerDidChangeNotification, object: nil)
    //            }
    //        }
    //    }
    
    public var currentSiteIndex: Int {
        set{
            defaults.setInteger(newValue, forKey: DefaultKey.currentSiteIndexKey)
            iCloudKeyStore.setLongLong(Int64(currentSiteIndex), forKey: DefaultKey.currentSiteIndexKey)
            iCloudKeyStore.synchronize()
        }
        get{
            return defaults.integerForKey(DefaultKey.currentSiteIndexKey)
        }
    }
    
    //    public var currentSiteIndex: Int = 0 {
    //        didSet {
    //            saveData()
    //        }
    //    }
    public var defaultSiteUUID: NSUUID? {
        set{
            defaults.setObject(newValue?.UUIDString, forKey: DefaultKey.defaultSiteKey)
            iCloudKeyStore.setString(defaultSiteUUID?.UUIDString, forKey: DefaultKey.defaultSiteKey)
            iCloudKeyStore.synchronize()
            updateComplication()
        }
        get {
            if let uuidString = defaults.objectForKey(DefaultKey.defaultSiteKey) as? String {
                return NSUUID(UUIDString: uuidString)
            }
            return sites.first?.uuid
        }
    }
    //
    //    public var defaultSiteUUID: NSUUID? {
    //        didSet {
    //            saveData()
    //        }
    //    }
    
    public func defaultSite() -> Site? {
        return self.sites.filter({ (site) -> Bool in
            return site.uuid == defaultSiteUUID
        }).first
    }
    
    public static let sharedInstance = AppDataManageriOS()
    
    private override init() {
        super.init()
        
        loadData()
    }
    
    deinit {
        saveData()
    }
    
    private struct SharedAppGroupKey {
        static let NightscouterGroup = "group.com.nothingonline.nightscouter"
    }
    
    public let defaults = NSUserDefaults(suiteName: SharedAppGroupKey.NightscouterGroup)!
    
    public let iCloudKeyStore = NSUbiquitousKeyValueStore.defaultStore()
    
//    public var nextRefreshDate: NSDate {
//        let date = NSDate().dateByAddingTimeInterval(Constants.NotableTime.StandardRefreshTime)
//        print("iOS nextRefreshDate: " + date.description)
//        return date
//    }
    
    // MARK: Save and Load Data
    public func saveData() {
        
        let models: [[String : AnyObject]] = sites.flatMap( { $0.viewModel.dictionary } )
        
        defaults.setObject(models, forKey: DefaultKey.modelArrayObjectsKey)
        defaults.setInteger(currentSiteIndex, forKey: DefaultKey.currentSiteIndexKey)
        defaults.setObject("iOS", forKey: DefaultKey.osPlatform)
        defaults.setObject(defaultSiteUUID?.UUIDString, forKey: DefaultKey.defaultSiteKey)
        
        // Save To iCloud
        iCloudKeyStore.setObject(currentSiteIndex, forKey: DefaultKey.currentSiteIndexKey)
        iCloudKeyStore.setArray(models, forKey: DefaultKey.modelArrayObjectsKey)
        iCloudKeyStore.setString(defaultSiteUUID?.UUIDString, forKey: DefaultKey.defaultSiteKey)
        
        iCloudKeyStore.synchronize()
    }
    
    public func loadData() {
        
        //        currentSiteIndex = defaults.integerForKey(DefaultKey.currentSiteIndexKey)
        if let models = defaults.arrayForKey(DefaultKey.modelArrayObjectsKey) as? [[String : AnyObject]] {
            sites = models.flatMap( { WatchModel(fromDictionary: $0)?.generateSite() } )
        }
        //        if let uuidString = defaults.objectForKey(DefaultKey.defaultSiteKey) as? String {
        //            defaultSiteUUID =  NSUUID(UUIDString: uuidString)
        //        } else  if let firstModel = sites.first {
        //            defaultSiteUUID = firstModel.uuid
        //        }
        
        // Register for settings changes as store might have changed
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: Selector("userDefaultsDidChange:"),
            name: NSUserDefaultsDidChangeNotification,
            object: defaults)
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "ubiquitousKeyValueStoreDidChange:",
            name: NSUbiquitousKeyValueStoreDidChangeExternallyNotification,
            object: iCloudKeyStore)
        
        iCloudKeyStore.synchronize()
        
    }
    
    
    // MARK: Data Source Managment
    public func addSite(site: Site, index: Int?) {
        guard let safeIndex = index where sites.count >= safeIndex else {
            sites.append(site)
            
            return
        }
        
        sites.insert(site, atIndex: safeIndex)
        updateWatch(withAction: .AppContext)
        //        updateWatch(withAction: .UserInfo)
    }
    
    public func updateSite(site: Site)  ->  Bool {
        
        var success = false
        
        if let index = sites.indexOf(site) {
            sites[index] = site
            success = true
        }
        
        updateWatch(withAction: .AppContext)
        
              
        return success
    }
    
    public func deleteSiteAtIndex(index: Int) {
        sites.removeAtIndex(index)
        updateWatch(withAction: .AppContext)
        
        //        updateWatch(withAction: .UserInfo)
    }
    
    
    // MARK: Demo Site
    private func loadSampleSites() -> Void {
        // Create a site URL.
        let demoSiteURL = NSURL(string: "https://nscgm.herokuapp.com")!
        // Create a site.
        let demoSite = Site(url: demoSiteURL, apiSecret: nil)!
        
        // Add it to the site Array
        sites = [demoSite]
    }
    
    
    // MARK: Supported URL Schemes
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
    
    
    // MARK: Watch OS Communication
    func processApplicationContext(context: [String : AnyObject], replyHandler:([String : AnyObject]) -> Void ) -> Bool {
        print("processApplicationContext \(context)")
        
        guard let action = WatchAction(rawValue: (context[WatchModel.PropertyKey.actionKey] as? String)!) else {
            print("No action was found, didReceiveMessage: \(context)")
            
            return false
        }
        /*
        guard let payload = context[WatchModel.PropertyKey.contextKey] as? [String: AnyObject] else {
        print("No payload was found.")
        
        print(context)
        return false
        
        }
        */
        
        /*
        if let defaultSiteString = payload[DefaultKey.defaultSiteKey] as? String, uuid = NSUUID(UUIDString: defaultSiteString)  {
        defaultSiteUUID = uuid
        }
        
        if let currentIndex = payload[DefaultKey.currentSiteIndexKey] as? Int {
        currentSiteIndex = currentIndex
        }
        
        if let siteArray = payload[DefaultKey.modelArrayObjectsKey] as? [[String: AnyObject]] {
        sites = siteArray.flatMap{ WatchModel(fromDictionary: $0)?.generateSite() }
        }
        */
        
        // Create a generic context to transfer to the watch.
        var payload = [String: AnyObject]()
        
        // Tag the context with an action so that the watch can handle it if needed.
        // ["action" : "WatchAction.Create"] for example...
        payload[WatchModel.PropertyKey.actionKey] = action.rawValue
        
        
        switch action {
        case .AppContext:
            generateData(forSites: self.sites, handler: { () -> Void in
                // WatchOS connectivity doesn't like custom data types and complex properties. So bundle this up as an array of standard dictionaries.
                payload[WatchModel.PropertyKey.contextKey] = self.defaults.dictionaryRepresentation()
                
                replyHandler(payload)
            })
            
            // updateWatch(withAction: .AppContext)
        case .UpdateComplication:
            //            guard let defaultSite = defaultSite() else {
            //                return false
            //            }
            updateComplication()
            payload[WatchModel.PropertyKey.contextKey] = self.defaults.dictionaryRepresentation()

            replyHandler(payload)
            //            generateData(forSites: [defaultSite], handler: { () -> Void in
            //                // WatchOS connectivity doesn't like custom data types and complex properties. So bundle this up as an array of standard dictionaries.
            //                //payload[WatchModel.PropertyKey.contextKey] = self.defaults.dictionaryRepresentation()
            //                self.updateWatch(withAction: .UpdateComplication)
            //                replyHandler([WatchModel.PropertyKey.actionKey : WatchAction.UpdateComplication.rawValue])
            //            })
            
        case .UserInfo:
            updateWatch(withAction: .UserInfo)
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
        
        
        
        if #available(iOSApplicationExtension 9.0, *) {
            
            // Tag the context with an action so that the watch can handle it if needed.
            // ["action" : "WatchAction.Create"] for example...
            payload[WatchModel.PropertyKey.actionKey] = action.rawValue
            
            // WatchOS connectivity doesn't like custom data types and complex properties. So bundle this up as an array of standard dictionaries.
            payload[WatchModel.PropertyKey.contextKey] = context ?? defaults.dictionaryRepresentation()
            
            
            if WatchSessionManager.sharedManager.validReachableSession == nil {
                // Tag the context with an action so that the watch can handle it if needed.
                // ["action" : "WatchAction.Create"] for example...
                payload[WatchModel.PropertyKey.actionKey] = WatchAction.UpdateComplication.rawValue
            }
            
            switch action {
            case .AppContext:
                print("Sending application context")
                
                do {
                    try WatchSessionManager.sharedManager.updateApplicationContext(payload)
                } catch {
                    WatchSessionManager.sharedManager.transferCurrentComplicationUserInfo(payload)
                }

            case .UpdateComplication, .UserInfo:
                print("Sending user info with complication data")
                WatchSessionManager.sharedManager.transferCurrentComplicationUserInfo(payload)
            }
        }
    }
    
    
    // MARK: Complication Data Methods
    
    public func generateData(forSites sites: [Site], handler:()->Void) -> Void {
        sites.forEach { (siteToLoad) -> () in
            print("fetching for: \(siteToLoad.url)")
            fetchSiteData(siteToLoad, handler: { (returnedSite, error) -> Void in
                self.updateSite(returnedSite)
            })
        }
        
        print("COMPLETE:   generateDataForAllSites complete")
        
        handler()
    }
    
    public func updateComplication() {
        print("updateComplication")
        if let siteToLoad = self.defaultSite() {
            if (siteToLoad.lastConnectedDate?.compare(siteToLoad.nextRefreshDate) == .OrderedDescending || siteToLoad.configuration == nil) {
                print("START:   iOS is updating complication data for \(siteToLoad.url)")
                fetchSiteData(siteToLoad, handler: { (returnedSite, error) -> Void in
                    self.updateSite(returnedSite)
                    self.updateWatch(withAction: .UpdateComplication)
                    print("COMPLETE:   iOS has updated complication data for \(siteToLoad.url)")
                    return
                })
            } else {
                self.updateWatch(withAction: .UpdateComplication)
            }
        }
    }
    
    
    // MARK: Storage Updates
    
    // MARK: Defaults have Changed
    
    func userDefaultsDidChange(notification: NSNotification) {
        print("userDefaultsDidChange:")
        
        // guard let defaultObject = notification.object as? NSUserDefaults else { return }
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            NSNotificationCenter.defaultCenter().postNotificationName(AppDataManagerDidChangeNotification, object: nil)
        }
        
    }
    
    // MARK: iCloud Key Store Changed
    
    func ubiquitousKeyValueStoreDidChange(notification: NSNotification) {
        print("ubiquitousKeyValueStoreDidChange:")
        
        guard let userInfo = notification.userInfo as? [String: AnyObject], changeReason = userInfo[NSUbiquitousKeyValueStoreChangeReasonKey] as? NSNumber else {
            return
        }
        let reason = changeReason.integerValue
        
        if (reason == NSUbiquitousKeyValueStoreServerChange || reason == NSUbiquitousKeyValueStoreInitialSyncChange) {
            let changedKeys = userInfo[NSUbiquitousKeyValueStoreChangedKeysKey] as! [String]
            let store = NSUbiquitousKeyValueStore.defaultStore()
            
            for key in changedKeys {
                
                // Update Data Source
                
                if key == DefaultKey.modelArrayObjectsKey {
                    if let models = store.arrayForKey(DefaultKey.modelArrayObjectsKey) as? [[String : AnyObject]] {
                        sites = models.flatMap( { WatchModel(fromDictionary: $0)?.generateSite() } )
                    }
                }
                
                if key == DefaultKey.currentSiteIndexKey {
                    currentSiteIndex = Int(store.longLongForKey(DefaultKey.currentSiteIndexKey))
                }
            }
        }
    }
}