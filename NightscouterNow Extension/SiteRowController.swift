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
                OperationQueue.main.addOperation({ () -> Void in
                    
                    let sgvColor = UIColor(hexString: model.sgvColor)
                    let rawColor = UIColor(hexString: model.rawColor)
                    let batteryColor = UIColor(hexString: model.batteryColor)
                    let lastReadingColor = UIColor(hexString: model.lastReadingColor)
                    
                    
                    self.siteNameLabel.setText(model.displayName)
                    
                    let date = Calendar.autoupdatingCurrent.stringRepresentationOfElapsedTimeSinceNow(model.lastReadingDate)
                    
                    // Last reading label
                    self.siteLastReadingLabel.setText(date)
                    self.siteLastReadingLabel.setTextColor(lastReadingColor)
                    
                    self.siteUpdateTimer.setDate(model.lastReadingDate)
                    self.siteUpdateTimer.setTextColor(lastReadingColor)
                    
                    // Battery label
                    self.siteBatteryLabel.setText(model.batteryString)
                    self.siteBatteryLabel.setTextColor(batteryColor)
                    
                    self.siteBatteryHeader.setHidden(model.batteryVisible)
                    self.siteBatteryLabel.setHidden(model.batteryVisible)
                    
                    // Raw data
                    self.siteRawGroup.setHidden(!model.rawVisible)
                    self.siteRawLabel.setText(model.rawString)
                    self.siteRawLabel.setTextColor(rawColor)
                    
                    // SGV formatted value
                    self.siteSgvLabel.setText(model.sgvStringWithEmoji)
                    self.siteSgvLabel.setTextColor(sgvColor)
                    
                    // Delta
                    self.siteDirectionLabel.setText(model.deltaString)
                    self.siteDirectionLabel.setTextColor(sgvColor)
                    self.backgroundGroup.setBackgroundColor(sgvColor.withAlphaComponent(0.2))
                    
                })
            }
            
        }
    }
    
}

