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
        
//        if let data = NSUserDefaults.standardUserDefaults().objectForKey("sites") as? NSData {
//            if let sites  = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? [Site] {
//                // dataSourceDidUpdate(sites)
//            }
//        } else {
//            updateTableData()
//        }

        updateTableData()
        
        NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: NightscoutAPIClientNotification.DataIsStaleUpdateNow, object: self))
        
        if (self.timer == nil) {
            timer = NSTimer.scheduledTimerWithTimeInterval(240.0, target: self, selector: Selector("updateData"), userInfo: nil, repeats: true)
        }

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
        
//        let data =  NSKeyedArchiver.archivedDataWithRootObject(self.sites)
//        NSUserDefaults.standardUserDefaults().setObject(data, forKey: "sites")
//        NSUserDefaults.standardUserDefaults().synchronize()
        
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
       // pushControllerWithName("SiteDetail", context: ["delegate": self, "site": sites[rowIndex]])
        
        let model = models[rowIndex]
        
        pushControllerWithName("SiteDetail", context: ["delegate": self, "site": model.dictionary])

    }
    
    
    private func updateTableData() {
        print(">>> Entering \(__FUNCTION__) <<<")
        
        let rowTypeIdentifier: String = "SiteRowController"
        
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
    }
    
    func dataSourceDidAddSiteModel(model: WatchModel) {
        print(">>> Entering \(__FUNCTION__) <<<")
        models.append(model)
    }
    
    func didUpdateItem(site: Site) {
        print(">>> Entering \(__FUNCTION__) <<<")
        if let model = WatchModel(fromSite: site), index = self.models.indexOf(model) {
            self.models[index] = model
        }
    }
    
    func updateData() {
        print(">>> Entering \(__FUNCTION__) <<<")
        for (index, model) in models.enumerate() {
            let url = NSURL(string: model.urlString)!
            let site = Site(url: url, apiSecret: nil)!
            WatchSessionManager.sharedManager.loadDataFor(site, index: index)
        }
    }
//    
//    func loadDataFor(site: Site, index: Int){
//
//        print(">>> Entering \(__FUNCTION__) <<<")
//        
//        
//        
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
//            // Start up the API
//            let nsApi = NightscoutAPIClient(url: site.url)
////            if (self.lastUpdatedTime?.timeIntervalSinceNow > 120) || self.lastUpdatedTime == nil {
//                // Get settings for a given site.
//                print("Loading data for \(site.url!)")
//                nsApi.fetchServerConfiguration { (result) -> Void in
//                    switch (result) {
//                    case let .Error(error):
//                        // display error message
//                        print("\(__FUNCTION__) ERROR recieved: \(error)")
//                    case let .Value(boxedConfiguration):
//                        let configuration:ServerConfiguration = boxedConfiguration.value
//                        // do something with user
//                        nsApi.fetchDataForWatchEntry({ (watchEntry, watchEntryErrorCode) -> Void in
//
//                            site.configuration = configuration
//                            site.watchEntry = watchEntry
//                            self.lastUpdatedTime = site.lastConnectedDate
//                            self.models[index] = WatchModel(fromSite: site)!
//                            
////                            // Get back on the main queue to update the user interface
////                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
////                                print("Update rows...")
////                                self.updateRowForSite(site, index: index)
////                            })
//                        })
//                    }
//                }
//        }
//    
//    }
    
//    func updateRowForSite(site: Site, index: Int) {
//        if let watchModel = WatchModel(fromSite: site) {
//            let row = self.sitesTable.rowControllerAtIndex(index) as! SiteRowController
//            row.model = watchModel
//        } else {
//            print("Why have you failed me yet again?")
//        }
//
//    }
}

