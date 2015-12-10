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
            NSOperationQueue.mainQueue().addOperationWithBlock {
                self.updateTableData()
            }
            updateData()
        }
        
    }
    
    var lastUpdatedTime: NSDate?
    var nsApi: [NightscoutAPIClient]?
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        print(">>> Entering \(__FUNCTION__) <<<")
    }
    
    
    override func willActivate() {
        super.willActivate()
        
        WatchSessionManager.sharedManager.addDataSourceChangedDelegate(self)
        setupNotifications()
        
        WatchSessionManager.sharedManager.requestLatestAppContext()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        print(">>> Entering \(__FUNCTION__) <<<")
        super.didDeactivate()
    }
    
    override func willDisappear() {
        super.willDisappear()
        print(">>> Entering \(__FUNCTION__) <<<")
        
        WatchSessionManager.sharedManager.removeDataSourceChangedDelegate(self)
    }
    
    func setupNotifications() {
        // Listen for global update timer.
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateData", name: NightscoutAPIClientNotification.DataIsStaleUpdateNow, object: nil)
    }
    
    deinit {
        // Remove this class from the observer list. Was listening for a global update timer.
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func table(table: WKInterfaceTable, didSelectRowAtIndex rowIndex: Int) {
        // create object.
        // push controller...
        print(">>> Entering \(__FUNCTION__) <<<")
        let model = models[rowIndex]
        
        pushControllerWithName("SiteDetail", context: [WatchModel.PropertyKey.delegateKey: self, WatchModel.PropertyKey.modelKey: model.dictionary])
    }
    
    private func updateTableData() {
        print(">>> Entering \(__FUNCTION__) <<<")
        
        let rowTypeIdentifier: String = "SiteRowController"
        print("models.count = \(models.count)")
        
        sitesTable.setNumberOfRows(0, withRowType: rowTypeIdentifier)
        
        if models.isEmpty {
            sitesTable.setNumberOfRows(1, withRowType: "SiteEmptyRowController")
            let row = sitesTable.rowControllerAtIndex(0) as? SiteEmptyRowController
            if let row = row {
                row.messageLabel.setText("No sites availble.")
            }
            
        } else {
            sitesTable.setNumberOfRows(models.count, withRowType: rowTypeIdentifier)
            for (index, model) in models.enumerate() {
                if let row = sitesTable.rowControllerAtIndex(index) as? SiteRowController {
                    lastUpdatedTime = model.lastReadingDate
                    row.model = model
                }
            }
            
        }
    }
    
    func dataSourceDidUpdateSiteModel(model: WatchModel, atIndex index: Int) {
        print(">>> Entering \(__FUNCTION__) <<<")
        models[index] = model
    }
    
    func dataSourceDidDeleteSiteModel(model: WatchModel, atIndex index: Int) {
        print(">>> Entering \(__FUNCTION__) <<<")
        models.removeAtIndex(index)
        updateTableData()
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
    
    func updateData() {
        print(">>> Entering \(__FUNCTION__) <<<")
        for model in models {
            AppDataManager.sharedInstance.loadDataFor(model, replyHandler: { (model) -> Void in
                //..
            })
        }
    }
    
    @IBAction func updateButton() {
        updateData()
    }
}

