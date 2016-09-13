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

open class SitesDataSource: SiteStoreType {
    
    open static let sharedInstance = SitesDataSource()
    
    // MARK: - Private iVars
    
    fileprivate init() {
        
        defaults = UserDefaults.standard
    }
    
    fileprivate let defaults: UserDefaults
    
    fileprivate var sessionManagers: [SessionManagerType] = []
    
    open var storageLocation: StorageLocation { return .localKeyValueStore }
    
    open var otherStorageLocations: SiteStoreType?
    
    open var sites: [Site] {
        if let loadedSites = loadData() {
            return loadedSites
        }
        return []
    }
    
    open var lastViewedSiteIndex: Int {
        get {
            return defaults.object(forKey: DefaultKey.lastViewedSiteIndex.rawValue) as? Int ?? 0
        }
        set {
            if lastViewedSiteIndex != newValue {
                save(data: [DefaultKey.lastViewedSiteIndex.rawValue: newValue as Any])
            }
        }
    }
    
    open var primarySiteUUID: UUID? {
        set{
            if let uuid = newValue {
                save(data: [DefaultKey.primarySiteUUID.rawValue: uuid.uuidString as Any])
            }
        }
        get {
            guard let uuidString = defaults.object(forKey: DefaultKey.primarySiteUUID.rawValue) as? String, let uuid = UUID(uuidString: uuidString) else {
                return nil
            }
            return uuid
        }
    }

    
    open func create(site: Site, atIndex index: Int?) -> Bool {
        var initial: [Site] = self.sites
        
        if initial.isEmpty {
            primarySiteUUID = site.uuid as UUID
        }
        
        if let index = index {
            initial.insert(site, at: index)
        } else {
            initial.append(site)
        }
        
        let siteDict = initial.map { $0.viewModel.dictionary }
        
        save(data: [DefaultKey.sites.rawValue: siteDict as Any])
        
        return initial.contains(site)
    }
    
    open func update(site: Site) -> Bool {
        var initial = sites
        
        let success = initial.insertOrUpdate(site)
        
        let siteDict = initial.map { $0.viewModel.dictionary }
        
        save(data: [DefaultKey.sites.rawValue: siteDict as Any])
        
        return success
    }
    
    open func delete(site: Site) -> Bool {
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
        save(data:[DefaultKey.sites.rawValue: siteDict as Any])
        
        return success
    }
    
    
    open func handle(applicationContextPayload payload: [String : AnyObject]) {
        
        if let sites = payload[DefaultKey.sites.rawValue] as? ArrayOfDictionaries {
            defaults.set(sites, forKey: DefaultKey.sites.rawValue)
        } else {
            print("No sites were found.")
        }
        
        if let lastViewedSiteIndex = payload[DefaultKey.lastViewedSiteIndex.rawValue] as? Int {
            self.lastViewedSiteIndex = lastViewedSiteIndex
        } else {
            print("No lastViewedIndex was found.")
        }
        
        if let uuidString = payload[DefaultKey.primarySiteUUID.rawValue] as? String {
            self.primarySiteUUID = sites.filter{ $0.uuid.uuidString == uuidString }.first!.uuid as UUID
        } else {
            print("No primarySiteUUID was found.")
        }
        
        #if os(watchOS)
            if let lastDataUpdateDateFromPhone = payload[DefaultKey.lastDataUpdateDateFromPhone.rawValue] as? Date {
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
    
    open func loadData() -> [Site]? {
        guard let sites = defaults.array(forKey: DefaultKey.sites.rawValue) as? ArrayOfDictionaries else {
            return []
        }
        
        return sites.flatMap { WatchModel(fromDictionary: $0)?.generateSite() }
    }
    
    open func save(data dictionary: [String : Any]) -> (savedLocally: Bool, updatedApplicationContext: Bool) {
        
        var dictionaryToSend = dictionary

        var successfullSave: Bool = false
        var successfullAppContextUpdate = false

        for (key, object) in dictionaryToSend {
            defaults.set(object, forKey: key)
        }

        dictionaryToSend[DefaultKey.lastDataUpdateDateFromPhone.rawValue] = Date() as AnyObject?
        
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
    
    open func clearAllSites() -> Bool {
        var currentSites = sites
        currentSites.removeAll()
        save(data: [DefaultKey.sites.rawValue: []])
        return currentSites.isEmpty
    }
}
