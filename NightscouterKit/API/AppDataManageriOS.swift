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
            
            let models: [[String : AnyObject]] = sites.flatMap( { WatchModel(fromSite: $0).dictionary } )
            defaults.setObject(models, forKey: DefaultKey.modelArrayObjectsKey)
            
            updateWatch(withAction: .UserInfo, withSites: self.sites)
            
            
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
            createComplicationData()
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
        
        updateWatch(withAction: .UserInfo, withSites: sites)
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
        let modelDictionaries:[[String: AnyObject]] = sites.flatMap( { WatchModel(fromSite: $0).dictionary })
        context[WatchModel.PropertyKey.modelsKey] = modelDictionaries
        
        // Send over the current index.
        context[WatchModel.PropertyKey.currentIndexKey] = currentSiteIndex
        
        //context["cModels"] = complicationDataDictoinary
        
        context["defaultSite"] = defaultSite?.UUIDString
        
        if #available(iOSApplicationExtension 9.0, *) {
            switch action {
            case .UpdateComplication:
                WatchSessionManager.sharedManager.transferCurrentComplicationUserInfo(context)
            default:
                if WatchSessionManager.sharedManager.validReachableSession?.reachable == true {
                    WatchSessionManager.sharedManager.sendMessage(context, replyHandler: { (reply) -> Void in
                        print("recieved reply: \(reply)")
                        }) { (error) -> Void in
                            print("recieved an error: \(error)")
                            WatchSessionManager.sharedManager.transferUserInfo(context)
                    }
                } else {
                    WatchSessionManager.sharedManager.transferUserInfo(context)
                }
            }
            
        }
    }
    
    public func siteForComplication() -> Site? {
        return self.sites.filter({ (model) -> Bool in
            return model.uuid == defaultSite
        }).first
    }
    
    public func createComplicationData() -> Void {
        if let site = siteForComplication() {
            let nsApi = NightscoutAPIClient(url: site.url)
            
            loadDataFor(site, index: nil, withChart: true, completetion: { (returnedModel, returnedSite, returnedIndex, returnedError) -> Void in
                
                
                guard let newSite = returnedSite else {
                    return
                }
                
                nsApi.fetchCalibrations(10, completetion: { (calibrations, errorCode) -> Void in
                    
                    self.updateSite(newSite)
                    
                    
                    let models = generateComplicationModels(forSite: site, calibrations: calibrations?.flatMap{ $0.cal } ?? [])
                    
                    var calModels: [[String: AnyObject]] = []
                    if let cals = calibrations {
                        
                        let calibrations = cals.sort{(item1:Entry, item2:Entry) -> Bool in
                            item1.date.compare(item2.date) == NSComparisonResult.OrderedDescending
                        }
                        
                        calModels = calibrations.flatMap { $0.cal?.dictionary }
                    }
                    
                    self.defaults.setObject(calModels, forKey: "calibrations")
                    self.complicationDataDictoinary = models.flatMap { $0.dictionary }
                    
                })
            })
            
        }
    }
    
    public var complicationDataFromDefaults: [ComplicationModel] {
        
        var complicationModels = [ComplicationModel]()
        for d in complicationDataDictoinary {
            
            if let complication = ComplicationModel(fromDictionary: d) {
                complicationModels.append(complication)
            }
        }
        
        return complicationModels
    }
    
    public var complicationDataDictoinary: [[String: AnyObject]] {
        set{
            defaults.setObject(newValue, forKey: "cModels")
            
            let now = NSDate()
            
            if let lastUpdateDate = defaults.objectForKey("complicationTimeStamp") as? NSDate {
                
                if lastUpdateDate.timeIntervalSinceDate(now) < -400 {
                    updateWatch(withAction: .UpdateComplication, withSites: sites)
                    
                }
                defaults.setObject(now, forKey: "complicationTimeStamp")

            }
            
            
            
            
        }
        get {
            guard let complicationDictArray = defaults.arrayForKey("cModels") as? [[String : AnyObject]] else {
                return []
            }
            return complicationDictArray
        }
    }
}