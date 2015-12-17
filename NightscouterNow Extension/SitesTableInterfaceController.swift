//
//  SitesTableInterfaceController.swift
//  Nightscouter
//
//  Created by Peter Ina on 10/4/15.
//  Copyright © 2015 Peter Ina. All rights reserved.
//

import WatchKit
import NightscouterWatchOSKit

class SitesTableInterfaceController: WKInterfaceController, DataSourceChangedDelegate { //, SiteDetailViewDidUpdateItemDelegate {
    
    @IBOutlet var sitesTable: WKInterfaceTable!
    
    var models = [WatchModel]() {
        didSet {
            updateTableData()
            if !models.isEmpty && (lastUpdatedTime?.timeIntervalSinceNow > Constants.StandardTimeFrame.TwoAndHalfMinutesInSeconds) {
                updateData()
            }
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
        WatchSessionManager.sharedManager.requestLatestAppContext()
        
        setupNotifications()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        print(">>> Entering \(__FUNCTION__) <<<")
        super.didDeactivate()
        
        WatchSessionManager.sharedManager.removeDataSourceChangedDelegate(self)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func willDisappear() {
        super.willDisappear()
        print(">>> Entering \(__FUNCTION__) <<<")
    }
    
    func setupNotifications() {
        // Listen for global update timer.
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateData", name: NightscoutAPIClientNotification.DataIsStaleUpdateNow, object: nil)
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
            
            self.sitesTable.setNumberOfRows(0, withRowType: rowTypeIdentifier)
            
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
                        self.lastUpdatedTime = model.lastReadingDate
                        row.model = model
                    }
                }
                
            }
            
        }
    }
    
    func dataSourceDidUpdateSiteModel(model: WatchModel, atIndex index: Int) {
        print(">>> Entering \(__FUNCTION__) <<<")
        //        if let modelIndex = models.indexOf(model){
        //            models[modelIndex] = model
        //        }
        
        models[index] = model
        
        ComplicationController.reloadComplications()
    }
    
    func dataSourceDidDeleteSiteModel(model: WatchModel, atIndex index: Int) {
        print(">>> Entering \(__FUNCTION__) <<<")
        
        if let realIndex = models.indexOf(model) {
            models.removeAtIndex(realIndex)
        } else {
            fatalError()
        }
        
        //        updateTableData()
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
    
//    func didUpdateItem(model: WatchModel) {
//        
//        print(">>> Entering \(__FUNCTION__) <<<")
//        
//        if let index = models.indexOf(model) {
//            self.models[index] = model
//        } else {
//            print("Did not update table view with recent item")
//        }
//    }
    
    func updateData() {
        print(">>> Entering \(__FUNCTION__) <<<")

        for (index, model) in models.enumerate() {
            loadDataFor(model, replyHandler: { (model) -> Void in
                self.dataSourceDidUpdateSiteModel(model, atIndex: index)
                //                self.updateTableData()
            })
        }
    }
    
    @IBAction func updateButton() {
        updateData()
    }
}

