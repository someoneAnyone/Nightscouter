//
//  AppDataStore.swift
//  Nightscouter
//
//  Created by Peter Ina on 7/22/15.
//  Copyright (c) 2015 Peter Ina. All rights reserved.
//
import Foundation

public class AppDataManager: NSObject, BundleRepresentable {
    
    //    public struct SavedPropertyKey {
    //        public static let sitesArrayObjectsKey = "userSitesData"
    //        static let currentSiteIndexKey = "currentSiteIndex"
    //        static let shouldDisableIdleTimerKey = "shouldDisableIdleTimer"
    //    }
    
    public struct SharedAppGroupKey {
        static let NightscouterGroup = "group.com.nothingonline.nightscouter"
    }
    
    public let defaults = NSUserDefaults(suiteName: SharedAppGroupKey.NightscouterGroup)!
    
    // models are light-weight struct that have display worthy information.
    public var models: [WatchModel] = [] {
        didSet {
            #if DEBUG
                // print("sites has been set with: \(models)")
            #endif
            let dictArray = models.map( { $0.dictionary } )
            defaults.setObject(dictArray, forKey: DefaultKey.modelArrayObjectsKey)
            // defaults.synchronize()
        }
    }
    
    // Sites are containers of raw data...
    public var sites: [Site] = [] {
        didSet {
            #if DEBUG
                // print("sites has been set with: \(sites)")
            #endif
            
            // old data...
            let userSitesData =  NSKeyedArchiver.archivedDataWithRootObject(self.sites)
            defaults.setObject(userSitesData, forKey: DefaultKey.sitesArrayObjectsKey)
            // defaults.synchronize()
            
            models = sites.flatMap( { WatchModel(fromSite: $0) } )
        }
    }
    
    public var currentSiteIndex: Int {
        set {
            
            #if DEBUG
                // print("currentSiteIndex is: \(currentSiteIndex) and is changing to \(newValue)")
            #endif
            
            defaults.setInteger(newValue, forKey: DefaultKey.currentSiteIndexKey)
            // defaults.synchronize()
            
            updateWatch(withAction: .UserInfo, withSites: sites)
            
        }
        get {
            return defaults.integerForKey(DefaultKey.currentSiteIndexKey)
        }
    }
    
    public var shouldDisableIdleTimer: Bool {
        set {
            
            #if DEBUG
                // print("shouldDisableIdleTimer currently is: \(shouldDisableIdleTimer) and is changing to \(newValue)")
            #endif
            
            defaults.setBool(newValue, forKey: DefaultKey.shouldDisableIdleTimerKey)
            // defaults.synchronize()
        }
        get {
            return defaults.boolForKey(DefaultKey.shouldDisableIdleTimerKey)
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
        
        if let models = defaults.objectForKey(DefaultKey.modelArrayObjectsKey) as? [[String : AnyObject]] {
            sites = models.flatMap( { WatchModel(fromDictionary: $0)?.generateSite() } )
        }
        
        updateWatch(withAction: .UserInfo, withSites: sites)
    }
    
    public func addSite(site: Site, index: Int?) {
        if let indexOptional = index {
            if (sites.count >= indexOptional) {
                sites.insert(site, atIndex: indexOptional )
            }
        }else {
            sites.append(site)
        }
        
        updateWatch(withAction:.Create, withSites: [site])
    }
    
    public func updateSite(site: Site)  ->  Bool {
        if let index = sites.indexOf(site) {
            sites[index] = site
            updateWatch(withAction: .Update, withSites: [site])
            
            return true
        }
        
        return false
    }
    
    public func deleteSiteAtIndex(index: Int) {
        
        updateWatch(withAction: .Delete, withSites: [sites[index]])
        
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
    public func updateWatch(withAction action: WatchAction, withSites sites: [Site]) {
        #if DEBUG
            print(">>> Entering \(__FUNCTION__) <<<")
            // print("Please \(action) the watch with the \(sites)")
        #endif
        
        // Create a generic context to transfer to the watch.
        var context = [String: AnyObject]()
        
        // Tag the context with an action so that the watch can handle it if needed.
        // ["action" : "WatchAction.Create"] for example...
        context[WatchModel.PropertyKey.actionKey] = action.rawValue
        
        // WatchOS connectivity doesn't like custom data types and complex properties. So bundle this up as an array of standard dictionaries.
        let modelDictionaries:[[String: AnyObject]] = models.map( { $0.dictionary } )// sites.flatMap( { WatchModel(fromSite: $0)?.dictionary })
        context[WatchModel.PropertyKey.modelsKey] = modelDictionaries
        
        // Send over the current index.
        context[WatchModel.PropertyKey.currentIndexKey] = currentSiteIndex
        
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
                        WatchSessionManager.sharedManager.transferUserInfo(context)
                }
            }
            
        }
    }
}

extension AppDataManager {
    
    public func loadDataFor(site: Site, index: Int?, withChart: Bool = false, completetion:(returnedModel: WatchModel?, returnedSite: Site?, returnedIndex: Int?, returnedError: NSError?) -> Void) {
        // Start up the API
        let nsApi = NightscoutAPIClient(url: site.url)
        //TODO: 1. There should be reachabiltiy checks before doing anything.
        //TODO: 2. We should fail gracefully if things go wrong. Need to present a UI for reporting errors.
        //TODO: 3. Probably need to move this code to the application delegate?
        
        // Get settings for a given site.
        print("Loading data for \(site.url)")
        nsApi.fetchServerConfiguration { (result) -> Void in
            switch (result) {
            case let .Error(error):
                // display error message
                print("loadUpData ERROR recieved: \(error)")
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    site.disabled = true
                    completetion(returnedModel: nil, returnedSite: nil, returnedIndex: index, returnedError: error)
                })
                
            case let .Value(boxedConfiguration):
                let configuration:ServerConfiguration = boxedConfiguration.value
                // do something with user
                nsApi.fetchDataForWatchEntry({ (watchEntry, watchEntryErrorCode) -> Void in
                    // Get back on the main queue to update the user interface
                    site.configuration = configuration
                    site.watchEntry = watchEntry
                    
                    if !withChart {
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.updateSite(site)
                            completetion(returnedModel: WatchModel(fromSite: site), returnedSite: site, returnedIndex: index, returnedError: nil)
                        })
                    } else {
                        
                        nsApi.fetchDataForEntries(Constants.EntryCount.NumberForChart) { (entries, errorCode) -> Void in
                            if let entries = entries {
                                site.entries = entries
                                
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                    self.updateSite(site)
                                    completetion(returnedModel: WatchModel(fromSite: site), returnedSite: site, returnedIndex: index, returnedError: nil)
                                })
                            }
                        }
                    }
                })
            }
        }
        
    }
}