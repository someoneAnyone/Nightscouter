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
    var timer: NSTimer?
    var nsApi: [NightscoutAPIClient]?
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
       
        if models.isEmpty {
            if let dictArray = NSUserDefaults.standardUserDefaults().objectForKey(WatchModel.PropertyKey.modelsKey) as? [[String: AnyObject]] {
                print("Loading models from default.")
                models = dictArray.map({ WatchModel(fromDictionary: $0)! })
            } else {
                updateTableData()
            }
        }
        
        timer = NSTimer.scheduledTimerWithTimeInterval(Constants.NotableTime.StandardRefreshTime, target: self, selector: Selector("updateData"), userInfo: nil, repeats: true)
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        print(">>> Entering \(__FUNCTION__) <<<")
        
        WatchSessionManager.sharedManager.addDataSourceChangedDelegate(self)
        WatchSessionManager.sharedManager.requestLatestAppContext()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        print(">>> Entering \(__FUNCTION__) <<<")
        
        timer?.invalidate()
        
        super.didDeactivate()
    }
    
    override func willDisappear() {
        super.willDisappear()
        print(">>> Entering \(__FUNCTION__) <<<")
        
        WatchSessionManager.sharedManager.removeDataSourceChangedDelegate(self)
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
//        else if models.count == 1 {
//            print("only one site...")
//            presentControllerWithName("SiteDetail", context: [WatchModel.PropertyKey.delegateKey: self, WatchModel.PropertyKey.modelKey: models.first!.dictionary])
//        }
    }
    
    func dataSourceDidUpdateSiteModel(model: WatchModel, atIndex index: Int) {
        print(">>> Entering \(__FUNCTION__) <<<")
        models[index] = model
    }
    
    func dataSourceDidDeleteSiteModel(model: WatchModel, atIndex index: Int) {
        print(">>> Entering \(__FUNCTION__) <<<")
        models.removeAtIndex(index)
    }
    
    func dataSourceDidAddSiteModel(model: WatchModel) {
        print(">>> Entering \(__FUNCTION__) <<<")
        
        if let modelIndex = models.indexOf(model){
            models[modelIndex] = model
        } else {
            models.append(model)
        }
    }
    
    func didUpdateItem(site: Site, withModel model: WatchModel) {
        
        print(">>> Entering \(__FUNCTION__) <<<")

        if let index = self.models.indexOf(model) {
            self.models[index] = model
        }
        
//        if let model = WatchModel(fromSite: site), index = self.models.indexOf(model) {
//            self.models[index] = model
//        }
    }
    
    func updateData() {
        print(">>> Entering \(__FUNCTION__) <<<")
        for (index, model) in models.enumerate() {
            let url = NSURL(string: model.urlString)!
            let site = Site(url: url, apiSecret: nil)!
            
            WatchSessionManager.sharedManager.loadDataFor(site, index: index, lastUpdateDate: model.lastReadingDate)
        }
        
        
        let dictArray = models.map({ $0.dictionary })
        NSUserDefaults.standardUserDefaults().setObject(dictArray, forKey: WatchModel.PropertyKey.modelsKey)
//        NSUserDefaults.standardUserDefaults().removeObjectForKey(WatchModel.PropertyKey.modelsKey)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
}

