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

class SitesInterfaceController: WKInterfaceController, DataSourceChangedDelegate{
    
    var sites: [Site] = [] {
        didSet{
            print("sites did set in PageController")
            let data =  NSKeyedArchiver.archivedDataWithRootObject(self.sites)
            NSUserDefaults.standardUserDefaults().setObject(data, forKey: "sites")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    var names: [String] = []

    override func willActivate() {
        super.willActivate()
        
        if let data = NSUserDefaults.standardUserDefaults().objectForKey("sites") as? NSData {
            if let sites  = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? [Site] {
                dataSourceDidUpdate(sites)
            }
        }

        WatchSessionManager.sharedManager.addDataSourceChangedDelegate(self)
        WatchSessionManager.sharedManager.wakeUp()
    }
    
    func dataSourceDidUpdate(dataSource: [Site]) {

        sites = dataSource

        names.removeAll()
        for _ in (0..<sites.count) {
            names.append("SiteDetail")
        }
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            WKInterfaceController.reloadRootControllersWithNames(self.names, contexts: self.sites)
        })
    }
}
