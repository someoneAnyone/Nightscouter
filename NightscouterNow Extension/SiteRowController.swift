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
    
    @IBOutlet var siteUpdateTimer: WKInterfaceTimer!
    
    var model: WatchModel? {
        didSet {
            
            if let model = model {
                // Site name in row
                
                let sgvColor = UIColor(hexString: model.sgvColor)
                let rawColor = UIColor(hexString: model.rawColor)
                let batteryColor = UIColor(hexString: model.batteryColor)
                let lastReadingColor = UIColor(hexString: model.lastReadingColor)
                

                siteNameLabel.setText(model.displayName)
                
                let date = NSCalendar.autoupdatingCurrentCalendar().stringRepresentationOfElapsedTimeSinceNow(model.lastReadingDate)

                
                
                // Last reading label
                siteLastReadingLabel.setText(date)
                siteLastReadingLabel.setTextColor(lastReadingColor)
           
                siteUpdateTimer.setDate(model.lastReadingDate)
                siteUpdateTimer.setTextColor(lastReadingColor)
                
                // Battery label
                siteBatteryLabel.setText(model.batteryString)
                siteBatteryLabel.setTextColor(batteryColor)
                
                // Raw data
                siteRawGroup.setHidden(!model.rawVisible)
                siteRawLabel.setText(model.rawString)
                siteRawLabel.setTextColor(rawColor)
                
                // SGV formatted value
                siteSgvLabel.setText(model.sgvStringWithEmoji)
                siteSgvLabel.setTextColor(sgvColor)
                
                // Delta
                siteDirectionLabel.setText(model.deltaString)
                siteDirectionLabel.setTextColor(sgvColor)
                
                backgroundGroup.setBackgroundColor(sgvColor.colorWithAlphaComponent(0.2))
            }
        }
    }
    
}

