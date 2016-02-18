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
            
            NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
                NSNotificationCenter.defaultCenter().postNotificationName(AppDataManagerDidChangeNotification, object: nil)
            }
            
            if sites.isEmpty {
                defaultSiteUUID = nil
                currentSiteIndex = 0
            }
            
            updateWatch(withAction: .AppContext, withContext: [DefaultKey.modelArrayObjectsKey : self.sites.map{ $0.viewModel.dictionary }])
            
            saveData()
        }
    }
    
    public var currentSiteIndex: Int = 0
    
    public var defaultSiteUUID: NSUUID?
    
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
    
    public var nextRefreshDate: NSDate {
        let date = NSDate().dateByAddingTimeInterval(Constants.NotableTime.StandardRefreshTime)
        print("iOS nextRefreshDate: " + date.description)
        return date
    }
    
    // MARK: Save and Load Data
    public func saveData() {
        
        // let userSitesData =  NSKeyedArchiver.archivedDataWithRootObject(self.sites)
        // defaults.setObject(userSitesData, forKey: DefaultKey.sitesArrayObjectsKey)
        if let _ = defaults.objectForKey(DefaultKey.sitesArrayObjectsKey) {
            defaults.setObject(nil, forKey: DefaultKey.sitesArrayObjectsKey)
        }
        
        let models: [[String : AnyObject]] = sites.flatMap( { $0.viewModel.dictionary } )
        
        defaults.setObject(models, forKey: DefaultKey.modelArrayObjectsKey)
        defaults.setInteger(currentSiteIndex, forKey: DefaultKey.currentSiteIndexKey)
        defaults.setObject("iOS", forKey: DefaultKey.osPlatform)
        defaults.setObject(defaultSiteUUID?.UUIDString, forKey: DefaultKey.defaultSiteKey)
        
        // Save To iCloud
        if let _ = iCloudKeyStore.dataForKey(DefaultKey.sitesArrayObjectsKey) {
            iCloudKeyStore.setData(nil, forKey: DefaultKey.sitesArrayObjectsKey)
        }
        // iCloudKeyStore.setData(userSitesData, forKey: DefaultKey.sitesArrayObjectsKey)
        iCloudKeyStore.setObject(currentSiteIndex, forKey: DefaultKey.currentSiteIndexKey)
        iCloudKeyStore.setArray(models, forKey: DefaultKey.modelArrayObjectsKey)
        iCloudKeyStore.setString(defaultSiteUUID?.UUIDString, forKey: DefaultKey.defaultSiteKey)
        
        iCloudKeyStore.synchronize()
    }
    
    public func loadData() {
        
        currentSiteIndex = defaults.integerForKey(DefaultKey.currentSiteIndexKey)
        if let models = defaults.arrayForKey(DefaultKey.modelArrayObjectsKey) as? [[String : AnyObject]] {
            sites = models.flatMap( { WatchModel(fromDictionary: $0)?.generateSite() } )
        }
        if let uuidString = defaults.objectForKey(DefaultKey.defaultSiteKey) as? String {
            defaultSiteUUID =  NSUUID(UUIDString: uuidString)
        } else  if let firstModel = sites.first {
            defaultSiteUUID = firstModel.uuid
        }
        
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
    }
    
    public func updateSite(site: Site)  ->  Bool {
        if let currentIndex = sites.indexOf(site) {
            sites[currentIndex] = site
            
            if site == defaultSite() {
                updateComplication()
            }
            
            return true
        }
        
        return false
    }
    
    public func deleteSiteAtIndex(index: Int) {
        sites.removeAtIndex(index)
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
            guard let defaultSite = defaultSite() else {
                return false
            }
            generateData(forSites: [defaultSite], handler: { () -> Void in
                // WatchOS connectivity doesn't like custom data types and complex properties. So bundle this up as an array of standard dictionaries.
                //payload[WatchModel.PropertyKey.contextKey] = self.defaults.dictionaryRepresentation()
                self.updateWatch(withAction: .UpdateComplication)
                replyHandler([WatchModel.PropertyKey.actionKey : WatchAction.UpdateComplication.rawValue])
            })
            
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
        
        // Tag the context with an action so that the watch can handle it if needed.
        // ["action" : "WatchAction.Create"] for example...
        payload[WatchModel.PropertyKey.actionKey] = action.rawValue
        
        // WatchOS connectivity doesn't like custom data types and complex properties. So bundle this up as an array of standard dictionaries.
        payload[WatchModel.PropertyKey.contextKey] = context ?? defaults.dictionaryRepresentation()
        
        if #available(iOSApplicationExtension 9.0, *) {
            switch action {
            case .AppContext:
                print("Sending application context")
                do {
                    try WatchSessionManager.sharedManager.updateApplicationContext(payload)
                } catch {
                    print(error)
                }
                
            case .UpdateComplication:
                print("Sending user info with complication data")
                WatchSessionManager.sharedManager.transferCurrentComplicationUserInfo(payload)
            case .UserInfo:
                print("Sending user info")
                WatchSessionManager.sharedManager.transferUserInfo(payload)
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
            if (siteToLoad.lastConnectedDate?.compare(AppDataManageriOS.sharedInstance.nextRefreshDate) == .OrderedDescending || siteToLoad.configuration == nil) {
            print("START:   iOS is updating complication data for \(siteToLoad.url)")
                fetchSiteData(siteToLoad, handler: { (returnedSite, error) -> Void in
                    self.updateSite(returnedSite)
                    self.updateWatch(withAction: .UpdateComplication)
                    print("COMPLETE:   iOS has updated complication data for \(siteToLoad.url)")
                    return
                })
            }
        }
    }
    
    
    // MARK: Storage Updates
    
    // MARK: Defaults have Changed
    
    func userDefaultsDidChange(notification: NSNotification) {
        print("userDefaultsDidChange:")
        
        // guard let defaultObject = notification.object as? NSUserDefaults else { return }
        
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
                    currentSiteIndex = store.objectForKey(DefaultKey.currentSiteIndexKey) as! Int
                }
            }
        }
    }
}