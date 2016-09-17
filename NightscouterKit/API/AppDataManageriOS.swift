//
//  AppDataStore.swift
//  Nightscouter
//
//  Created by Peter Ina on 7/22/15.
//  Copyright (c) 2015 Peter Ina. All rights reserved.
//
import Foundation


open class AppDataManageriOS: NSObject, BundleRepresentable {
    
    open var sites: [Site] = [] {
        didSet{
            let models: [[String : Any]] = sites.flatMap( { $0.viewModel.dictionary } )
            
            if models.isEmpty {
                defaultSiteUUID = nil
                currentSiteIndex = 0
                
                iCloudKeyStore.resetStorage()
            }
            
            defaults.set(models, forKey: DefaultKey.sites.rawValue)
            //defaults.synchronize()
            
            iCloudKeyStore.set(models, forKey: DefaultKey.sites.rawValue)
            iCloudKeyStore.synchronize()
        }
    }
    
    open var currentSiteIndex: Int {
        set{
            defaults.set(newValue, forKey: DefaultKey.lastViewedSiteIndex.rawValue)
            
            iCloudKeyStore.set(Int64(currentSiteIndex), forKey: DefaultKey.lastViewedSiteIndex.rawValue)
            iCloudKeyStore.synchronize()
        }
        get{
            return defaults.integer(forKey: DefaultKey.lastViewedSiteIndex.rawValue)
        }
    }
    
    open var defaultSiteUUID: UUID? {
        set{
            defaults.set(newValue?.uuidString, forKey: DefaultKey.primarySiteUUID.rawValue)
            
            iCloudKeyStore.set(defaultSiteUUID?.uuidString, forKey: DefaultKey.primarySiteUUID.rawValue)
            iCloudKeyStore.synchronize()
            
            updateComplicationForDefaultSite(foreRrefresh: true) { (returnedSite, _) in
                if let site = returnedSite  {
                    self.updateSite(site)
                    //self.updateWatch(withAction: .UpdateComplication)
                }
            }
        }
        get {
            if let uuidString = defaults.object(forKey: DefaultKey.primarySiteUUID.rawValue) as? String {
                return UUID(uuidString: uuidString)
            }
            return sites.first?.uuid as UUID?
        }
    }
    
    open func defaultSite() -> Site? {
        return self.sites.filter({ (site) -> Bool in
            return site.uuid as UUID == defaultSiteUUID!
        }).first
    }
    
    var dictionaryOfDataSource:[String: Any] {
        var dictionaryOfData = [String: Any]()
        dictionaryOfData[DefaultKey.sites.rawValue] = sites.flatMap( { $0.viewModel.dictionary } )
        dictionaryOfData[DefaultKey.lastViewedSiteIndex.rawValue] = currentSiteIndex as AnyObject?
        dictionaryOfData[DefaultKey.primarySiteUUID.rawValue] = defaultSiteUUID?.uuidString as AnyObject?
        
        return dictionaryOfData
    }
    
    
    public static let sharedInstance = AppDataManageriOS()
    
    fileprivate override init() {
        super.init()
        
        loadData()
    }
    
    deinit {
        saveData()
    }
    
    fileprivate struct SharedAppGroupKey {
        static let NightscouterGroup = "group.com.nothingonline.nightscouter"
    }
    
    open let defaults = UserDefaults(suiteName: SharedAppGroupKey.NightscouterGroup)!
    
    open let iCloudKeyStore = NSUbiquitousKeyValueStore.default()
    
    // MARK: Save and Load Data
    open func saveData() {
        
        let models: [[String : Any]] = sites.flatMap( { $0.viewModel.dictionary } )
        
        defaults.set(models, forKey: DefaultKey.sites.rawValue)
        defaults.set(currentSiteIndex, forKey: DefaultKey.lastViewedSiteIndex.rawValue)
        defaults.set("iOS", forKey: DefaultKey.osPlatform.rawValue)
        defaults.set(defaultSiteUUID?.uuidString, forKey: DefaultKey.primarySiteUUID.rawValue)
        
        // Save To iCloud
        iCloudKeyStore.set(currentSiteIndex, forKey: DefaultKey.lastViewedSiteIndex.rawValue)
        iCloudKeyStore.set(models, forKey: DefaultKey.sites.rawValue)
        iCloudKeyStore.set(defaultSiteUUID?.uuidString, forKey: DefaultKey.primarySiteUUID.rawValue)
        
        iCloudKeyStore.synchronize()
    }
    
