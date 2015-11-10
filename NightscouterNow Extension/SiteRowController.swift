//
//  SiteRowController.swift
//  Nightscouter
//
//  Created by Peter Ina on 10/4/15.
//  Copyright © 2015 Peter Ina. All rights reserved.
//

import WatchKit
import NightscouterWatchOSKit

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
    
    var model: WatchModel? {
        didSet {
            
            if let model = model {
                // Site name in row
                siteNameLabel.setText(model.displayName)
                
                // Last reading label
                siteLastReadingLabel.setText(model.lastReadingString)
                siteLastReadingLabel.setTextColor(model.lastReadingColor)
                
                // Battery label
                siteBatteryLabel.setText(model.batteryString)
                siteBatteryLabel.setTextColor(model.batteryColor)
                
                // Raw data
                siteRawGroup.setHidden(model.rawVisible)
                siteRawLabel.setText(model.rawString)
                siteRawLabel.setTextColor(model.rawColor)
                
                // SGV formatted value
                siteSgvLabel.setText(model.sgvString)
                siteSgvLabel.setTextColor(model.sgvColor)
                
                // Delta
                siteDirectionLabel.setText(model.deltaString)
                siteDirectionLabel.setTextColor(model.sgvColor)
                
                backgroundGroup.setBackgroundColor(model.sgvColor.colorWithAlphaComponent(0.2))
            }
        }
    }
    
}

