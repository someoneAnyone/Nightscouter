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
        
        //WatchSessionManager.sharedManager.requestLatestAppContext()
        updatePages()
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
        if !WatchSessionManager.sharedManager.requestLatestAppContext(watchAction: .AppContext) {
            for model in models {
                loadDataFor(model, replyHandler: { (model) -> Void in
//                    //..
                })
            }
        }
    }
    
    func updatePages() {
        print(">>> Entering \(__FUNCTION__) <<<")
        popToRootController()
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
            
            // MARK: Need a better experience for an empty experience....
            
            //            WKInterfaceController.reloadRootControllersWithNames(["empty"], contexts: [" "])
            
            //            NSOperationQueue.mainQueue().addOperationWithBlock {
            //                let alertMessage = "No sites were found."
            //                let okButtom = WKAlertAction(title: "Retry", style: WKAlertActionStyle.Default, handler: { () -> Void in
            //                    WatchSessionManager.sharedManager.requestLatestAppContext()
            //                })
            //                self.popToRootController()
            //
            //                // Or you can do it the old way
            //                let offset = 2.0
            //                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(offset * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), {
            //                    // Do something
            //                    self.presentAlertControllerWithTitle(alertMessage, message: "We didn't find any sites. You can try looking for sites again.", preferredStyle: WKAlertControllerStyle.Alert, actions: [okButtom])
            //
            //                })
            
            //            }
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
    
    func dataSourceDidAddSiteModel(model: WatchModel, atIndex index: Int) {
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
    @IBAction func updateButton() {
        updateData()
    }
}
