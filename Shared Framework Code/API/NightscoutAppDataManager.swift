//
//  NightscoutAppDataManager.swift
//  Nightscouter
//
//  Created by Peter Ina on 12/16/15.
//  Copyright © 2015 Peter Ina. All rights reserved.
//

import Foundation

//public protocol ApplicationDataManageable {
//
//    var defaults: NSUserDefaults { get }
//
//    var models: [WatchModel] { get }
//
//    var sites: [Site] { get }
//
//    var currentSiteIndex: Int { get set }
//
//    var shouldDisableIdleTimer: Bool { get set }
//
//    func addSite(site: Site, index: Int?)
//
//    func updateSite(site: Site) -> Bool
//
//    func deleteSiteAtIndex(index: Int)
//
//    func loadSampleSites()
//
//
//    func loadDataFor(site: Site, index: Int?, withChart: Bool?, completetion: (returnedModel: WatchModel?, returnedSite: Site?, returnedIndex: Int?, returnedError: NSError?) -> Void)
//}
//
//
//extension ApplicationDataManageable {
//
//    var NightscouterGroup: String {
//        return "group.com.nothingonline.nightscouter"
//}
//
//
//    public var defaults: NSUserDefaults {
//     return NSUserDefaults(suiteName: NightscouterGroup)!
//    }
//
//
//}



public func loadDataFor(model: WatchModel, replyHandler:(model: WatchModel) -> Void) {
    print(">>> Entering \(__FUNCTION__) <<<")
    
    // Start up the API
    let url = NSURL(string: model.urlString)!
    let site = Site(url: url, apiSecret: nil)!
    
    loadDataFor(site, index: nil) { (returnedModel, returnedSite, returnedIndex, returnedError) -> Void in
        
        guard let model = returnedModel else {
            return
        }
        
        replyHandler(model: model)
    }
}


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
                        //                            self.updateSite(site)
                        completetion(returnedModel: WatchModel(fromSite: site), returnedSite: site, returnedIndex: index, returnedError: nil)
                    })
                } else {
                    
                    nsApi.fetchDataForEntries(Constants.EntryCount.NumberForChart) { (entries, errorCode) -> Void in
                        if let entries = entries {
                            site.entries = entries
                            
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                completetion(returnedModel: WatchModel(fromSite: site), returnedSite: site, returnedIndex: index, returnedError: nil)
                            })
                        }
                    }
                }
            })
        }
    }
    
}
