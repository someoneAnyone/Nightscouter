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
    
    @IBOutlet var table: WKInterfaceTable!
    
    var sites: [Site] = []
    
    var lastUpdatedTime: NSDate?
    
    override func willActivate() {
        super.willActivate()
        
        if let data = NSUserDefaults.standardUserDefaults().objectForKey("sites") as? NSData {
            if let sites  = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? [Site] {
                dataSourceDidUpdate(sites)
            }
        }
        
        WatchSessionManager.sharedManager.addDataSourceChangedDelegate(self)
        // WatchSessionManager.sharedManager.wakeUp()
    }
    
    override func willDisappear() {
        super.willDisappear()
        let data =  NSKeyedArchiver.archivedDataWithRootObject(self.sites)
        NSUserDefaults.standardUserDefaults().setObject(data, forKey: "sites")
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    func dataSourceDidUpdate(dataSource: [Site]) {
        sites = dataSource
        self.loadTableRows()
    }
    
    override func table(table: WKInterfaceTable, didSelectRowAtIndex rowIndex: Int) {
        // create object.
        // push controller...
        print(">>> Entering \(__FUNCTION__) <<<")
        pushControllerWithName("SiteDetail", context: ["delegate": self, "site": sites[rowIndex]])
        //        presentControllerWithName("SiteDetail", context: sites[rowIndex])
    }
    
    /*
    override func contextForSegueWithIdentifier(segueIdentifier: String,
    inTable table: WKInterfaceTable, rowIndex: Int) -> AnyObject? {
    print(">>> Entering \(__FUNCTION__) <<<")
    
    if segueIdentifier == "detail" {
    return sites[rowIndex]
    }
    
    return nil
    }
    */
    
    func didUpdateItem(site: Site) {
        if let index = self.sites.indexOf(site) {
            self.sites[index] = site
        }
    }
    
    func loadTableRows(){
        table.setNumberOfRows(0, withRowType: "site")
        
        if sites.isEmpty {
            table.setNumberOfRows(1, withRowType: "site")
            
            let row = table.rowControllerAtIndex(0) as? SiteRowController
            
            if let row = row {
                row.siteNameLabel.setText("Nothing")
            }
            
        } else {
            table.setNumberOfRows(sites.count, withRowType: "site")
            
            for (index, site) in sites.enumerate() {
                let row = table.rowControllerAtIndex(index) as? SiteRowController
                if let row = row {
                    
                    if (site.configuration == nil) {
                        loadDataFor(site, index: index)
                    } else {
                        updateUI(row, site: site)
                    }
                }
            }
        }
    }
    
    func updateUI(row: SiteRowController, site: Site) {
        
        guard let configuration = site.configuration, watchEntry = site.watchEntry else {
            return
        }
        
        let units: Units = configuration.displayUnits
        
        let timeAgo = watchEntry.date.timeIntervalSinceNow
        let isStaleData = configuration.isDataStaleWith(interval: timeAgo)
        
        guard let sgvValue = watchEntry.sgv  else {
            #if DEBUG
                println("No SGV was found in the watch")
            #endif
            
            return
        }
        
        let defaultTextColor = NSAssetKitWatchOS.predefinedNeutralColor
        
        var sgvString: String = ""
        var sgvColor: UIColor = defaultTextColor
        
        var deltaString: String = ""
        
        var isRawDataAvailable: Bool = false
        var rawString: String = ""
        var rawColor: UIColor = defaultTextColor
        
        var batteryString: String = watchEntry.batteryString
        var batteryColor: UIColor = colorForDesiredColorState(watchEntry.batteryColorState)
        var lastUpdatedColor: UIColor = defaultTextColor
        
        var boundedColor = configuration.boundedColorForGlucoseValue(sgvValue.sgv)
        if units == .Mmol {
            boundedColor = configuration.boundedColorForGlucoseValue(sgvValue.sgv.toMgdl)
        }
        
        sgvString =  "\(sgvValue.sgvString) \(sgvValue.direction.emojiForDirection)"
        deltaString = "\(watchEntry.bgdelta.formattedForBGDelta) \(units.descriptionShort)"
        sgvColor = colorForDesiredColorState(boundedColor)
        
        if let enabledOptions = configuration.enabledOptions {
            let rawEnabled =  enabledOptions.contains(EnabledOptions.rawbg)
            isRawDataAvailable = true
            if rawEnabled {
                if let rawValue = watchEntry.raw {
                    rawColor = colorForDesiredColorState(configuration.boundedColorForGlucoseValue(rawValue))
                    
                    var raw = "\(rawValue.formattedForMgdl)"
                    if configuration.displayUnits == .Mmol {
                        raw = rawValue.formattedForMmol
                    }
                    
                    rawString = "\(raw) : \(sgvValue.noise.descriptionShort)"
                }
            }
        }
        
        
        if isStaleData.warn {
            batteryString = ("---%")
            batteryColor = defaultTextColor
            
            rawString = "--- : ---"
            rawColor = defaultTextColor
            
            deltaString = "- --/--"
            
            sgvString = "---"
            sgvColor = colorForDesiredColorState(.Neutral)
        }
        
        if isStaleData.urgent{
            
            lastUpdatedColor = NSAssetKitWatchOS.predefinedAlertColor
            
        }
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            
            // Site name in row
            row.siteNameLabel.setText(configuration.displayName)
            
            // Last reading label
            row.siteLastReadingLabel.setText(watchEntry.dateTimeAgoStringShort)
            row.siteLastReadingLabel.setTextColor(lastUpdatedColor)
            
            // Battery label
            row.siteBatteryLabel.setText(batteryString)
            row.siteBatteryLabel.setTextColor(batteryColor)
            
            // Raw data
            row.siteRawGroup.setHidden(!isRawDataAvailable)
            row.siteRawLabel.setText(rawString)
            row.siteRawLabel.setTextColor(rawColor)
            
            // SGV formatted value
            row.siteSgvLabel.setText(sgvString)
            row.siteSgvLabel.setTextColor(sgvColor)
            
            // Delta
            row.siteDirectionLabel.setText(deltaString)
            row.siteDirectionLabel.setTextColor(sgvColor)
            
            row.backgroundGroup.setBackgroundColor(sgvColor.colorWithAlphaComponent(0.2))
            
        })
    }
    
    func loadDataFor(site: Site, index: Int){
        // Start up the API
        let nsApi = NightscoutAPIClient(url: site.url)
        if (lastUpdatedTime?.timeIntervalSinceNow > 120 || lastUpdatedTime == nil || site.configuration == nil) {
            
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
                        // Get back on the main queue to update the user interface
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            
                            site.configuration = configuration
                            site.watchEntry = watchEntry
                            self.lastUpdatedTime = site.lastConnectedDate
                            
                            if let index = self.sites.indexOf(site) {
                                self.sites[index] = site
                            } else {
                                print("warning...")
                            }
                            
                            self.loadTableRows()
                        })
                    })
                }
            }
        }
    }
}
