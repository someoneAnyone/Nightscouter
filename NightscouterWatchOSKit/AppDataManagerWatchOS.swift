//
//  AppDataManagerWatchOS.swift
//  Nightscouter
//
//  Created by Peter Ina on 12/7/15.
//  Copyright © 2015 Peter Ina. All rights reserved.
//

import Foundation

public class AppDataManager: NSObject {
    
    public struct SavedPropertyKey {
        public static let sitesArrayObjectsKey = "userSites"
        static let currentSiteIndexKey = "currentSiteIndex"
        static let shouldDisableIdleTimerKey = "shouldDisableIdleTimer"
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
    }
    
    public func loadDataFor(model: WatchModel, replyHandler:(model: WatchModel) -> Void) {
        print(">>> Entering \(__FUNCTION__) <<<")
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            // Start up the API
            let url = NSURL(string: model.urlString)!
            let site = Site(url: url, apiSecret: nil)!
            let nsApi = NightscoutAPIClient(url: site.url)
            if (model.lastReadingDate.timeIntervalSinceNow > Constants.StandardTimeFrame.TwoAndHalfMinutesInSeconds) {
                // Get settings for a given site.
                print("Loading data for \(site.url!)")
                nsApi.fetchServerConfiguration { (result) -> Void in
                    switch (result) {
                    case let .Error(error):
                        // display error message
                        print("\(__FUNCTION__) ERROR recieved: \(error)")
                    case let .Value(boxedConfiguration):
                        let configuration:ServerConfiguration = boxedConfiguration.value
                        // do something with user
                        nsApi.fetchDataForWatchEntry({ (watchEntry, watchEntryErrorCode) -> Void in
                            site.configuration = configuration
                            site.watchEntry = watchEntry
                            if let model = WatchModel(fromSite: site) {
                                replyHandler(model: model)
                            }
                        })
                    }
                }
            }
        }
    }
    
}