    open func loadData() {
        
        if let models = defaults.array(forKey: DefaultKey.sites.rawValue) as? [[String : Any]] {
            sites = models.flatMap( { WatchModel(fromDictionary: $0)?.generateSite() } )
        }
        
        // Register for settings changes as store might have changed
        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(AppDataManageriOS.userDefaultsDidChange(_:)),
                         name: UserDefaults.didChangeNotification,
                         object: defaults)
        
        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(AppDataManageriOS.ubiquitousKeyValueStoreDidChange(_:)),
                         name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
                         object: iCloudKeyStore)
        
        iCloudKeyStore.synchronize()
    }
    
    
    // MARK: Data Source Managment
    open func addSite(_ site: Site, index: Int?) {
        guard let safeIndex = index , sites.count >= safeIndex else {
            sites.append(site)
            
            return
        }
        
        sites.insert(site, at: safeIndex)
        
        
        transmitToWatch()
        //updateWatch(withAction: .AppContext)
    }
    
    @discardableResult
    open func updateSite(_ site: Site) -> Bool {
        
        var success = false
        
        if let index = sites.index(of: site) {
            sites[index] = site
            success = true
        }
        
        transmitToWatch()
        //self.updateWatch(withAction: .AppContext)
        
        return success
    }
    
    open func deleteSiteAtIndex(_ index: Int) {
        sites.remove(at: index)
        //updateWatch(withAction: .AppContext)
        transmitToWatch()
    }
    
    
    // MARK: Demo Site
    fileprivate func loadSampleSites() -> Void {
        // Create a site URL.
        let demoSiteURL = URL(string: "https://nscgm.herokuapp.com")!
        // Create a site.
        let demoSite = Site(url: demoSiteURL, apiSecret: nil)!
        
        // Add it to the site Array
        sites = [demoSite]
    }
    
    
    // MARK: Supported URL Schemes
    open var supportedSchemes: [String]? {
        if let info = infoDictionary {
            var schemes = [String]() // Create an empty array we can later set append available schemes.
            if let bundleURLTypes = info["CFBundleURLTypes"] as? [AnyObject] {
                for (index, _) in bundleURLTypes.enumerated() {
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
    func processApplicationContext(_ context: [String : Any], replyHandler: (([String : Any]) -> Void)? = nil) {
        print("processApplicationContext \(context)")
        
        if let defaults = context["defaults"] as? [String: AnyObject] {
            self.defaults.set(defaults, forKey: "watchDefaults")
            self.iCloudKeyStore.set(defaults, forKey: "watchDefaults")
        }
        
        if let uuidString = context[DefaultKey.primarySiteUUID.rawValue] as? String {
            defaultSiteUUID = UUID(uuidString: uuidString)
        }
        
        // check to see if an incomming action is available.
        guard let actionString = context[WatchModel.PropertyKey.actionKey] as? String, let action = WatchAction(rawValue: actionString) else {
            print("No action was found, didReceiveMessage: \(context)")
            
            return
        }
        
        switch action {
        case .UpdateComplication:
            updateComplicationForDefaultSite(foreRrefresh: false, handler: { (site, error) in
                if let site = site {
                    
                    self.updateSite(site)
                    
                    if let replyHandler = replyHandler {
                        replyHandler(self.generatePayloadForAction(action))
                    }
                }
            })
            
        default:
            generateData(forSites: self.sites, handler: { (updatedSites) in
                for site in updatedSites {
                    self.updateSite(site)
                }
                
                if let replyHandler = replyHandler {
                    replyHandler(self.generatePayloadForAction(action))
                }
            })
        }
        
    }
    
    let transmitToWatch = debounce(delay: 4, action: {
        
        print("Throttle how many times we send to the watch... only send every \(4.0) seconds!!!!!!!!!")
        
        WatchSessionManager.sharedManager.sendMessage(AppDataManageriOS.sharedInstance.generatePayloadForAction(), replyHandler: nil, errorHandler: { (error) in
            print("Sending error: \(error)")
            do {
                print("Updating Application Context")
                try WatchSessionManager.sharedManager.updateApplicationContext(AppDataManageriOS.sharedInstance.generatePayloadForAction())
            } catch let exception {
                print("Exception when updating application context", exception)
            }
        })
    })
    
    open func generatePayloadForAction(_ action: WatchAction = .AppContext) -> [String: Any] {
        #if DEBUG
            print(">>> Entering \(#function) <<<")
            // print("Please \(action) the watch with the \(sites)")
        #endif
        // Create a generic context to transfer to the watch.
        var payload = [String: Any]()
        // Tag the context with an action so that the watch can handle it if needed.
        // ["action" : "WatchAction.Create"] for example...
        payload[WatchModel.PropertyKey.actionKey] = action.rawValue
        // WatchOS connectivity doesn't like custom data types and complex properties. So bundle this up as an array of standard dictionaries.
        payload[WatchModel.PropertyKey.contextKey] = dictionaryOfDataSource
        return payload
    }
    
    
    // MARK: Complication Data Methods
    
    open func generateData(forSites sites: [Site], handler:@escaping (_ updatedSites: [Site])->Void) -> Void {
        
        let processingSiteDataGroup = DispatchGroup()
        
        var updatedSites:[Site] = []
        
        sites.forEach { (siteToLoad) -> () in
            print("fetching for: \(siteToLoad.url)")
            
            if siteToLoad == self.defaultSite() {
                
                processingSiteDataGroup.enter()
                self.updateComplicationForDefaultSite(foreRrefresh: true, handler: {returnedSite,_ in
                    // Completed complication data.
                    if let site = returnedSite  {
                        updatedSites.append(site)
                    }
                    processingSiteDataGroup.leave()
                })
            } else {
                processingSiteDataGroup.enter()
                quickFetch(siteToLoad, handler: { (site, error) -> Void in
                    updatedSites.append(site)
                    processingSiteDataGroup.leave()
                })
            }
        }
        
        processingSiteDataGroup.notify(queue: .global()) {//.notify(queue: DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.low)) {
            handler(updatedSites)
        }
    }
    
    /*
     Generates data for a comnpication but does not transmitt it to the watch or update the data store.
     */
    open func updateComplicationForDefaultSite(foreRrefresh force: Bool = false, handler:@escaping (_ site: Site?, _ error: NightscoutAPIError)-> Void) {
        print(#function)
        guard let siteToLoad = self.defaultSite() else {
            handler(nil, NightscoutAPIError.dataError("No default site was found."))
            return
        }
        
        if (siteToLoad.lastConnectedDate?.compare(siteToLoad.nextRefreshDate as Date) == .orderedDescending || siteToLoad.configuration == nil || force == true) {
            print("START:   iOS is updating complication data for \(siteToLoad.url)")
            fetchSiteData(siteToLoad, handler: { (returnedSite, error) -> Void in
                print("COMPLETE:   iOS has updated complication data for \(siteToLoad.url)")
                handler(returnedSite, error)
                return
            })
        } else {
            handler(siteToLoad, NightscoutAPIError.noError)
            return
        }
    }
    
    
    // MARK: Storage Updates
    
    // MARK: Defaults have Changed
    let postNotification = debounce(delay: 1) { 
            //dispatch_debounce_block(1.0)
        //            NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
        print("Posting: AppDataManagerDidChangeNotification")
        NotificationCenter.default.post(name: Notification.Name(rawValue: AppDataManagerDidChangeNotification), object: AppDataManageriOS.sharedInstance
            .sites)
        //            }
    }
    
    func userDefaultsDidChange(_ notification: Notification) {
        print("userDefaultsDidChange:")
        
        // guard let defaultObject = notification.object as? NSUserDefaults else { return }
        
        postNotification()
        // transmitToWatch()
    }
    
    // MARK: iCloud Key Store Changed
    
    func ubiquitousKeyValueStoreDidChange(_ notification: Notification) {
        print("ubiquitousKeyValueStoreDidChange:")
        
        guard let userInfo = (notification as NSNotification).userInfo as? [String: AnyObject], let changeReason = userInfo[NSUbiquitousKeyValueStoreChangeReasonKey] as? NSNumber else {
            return
        }
        
        let reason = changeReason.intValue
        
        if (reason == NSUbiquitousKeyValueStoreServerChange || reason == NSUbiquitousKeyValueStoreInitialSyncChange) {
            let changedKeys = userInfo[NSUbiquitousKeyValueStoreChangedKeysKey] as! [String]
         
            let store = NSUbiquitousKeyValueStore.default()
            
            for key in changedKeys {
                
                // Update Data Source
                
                if key == DefaultKey.sites.rawValue {
                    if let models = store.array(forKey: DefaultKey.sites.rawValue) as? [[String : Any]] {
                        sites = models.flatMap( { WatchModel(fromDictionary: $0)?.generateSite() } )
                    }
                }
                
                if key == DefaultKey.lastViewedSiteIndex.rawValue {
                    currentSiteIndex = Int(store.longLong(forKey: DefaultKey.lastViewedSiteIndex.rawValue))
                }
                
                if key == DefaultKey.primarySiteUUID.rawValue {
                    print("defaultSiteUUID: " + key)
                }
            }
        }
    }
    
}
