//
//  AppDataStore.swift
//  Nightscouter
//
//  Created by Peter Ina on 7/22/15.
//  Copyright (c) 2015 Peter Ina. All rights reserved.
//
import Foundation


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
    
    public var defaultSiteUUID: NSUUID? {
        set{
            defaults.setObject(newValue?.UUIDString, forKey: DefaultKey.defaultSiteKey)
            
            iCloudKeyStore.setString(defaultSiteUUID?.UUIDString, forKey: DefaultKey.defaultSiteKey)
            iCloudKeyStore.synchronize()
            
            updateComplicationForDefaultSite(foreRrefresh: true) { (returnedSite, _) in
                if let site = returnedSite  {
                    self.updateSite(site)
                    //self.updateWatch(withAction: .UpdateComplication)
                }
            }
        }
        get {
            if let uuidString = defaults.objectForKey(DefaultKey.defaultSiteKey) as? String {
                return NSUUID(UUIDString: uuidString)
            }
            return sites.first?.uuid
        }
    }
    
    public func defaultSite() -> Site? {
        return self.sites.filter({ (site) -> Bool in
            return site.uuid == defaultSiteUUID
        }).first
    }
    
    func dictionaryOfDataSource(watchAction: WatchAction) -> [String: AnyObject] {
        var dictionaryOfData = [String: AnyObject]()
        dictionaryOfData[DefaultKey.modelArrayObjectsKey] = sites.flatMap( { $0.viewModel.dictionary } )
        dictionaryOfData[DefaultKey.currentSiteIndexKey] = currentSiteIndex
        dictionaryOfData[DefaultKey.defaultSiteKey] = defaultSiteUUID?.UUIDString
        
        return dictionaryOfData
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
        
        if let models = defaults.arrayForKey(DefaultKey.modelArrayObjectsKey) as? [[String : AnyObject]] {
            sites = models.flatMap( { WatchModel(fromDictionary: $0)?.generateSite() } )
        }
        
        // Register for settings changes as store might have changed
        NSNotificationCenter.defaultCenter()
            .addObserver(self,
                         selector: #selector(AppDataManageriOS.userDefaultsDidChange(_:)),
                         name: NSUserDefaultsDidChangeNotification,
                         object: defaults)
        
        NSNotificationCenter.defaultCenter()
            .addObserver(self,
                         selector: #selector(AppDataManageriOS.ubiquitousKeyValueStoreDidChange(_:)),
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
    }
    
    public func updateSite(site: Site)  ->  Bool {
        
        var success = false
        
        if let index = sites.indexOf(site) {
            sites[index] = site
            success = true
        }
        
        self.updateWatch(withAction: .AppContext)
        
        return success
    }
    
    public func deleteSiteAtIndex(index: Int) {
        sites.removeAtIndex(index)
        updateWatch(withAction: .AppContext)
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
    func processApplicationContext(context: [String : AnyObject]) -> Bool {
        print("processApplicationContext \(context)")
        
        // Create a generic context to transfer to the watch.
        var success = false
        
        if let defaults = context["defaults"] as? [String: AnyObject] {
            self.defaults.setObject(defaults, forKey: "watchDefaults")
            self.iCloudKeyStore.setObject(defaults, forKey: "watchDefaults")
        }
        
        if let uuidString = context[DefaultKey.defaultSiteKey] as? String {
            defaultSiteUUID = NSUUID(UUIDString: uuidString)
        }
        
        // check to see if an incomming action is available.
        guard let action = WatchAction(rawValue: (context[WatchModel.PropertyKey.actionKey] as? String)!) else {
            print("No action was found, didReceiveMessage: \(context)")
            
            return success
        }
        
        success = true
        
        switch action {
        case .UpdateComplication:
            updateComplicationForDefaultSite(foreRrefresh: false, handler: { (site, error) in
                if let site = site {
                    self.updateSite(site)
                    self.updateWatch(withAction: action)
                }
            })
            
        default:
            generateData(forSites: self.sites, handler: { () -> Void in
                
            })
        }
        
        return success
    }
    
    private var currentPayload: [String: AnyObject] = [String: AnyObject]()
    private static let debounceIntervalTime = NSTimeInterval(4.0)
    let transmitToWatch = dispatch_debounce_block(AppDataManageriOS.debounceIntervalTime, block: {
        
        print("Throttle how many times we send to the watch... only send every \(debounceIntervalTime) seconds!!!!!!!!!")
        
        let currentPayload = AppDataManageriOS.sharedInstance.currentPayload
        
        guard let actionString = currentPayload[WatchModel.PropertyKey.actionKey] as? String, action = WatchAction(rawValue: actionString) else {
            print("no action was found.")
            return
        }
        
        if #available(iOSApplicationExtension 9.0, *) {
            WatchSessionManager.sharedManager.sendMessage(currentPayload, replyHandler: nil, errorHandler: { (error) in
                print("Sending error: \(error)")
                do {
                    print("Updating Application Context")
                    try WatchSessionManager.sharedManager.updateApplicationContext(currentPayload)
                } catch {
                    print("Couldn't update Application Context, transferUserInfo.")

                    WatchSessionManager.sharedManager.transferUserInfo(currentPayload)
                }
            })
            print("Update transferCurrentComplicationUserInfo.")
            WatchSessionManager.sharedManager.transferCurrentComplicationUserInfo(currentPayload)
        }
    })
    
    
    public func updateWatch(withAction action: WatchAction) {
        #if DEBUG
            print(">>> Entering \(#function) <<<")
            // print("Please \(action) the watch with the \(sites)")
        #endif
        
        if #available(iOSApplicationExtension 9.0, *) {
            // Create a generic context to transfer to the watch.
            var payload = [String: AnyObject]()
            // Tag the context with an action so that the watch can handle it if needed.
            // ["action" : "WatchAction.Create"] for example...
            payload[WatchModel.PropertyKey.actionKey] = action.rawValue
            // WatchOS connectivity doesn't like custom data types and complex properties. So bundle this up as an array of standard dictionaries.
            payload[WatchModel.PropertyKey.contextKey] = dictionaryOfDataSource(action)
            
            currentPayload = payload
            transmitToWatch()
        } else {
            return
        }
    }
    
    
    // MARK: Complication Data Methods
    
    public func generateData(forSites sites: [Site], handler:()->Void) -> Void {
        sites.forEach { (siteToLoad) -> () in
            print("fetching for: \(siteToLoad.url)")
            
            if siteToLoad == defaultSite() {
                updateComplicationForDefaultSite(foreRrefresh: true, handler: {returnedSite,_ in
                    // Completed complication data.
                    if let site = returnedSite  {
                        self.updateSite(site)
                        //self.updateWatch(withAction: .UpdateComplication)
                    }
                })
            } else {
                quickFetch(siteToLoad, handler: { (returnedSite, error) -> Void in
                    self.updateSite(returnedSite)
                })
            }
        }
        
        print("COMPLETE:   \(#function) complete, \(sites.count), were updated.")
        
        handler()
    }
    
    /*
     Generates data for a comnpication but does not transmitt it to the watch or update the data store.
     */
    public func updateComplicationForDefaultSite(foreRrefresh force: Bool = false, handler:(site: Site?, error: NightscoutAPIError)-> Void) {
        print(#function)
        guard let siteToLoad = self.defaultSite() else {
            handler(site: nil, error: NightscoutAPIError.DataError("No default site was found."))
            return
        }
        
        if (siteToLoad.lastConnectedDate?.compare(siteToLoad.nextRefreshDate) == .OrderedDescending || siteToLoad.configuration == nil || force == true) {
            print("START:   iOS is updating complication data for \(siteToLoad.url)")
            fetchSiteData(siteToLoad, handler: { (returnedSite, error) -> Void in
                print("COMPLETE:   iOS has updated complication data for \(siteToLoad.url)")
                handler(site: returnedSite, error: error)
                return
            })
        } else {
            handler(site: siteToLoad, error: NightscoutAPIError.NoError)
            return
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
                
                if key == DefaultKey.defaultSiteKey {
                    print("defaultSiteUUID: " + key)
                }
            }
        }
    }
}