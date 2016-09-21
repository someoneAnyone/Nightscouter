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
    
    var model: SiteSummaryModelViewModel? {
        didSet {
            
            if let model = model {
                // Site name in row
                OperationQueue.main.addOperation({ () -> Void in
                    
                    let sgvColor = model.sgvColor
                    let rawColor = model.rawColor
                    let batteryColor = model.batteryColor
                    let lastReadingColor = model.lastReadingColor
                    
                    
                    self.siteNameLabel.setText(model.nameLabel)
                    
                    let date = Calendar.autoupdatingCurrent.stringRepresentationOfElapsedTimeSinceNow(model.lastReadingDate)
                    
                    // Last reading label
                    self.siteLastReadingLabel.setText(date)
                    self.siteLastReadingLabel.setTextColor(lastReadingColor)
                    
                    self.siteUpdateTimer.setDate(model.lastReadingDate)
                    self.siteUpdateTimer.setTextColor(lastReadingColor)
                    
                    // Battery label
                    self.siteBatteryLabel.setText(model.batteryLabel)
                    self.siteBatteryLabel.setTextColor(batteryColor)
                    
                    self.siteBatteryHeader.setHidden(model.batteryHidden)
                    self.siteBatteryLabel.setHidden(model.batteryHidden)
                    
                    // Raw data
                    self.siteRawGroup.setHidden(model.rawHidden)
                    self.siteRawLabel.setText(model.rawLabel)
                    self.siteRawLabel.setTextColor(rawColor)
                    
                    // SGV formatted value
                    self.siteSgvLabel.setText(model.sgvLabel)
                    self.siteSgvLabel.setTextColor(sgvColor)
                    
                    // Delta
                    self.siteDirectionLabel.setText(model.deltaLabel)
                    self.siteDirectionLabel.setTextColor(sgvColor)
                    self.backgroundGroup.setBackgroundColor(sgvColor.withAlphaComponent(0.2))
                    
                })
            }
            
        }
    }
    
}

