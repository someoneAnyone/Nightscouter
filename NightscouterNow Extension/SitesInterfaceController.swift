//
//  SitesInterfaceController.swift
//  Nightscouter
//
//  Created by Peter Ina on 11/8/15.
//  Copyright © 2015 Peter Ina. All rights reserved.
//

import WatchKit
import Foundation
import NightscouterWatchOSKit

class SitesInterfaceController: WKInterfaceController, DataSourceChangedDelegate {
    
    var models: [WatchModel] = [] {
        didSet{
            print("models did set in PageController")
            updatePages()
        }
    }
    
    private var names: [String] = []
    
    override func willActivate() {
        super.willActivate()
        
        WatchSessionManager.sharedManager.addDataSourceChangedDelegate(self)
        setupNotifications()
        
        WatchSessionManager.sharedManager.requestLatestAppContext()

        
        //        if models.isEmpty {
        //            if let dictArray = NSUserDefaults.standardUserDefaults().objectForKey(WatchModel.PropertyKey.modelsKey) as? [[String: AnyObject]] {
        //                print("Loading models from default.")
        //                models = dictArray.map({ WatchModel(fromDictionary: $0)! })
        //            }
        
        updatePages()
        //        }
    }
    
    func setupNotifications() {
        // Listen for global update timer.
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateData", name: NightscoutAPIClientNotification.DataIsStaleUpdateNow, object: nil)
    }
    
    deinit {
        // Remove this class from the observer list. Was listening for a global update timer.
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    
    func updateData() {
        print(">>> Entering \(__FUNCTION__) <<<")
        WatchSessionManager.sharedManager.requestLatestAppContext()
        
        for (index, model) in models.enumerate() {
            let url = NSURL(string: model.urlString)!
            let site = Site(url: url, apiSecret: nil)!
            
            WatchSessionManager.sharedManager.loadDataFor(site, index: index, lastUpdateDate: model.lastReadingDate)
        }
        
        //        let dictArray = models.map({ $0.dictionary })
        //        NSUserDefaults.standardUserDefaults().setObject(dictArray, forKey: WatchModel.PropertyKey.modelsKey)
        //        NSUserDefaults.standardUserDefaults().removeObjectForKey(WatchModel.PropertyKey.modelsKey)
        //        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    func updatePages() {
        print(">>> Entering \(__FUNCTION__) <<<")
        
        names.removeAll()
        for _ in (0..<models.count) {
            names.append("SiteDetail")
        }
        if !models.isEmpty {
            NSOperationQueue.mainQueue().addOperationWithBlock {
                print(">>> Entering \(__FUNCTION__) <<<")
                
                // pushControllerWithName("SiteDetail", context: [WatchModel.PropertyKey.delegateKey: self, WatchModel.PropertyKey.modelKey: model.dictionary])
                
                let modelDicts = self.models.map({ [WatchModel.PropertyKey.modelKey : $0.dictionary] })
                self.animateWithDuration(0.2) { () -> Void in
                    WKInterfaceController.reloadRootControllersWithNames(self.names, contexts: modelDicts)
                }
            }
        } else {
            popController()
        }
    }
    
    func dataSourceDidUpdateSiteModel(model: WatchModel, atIndex index: Int) {
        print(">>> Entering \(__FUNCTION__) <<<")
        models[index] = model
    }
    
    func dataSourceDidDeleteSiteModel(model: WatchModel, atIndex index: Int) {
        print(">>> Entering \(__FUNCTION__) <<<")
        models.removeAtIndex(index)
        updatePages()
    }
    
    func dataSourceDidAddSiteModel(model: WatchModel) {
        print(">>> Entering \(__FUNCTION__) <<<")
        
        if let modelIndex = models.indexOf(model){
            models[modelIndex] = model
        } else {
            models.insert(model, atIndex: 0)//(model)
        }
    }
    
    func dataSourceDidUpdateAppContext(models: [WatchModel]) {
        self.models = models
    }
    
    func didUpdateItem(site: Site, withModel model: WatchModel) {
        
        print(">>> Entering \(__FUNCTION__) <<<")
        
        if let index = self.models.indexOf(model) {
            self.models[index] = model
        } else {
            print("Did not update table view with recent item")
        }
    }
    
}
