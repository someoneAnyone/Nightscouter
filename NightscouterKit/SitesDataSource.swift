//
//  SitesDataSource.swift
//  Nightscouter
//
//  Created by Peter Ina on 9/2/16.
//  Copyright © 2016 Peter Ina. All rights reserved.
//


//private struct SharedAppGroupKey {
//    static let NightscouterGroup = "group.com.nothingonline.nightscouter"
//}
//
//public let defaults = NSUserDefaults(suiteName: SharedAppGroupKey.NightscouterGroup)!


import Foundation

public typealias ArrayOfDictionaries = [[String: AnyObject]]


public class SitesDataSource: SiteStoreType {
    
    public static let sharedInstance = SitesDataSource()
    
    // MARK: - Private iVars
    
    private init() {
        
        defaults = NSUserDefaults.standardUserDefaults()
    }
    
    private let defaults: NSUserDefaults
    
    private var sessionManagers: [SessionManagerType] = []
    
    public var storageLocation: StorageLocation { return .localKeyValueStore }
    
    public var otherStorageLocations: SiteStoreType?
    
    public var sites: [Site] {
        if let loadedSites = loadData() {
            return loadedSites
        }
        return []
    }
    
    public var lastViewedSiteIndex: Int {
        get {
            return defaults.objectForKey(DefaultKey.lastViewedSiteIndex.rawValue) as? Int ?? 0
        }
        set {
            if lastViewedSiteIndex != newValue {
                save(data: [DefaultKey.lastViewedSiteIndex.rawValue: newValue])
            }
        }
    }
    
    public var primarySiteUUID: NSUUID? {
        set{
            if let uuid = newValue {
                save(data: [DefaultKey.primarySiteUUID.rawValue: uuid.UUIDString])
            }
        }
        get {
            guard let uuidString = defaults.objectForKey(DefaultKey.primarySiteUUID.rawValue) as? String, let uuid = NSUUID(UUIDString: uuidString) else {
                return nil
            }
            return uuid
        }
    }

    
    public func create(site site: Site, atIndex index: Int?) -> Bool {
        var initial: [Site] = self.sites
        
        if initial.isEmpty {
            primarySiteUUID = site.uuid
        }
        
        if let index = index {
            initial.insert(site, atIndex: index)
        } else {
            initial.append(site)
        }
        
        let siteDict = initial.map { $0.viewModel.dictionary }
        
        save(data: [DefaultKey.sites.rawValue: siteDict])
        
        return initial.contains(site)
    }
    
    public func update(site site: Site) -> Bool {
        var initial = sites
        
        let success = initial.insertOrUpdate(site)
        
        let siteDict = initial.map { $0.viewModel.dictionary }
        
        save(data: [DefaultKey.sites.rawValue: siteDict])
        
        return success
    }
    
    public func delete(site site: Site) -> Bool {
        var initial = sites
        
        let success = initial.remove(object: site)
        
        //AppConfiguration.keychain[site.uuid.UUIDString] = nil
        
        if site == lastViewedSite {
            lastViewedSiteIndex = 0
        }
        
        if sites.isEmpty {
            lastViewedSiteIndex = 0
            primarySiteUUID = nil
        }
        
        let siteDict = initial.map { $0.viewModel.dictionary }
        save(data:[DefaultKey.sites.rawValue: siteDict])
        
        return success
    }
    
    
    public func handle(applicationContextPayload payload: [String : AnyObject]) {
        
        if let sites = payload[DefaultKey.sites.rawValue] as? ArrayOfDictionaries {
            defaults.setObject(sites, forKey: DefaultKey.sites.rawValue)
        } else {
            print("No sites were found.")
        }
        
        if let lastViewedSiteIndex = payload[DefaultKey.lastViewedSiteIndex.rawValue] as? Int {
            self.lastViewedSiteIndex = lastViewedSiteIndex
        } else {
            print("No lastViewedIndex was found.")
        }
        
        if let uuidString = payload[DefaultKey.primarySiteUUID.rawValue] as? String {
            self.primarySiteUUID = sites.filter{ $0.uuid.UUIDString == uuidString }.first!.uuid
        } else {
            print("No primarySiteUUID was found.")
        }
        
        #if os(watchOS)
            if let lastDataUpdateDateFromPhone = payload[DefaultKey.lastDataUpdateDateFromPhone.rawValue] as? NSDate {
                //defaults.setObject(lastDataUpdateDateFromPhone,forKey: DefaultKey.lastDataUpdateDateFromPhone.rawValue)
                print(lastDataUpdateDateFromPhone)
            }
        #endif
        
        if let action = payload[DefaultKey.action.rawValue] as? String {
            if action == DefaultKey.updateData.rawValue {
                print("found an action: \(action)")
                //for site in sites {
                    #if os(iOS)

                    #endif
               //}
            } else if action == DefaultKey.error.rawValue {
                print("Received an error.")
                
            } else {
                print("Did not find an action.")
            }
        }
        
        defaults.synchronize()
        //NSNotificationCenter.defaultCenter().postNotificationName(NightscoutAPIClientNotification.DataUpdateSuccessful, object: nil)
    }
    
    public func loadData() -> [Site]? {
        guard let sites = defaults.arrayForKey(DefaultKey.sites.rawValue) as? ArrayOfDictionaries else {
            return []
        }
        
        return sites.flatMap { WatchModel(fromDictionary: $0)?.generateSite() }
    }
    
    public func save(data dictionary: [String : AnyObject]) -> (savedLocally: Bool, updatedApplicationContext: Bool) {
        
        var dictionaryToSend = dictionary

        var successfullSave: Bool = false
        var successfullAppContextUpdate = false

        for (key, object) in dictionaryToSend {
            defaults.setObject(object, forKey: key)
        }

        dictionaryToSend[DefaultKey.lastDataUpdateDateFromPhone.rawValue] = NSDate()
        
        successfullSave = defaults.synchronize()
        
        sessionManagers.forEach { manager in
            do {
                try manager.update(applicationContext: dictionaryToSend)
                successfullAppContextUpdate = true
            } catch {
                successfullAppContextUpdate = false
                fatalError("Something didn't go right, create a fix.")
            }
        }

        return (successfullSave, successfullAppContextUpdate)
    }
    
    public func clearAllSites() -> Bool {
        var currentSites = sites
        currentSites.removeAll()
        save(data: [DefaultKey.sites.rawValue: []])
        return currentSites.isEmpty
    }
}