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
    
    var sites: [Site] = []
    
    var lastUpdatedTime: NSDate?
    var timer: NSTimer = NSTimer()
    var nsApi: [NightscoutAPIClient]?
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        if let data = NSUserDefaults.standardUserDefaults().objectForKey("sites") as? NSData {
            if let sites  = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? [Site] {
                dataSourceDidUpdate(sites)
            }
        }

        WatchSessionManager.sharedManager.addDataSourceChangedDelegate(self)
        
        timer = NSTimer.scheduledTimerWithTimeInterval(240.0, target: self, selector: Selector("updateData"), userInfo: nil, repeats: true)
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        print(">>> Entering \(__FUNCTION__) <<<")
        
        WatchSessionManager.sharedManager.wakeUp()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        print(">>> Entering \(__FUNCTION__) <<<")
        super.didDeactivate()
        
        let data =  NSKeyedArchiver.archivedDataWithRootObject(self.sites)
        NSUserDefaults.standardUserDefaults().setObject(data, forKey: "sites")
        NSUserDefaults.standardUserDefaults().synchronize()
        
        timer.invalidate()
    }
    
    override func willDisappear() {
        super.willDisappear()
        print(">>> Entering \(__FUNCTION__) <<<")
        
    }
    
    override func table(table: WKInterfaceTable, didSelectRowAtIndex rowIndex: Int) {
        // create object.
        // push controller...
        print(">>> Entering \(__FUNCTION__) <<<")
        pushControllerWithName("SiteDetail", context: ["delegate": self, "site": sites[rowIndex]])
    }
    
    
    private func loadTableData() {
        print(">>> Entering \(__FUNCTION__) <<<")
        
        let rowTypeIdentifier: String = "SiteRowController"
        
        sitesTable.setNumberOfRows(0, withRowType: rowTypeIdentifier)
        
        if sites.isEmpty {
            sitesTable.setNumberOfRows(1, withRowType: rowTypeIdentifier)
            let row = sitesTable.rowControllerAtIndex(0) as? SiteRowController
            if let row = row {
                row.siteNameLabel.setText("Nothing")
            }
            
        } else {
            sitesTable.setNumberOfRows(sites.count, withRowType: rowTypeIdentifier)
            for (index, site) in sites.enumerate() {
                if let _ = sitesTable.rowControllerAtIndex(index) as? SiteRowController {
                    loadDataFor(site, index: index)
                }
            }
        }
    }
    
    func dataSourceDidUpdate(dataSource: [Site]) {
        print(">>> Entering \(__FUNCTION__) <<<")
        
        sites = dataSource
        loadTableData()
    }
    
    func didUpdateItem(site: Site) {
        print(">>> Entering \(__FUNCTION__) <<<")
        if let index = self.sites.indexOf(site) {
            self.sites[index] = site
        }
    }
    
    func updateData() {
        print(">>> Entering \(__FUNCTION__) <<<")
        for (index, site) in sites.enumerate() {
            loadDataFor(site, index: index)
        }
    }
    
    func loadDataFor(site: Site, index: Int){
        print(">>> Entering \(__FUNCTION__) <<<")
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            // Start up the API
            let nsApi = NightscoutAPIClient(url: site.url)
            if (self.lastUpdatedTime?.timeIntervalSinceNow > 120) || self.lastUpdatedTime == nil {
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
                            self.lastUpdatedTime = site.lastConnectedDate
                            self.sites[index] = site
                            
                            // Get back on the main queue to update the user interface
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                print("Update rows...")
                                if let watchModel = WatchModel(fromSite: site) {
                                    let row = self.sitesTable.rowControllerAtIndex(index) as! SiteRowController
                                    row.model = watchModel
                                }
                            })
                        })
                    }
                }
            }
        }
    }
}

