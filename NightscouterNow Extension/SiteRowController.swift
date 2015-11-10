//
//  SiteRowController.swift
//  Nightscouter
//
//  Created by Peter Ina on 10/4/15.
//  Copyright © 2015 Peter Ina. All rights reserved.
//

import WatchKit

class SiteRowController: NSObject {
    @IBOutlet var siteNameLabel: WKInterfaceLabel!
    @IBOutlet var siteRawGroup: WKInterfaceGroup!
    
    @IBOutlet var siteLastReadingHeader: WKInterfaceLabel!
    @IBOutlet var backgroundGroup: WKInterfaceGroup!
    @IBOutlet var siteLastReadingLabel: WKInterfaceLabel!
    
    @IBOutlet var siteBatteryHeader: WKInterfaceLabel!
    @IBOutlet var siteBatteryLabel: WKInterfaceLabel!
    
    @IBOutlet var siteRawHeader: WKInterfaceLabel!
    @IBOutlet var siteRawLabel: WKInterfaceLabel!
    
    @IBOutlet var siteSgvLabel: WKInterfaceLabel!
    @IBOutlet var siteDirectionLabel: WKInterfaceLabel!
}


