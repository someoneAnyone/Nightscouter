//
//  AppDataStore.swift
//  Nightscouter
//
//  Created by Peter Ina on 7/22/15.
//  Copyright (c) 2015 Peter Ina. All rights reserved.
//

import Foundation

class AppDataManager {
    
    var sites: [Site] = [Site]() {
        didSet {
            saveAppData()
        }
    }
    
    let sitesArrayObjectsKey = "userSites"
    let defaults = NSUserDefaults.standardUserDefaults()

    class var sharedInstance: AppDataManager {
        struct Static {
            static var onceToken: dispatch_once_t = 0
            static var instance: AppDataManager? = nil
        }
        dispatch_once(&Static.onceToken) {
            Static.instance = AppDataManager()
        }
        return Static.instance!
    }
    
    init() {

        /*
        if let arrayOfObjectsUnarchivedData = defaults.dataForKey(sitesArrayObjectsKey) {
            if let arrayOfObjectsUnarchived = NSKeyedUnarchiver.unarchiveObjectWithData(arrayOfObjectsUnarchivedData) as? [Site] {
                sites = arrayOfObjectsUnarchived
            }
        }
        */

        if let  sitesData = NSKeyedUnarchiver.unarchiveObjectWithFile(Site.ArchiveURL.path!) as? NSData {
            if let sitesArray = NSKeyedUnarchiver.unarchiveObjectWithData(sitesData) as? [Site] {
                sites = sitesArray
            }
        }
    }
    
    func saveAppData() {

        // write to disk
        let data =  NSKeyedArchiver.archivedDataWithRootObject(sites)
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(data, toFile: Site.ArchiveURL.path!)
        if !isSuccessfulSave {
            println("Failed to save sites...")
        }else{
            println("Successful save...")
        }
        
        // write to defaults
        /*
        var arrayOfObjects = [Site]()
        var arrayOfObjectsData = NSKeyedArchiver.archivedDataWithRootObject(sites)
        defaults.setObject(arrayOfObjectsData, forKey: sitesArrayObjectsKey)
        */
    }
    
    func addSite(site: Site, index: Int?) {
        if let indexOptional = index {
            if (sites.count >= indexOptional) {
                sites.insert(site, atIndex: indexOptional )
            }
        }else {
            sites.append(site)
        }
        
        saveAppData()
    }
    
    func deleteSiteAtIndex(index: Int) {
        sites.removeAtIndex(index)
        
        saveAppData()
    }

}