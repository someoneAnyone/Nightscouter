//
//  SitesTableInterfaceController.swift
//  Nightscouter
//
//  Created by Peter Ina on 10/4/15.
//  Copyright © 2015 Peter Ina. All rights reserved.
//

import WatchKit
import NightscouterWatchOSKit

class SitesTableInterfaceController: WKInterfaceController, DataSourceChangedDelegate, SiteDetailViewDidUpdateItemDelegate {
    
    @IBOutlet var sitesTable: WKInterfaceTable!
    
    var models = [WatchModel]() {
        didSet {
            updateTableData()
            if !models.isEmpty {
                updateData(false)
                //WKInterfaceDevice.currentDevice().playHaptic(.Success)
            }
            
        }
    }
    
    var delayTimer = NSTimer()
    var delayRequestForNow: Bool = false {
        didSet {
            delayTimer.invalidate()
            if delayRequestForNow {
                delayTimer = NSTimer.scheduledTimerWithTimeInterval(Constants.NotableTime.StandardRefreshTime, target: self, selector: Selector("updateData"), userInfo: "timer", repeats: true)
            }
        }
    }
    
    var nsApi: [NightscoutAPIClient]?
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        print(">>> Entering \(__FUNCTION__) <<<")
    }
    
    override func willActivate() {
        super.willActivate()
        print(">>> Entering \(__FUNCTION__) <<<")
        
        setupNotifications()
        models = WatchSessionManager.sharedManager.models
        
        WatchSessionManager.sharedManager.addDataSourceChangedDelegate(self)
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        print(">>> Entering \(__FUNCTION__) <<<")
        super.didDeactivate()
        
        WatchSessionManager.sharedManager.removeDataSourceChangedDelegate(self)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func setupNotifications() {
        // Listen for global update timer.
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("dataStaleUpdate:"), name: NightscoutAPIClientNotification.DataIsStaleUpdateNow, object: nil)
    }
    
    override func table(table: WKInterfaceTable, didSelectRowAtIndex rowIndex: Int) {
        // create object.
        // push controller...
        print(">>> Entering \(__FUNCTION__) <<<")
        let model = models[rowIndex]
        
        pushControllerWithName("SiteDetail", context: [WatchModel.PropertyKey.delegateKey: self, WatchModel.PropertyKey.modelKey: model.dictionary])
    }
    
    private func updateTableData() {
        
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            
            print(">>> Entering \(__FUNCTION__) <<<")
            
            let rowTypeIdentifier: String = "SiteRowController"
            print("models.count = \(self.models.count)")
            
            if self.models.isEmpty {
                self.sitesTable.setNumberOfRows(1, withRowType: "SiteEmptyRowController")
                let row = self.sitesTable.rowControllerAtIndex(0) as? SiteEmptyRowController
                if let row = row {
                    row.messageLabel.setText("No sites availble.")
                }
                
            } else {
                self.sitesTable.setNumberOfRows(self.models.count, withRowType: rowTypeIdentifier)
                for (index, model) in self.models.enumerate() {
                    if let row = self.sitesTable.rowControllerAtIndex(index) as? SiteRowController {
                        row.model = model
                    }
                }
                
            }
            
        }
    }
    
    
    func dataSourceDidUpdateSiteModel(model: WatchModel, atIndex index: Int) {
        print(">>> Entering \(__FUNCTION__) <<<")
        
        self.delayRequestForNow = model.warn
        
        ComplicationController.reloadComplications()
        
        models[index] = model
    }

    func dataSourceDidUpdateAppContext(models: [WatchModel]) {
        self.models = models
    }
    
    func didUpdateItem(model: WatchModel) {
        print(">>> Entering \(__FUNCTION__) <<<")
        
        if let index = models.indexOf(model) {
            self.models[index] = model
        } else {
            print("Did not update table view with recent item")
        }
    }
    
    func dataStaleUpdate(notif: NSNotification) {
        updateData(true)
    }
    
    func updateData(forceRefresh: Bool = true) {
        print(">>> Entering \(__FUNCTION__) <<<")
        
        for (index, model) in models.enumerate() {
            if (model.lastReadingDate.timeIntervalSinceNow < Constants.NotableTime.StandardRefreshTime.inThePast && !delayRequestForNow) || forceRefresh {
                loadDataFor(model, replyHandler: { (model) -> Void in
                    self.dataSourceDidUpdateSiteModel(model, atIndex: index)
                })
            }
        }
    }
    
    @IBAction func updateButton() {
        updateData()
    }
    
    override func handleUserActivity(userInfo: [NSObject : AnyObject]?) {
        print(">>> Entering \(__FUNCTION__) <<<")
        
        guard let dict = userInfo?["model"] as? [String : AnyObject], incomingModel = WatchModel (fromDictionary: dict) else {
            return
        }
        NSOperationQueue.mainQueue().addOperationWithBlock {
            self.pushControllerWithName("SiteDetail", context: [WatchModel.PropertyKey.delegateKey: self, WatchModel.PropertyKey.modelKey: incomingModel.dictionary])
        }
    }
}

