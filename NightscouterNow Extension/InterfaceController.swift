//
//  InterfaceController.swift
//  NightscouterNow Extension
//
//  Created by Peter Ina on 10/4/15.
//  Copyright © 2015 Peter Ina. All rights reserved.
//

import WatchKit
import Foundation


class InterfaceController: WKInterfaceController {
    
    @IBOutlet var siteNameLabel: WKInterfaceLabel!
    @IBOutlet var siteLastReadingLabel: WKInterfaceLabel!
    
    @IBOutlet var siteBatteryHeader: WKInterfaceLabel!
    @IBOutlet var siteBatteryLabel: WKInterfaceLabel!
    
    @IBOutlet var siteRawHeader: WKInterfaceLabel!
    @IBOutlet var siteRawLabel: WKInterfaceLabel!
    
    @IBOutlet var siteSgvLabel: WKInterfaceLabel!
    @IBOutlet var siteDirectionLabel: WKInterfaceLabel!
    
    @IBOutlet var siteDeltaLabel: WKInterfaceLabel!
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
}
