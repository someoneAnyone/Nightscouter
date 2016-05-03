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
    
    var dictionaryOfDataSource:[String: AnyObject] {
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
        
        
        transmitToWatch()
        //updateWatch(withAction: .AppContext)
    }
    
    public func updateSite(site: Site)  ->  Bool {
        
        var success = false
        
        if let index = sites.indexOf(site) {
            sites[index] = site
            success = true
        }
        
        transmitToWatch()
        //self.updateWatch(withAction: .AppContext)
        
        return success
    }
    
    public func deleteSiteAtIndex(index: Int) {
        sites.removeAtIndex(index)
        //updateWatch(withAction: .AppContext)
        transmitToWatch()
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
    func processApplicationContext(context: [String : AnyObject], replyHandler: (([String : AnyObject]) -> Void)? = nil) {
        print("processApplicationContext \(context)")
        
        if let defaults = context["defaults"] as? [String: AnyObject] {
            self.defaults.setObject(defaults, forKey: "watchDefaults")
            self.iCloudKeyStore.setObject(defaults, forKey: "watchDefaults")
        }
        
        if let uuidString = context[DefaultKey.defaultSiteKey] as? String {
            defaultSiteUUID = NSUUID(UUIDString: uuidString)
        }
        
        // check to see if an incomming action is available.
        guard let actionString = context[WatchModel.PropertyKey.actionKey] as? String, action = WatchAction(rawValue: actionString) else {
            print("No action was found, didReceiveMessage: \(context)")
            
            return
        }
        
        switch action {
        case .UpdateComplication:
            updateComplicationForDefaultSite(foreRrefresh: false, handler: { (site, error) in
                if let site = site {
                    
                    self.updateSite(site)
             
                    if let replyHandler = replyHandler {
                        replyHandler(self.genratePayloadForAction(action))
                    }
                }
            })
            
        default:
            generateData(forSites: self.sites, handler: { (updatedSites) in
                for site in updatedSites {
                    self.updateSite(site)
                }
                
                if let replyHandler = replyHandler {
                    replyHandler(self.genratePayloadForAction(action))
                }
            })
        }
        
    }
    
    private var currentPayload: [String: AnyObject] = [String: AnyObject]()
    
    let transmitToWatch = dispatch_debounce_block(4.0, block: {
        
        print("Throttle how many times we send to the watch... only send every \(4.0) seconds!!!!!!!!!")
        
//        let currentPayload = AppDataManageriOS.sharedInstance.currentPayload
        
//        guard let actionString = currentPayload[WatchModel.PropertyKey.actionKey] as? String, action = WatchAction(rawValue: actionString) else {
//            print("no action was found.")
//            return
//        }
//        
        if #available(iOSApplicationExtension 9.0, *) {
//            switch action {
//            case .UpdateComplication:
//                WatchSessionManager.sharedManager.transferCurrentComplicationUserInfo(currentPayload)
//                
//                return
//            default:
                WatchSessionManager.sharedManager.sendMessage(AppDataManageriOS.sharedInstance.genratePayloadForAction(), replyHandler: nil, errorHandler: { (error) in
                    print("Sending error: \(error)")
                    do {
                        print("Updating Application Context")
                        try WatchSessionManager.sharedManager.updateApplicationContext(AppDataManageriOS.sharedInstance.genratePayloadForAction())
                    } catch {
                        print("Couldn't update Application Context, transferCurrentComplicationUserInfo.")
                        
                        WatchSessionManager.sharedManager.transferCurrentComplicationUserInfo(AppDataManageriOS.sharedInstance.genratePayloadForAction(.UserInfo))
                    }
                })
                print("Update transferCurrentComplicationUserInfo.")
                // WatchSessionManager.sharedManager.transferCurrentComplicationUserInfo(AppDataManageriOS.sharedInstance.genratePayloadForAction(.UpdateComplication))
                
                return
            }
        
            
//        }
    })
    
    
    public func genratePayloadForAction(action: WatchAction = .AppContext) -> [String: AnyObject] {
        #if DEBUG
            print(">>> Entering \(#function) <<<")
            // print("Please \(action) the watch with the \(sites)")
        #endif
            // Create a generic context to transfer to the watch.
            var payload = [String: AnyObject]()
            // Tag the context with an action so that the watch can handle it if needed.
            // ["action" : "WatchAction.Create"] for example...
            payload[WatchModel.PropertyKey.actionKey] = action.rawValue
            // WatchOS connectivity doesn't like custom data types and complex properties. So bundle this up as an array of standard dictionaries.
            payload[WatchModel.PropertyKey.contextKey] = dictionaryOfDataSource
            
            currentPayload = payload
            
            return payload
    }
    
    
    // MARK: Complication Data Methods
    
    public func generateData(forSites sites: [Site], handler:(updatedSites: [Site])->Void) -> Void {
        
        let processingSiteDataGroup = dispatch_group_create()
        
        var updatedSites:[Site] = []
        
        sites.forEach { (siteToLoad) -> () in
            print("fetching for: \(siteToLoad.url)")
            
            if siteToLoad == self.defaultSite() {
                
                dispatch_group_enter(processingSiteDataGroup)
                self.updateComplicationForDefaultSite(foreRrefresh: true, handler: {returnedSite,_ in
                    // Completed complication data.
                    if let site = returnedSite  {
                        updatedSites.append(site)
                    }
                    dispatch_group_leave(processingSiteDataGroup)
                })
            } else {
                dispatch_group_enter(processingSiteDataGroup)
                quickFetch(siteToLoad, handler: { (site, error) -> Void in
                    updatedSites.append(site)
                    dispatch_group_leave(processingSiteDataGroup)
                })
            }
        }
        
        dispatch_group_notify(processingSiteDataGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)) {
            handler(updatedSites: updatedSites)
        }
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
        
        // transmitToWatch()
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