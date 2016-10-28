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

    fileprivate var dataSource: TableViewRowWithOutCompassDataSource?
    fileprivate var delegate: TableViewRowWithOutCompassDelegate?
    
    func configure(withDataSource dataSource: TableViewRowWithOutCompassDataSource, delegate: TableViewRowWithOutCompassDelegate?) {
        self.dataSource = dataSource
        self.delegate = delegate
        
        // let timerHidden: Bool = dataSource.lookStale
        
        siteNameLabel.setText(dataSource.nameLabel)
        
        // Last reading label
        siteLastReadingHeader.setText(LocalizedString.lastReadingLabelShort.localized)

        // siteLastReadingLabel.setText(PlaceHolderStrings.date)
        // siteLastReadingLabel.setTextColor(PlaceHolderStrings.defaultColor.colorValue)
        // siteLastReadingLabel.setHidden(true)
        
        siteUpdateTimer.setDate(dataSource.lastReadingDate)
        siteUpdateTimer.setTextColor(delegate?.lastReadingColor)
        siteUpdateTimer.setHidden(false)
        
        // Battery label
        siteBatteryHeader.setText(LocalizedString.batteryLabelShort.localized)
        siteBatteryLabel.setText(dataSource.batteryLabel)
        siteBatteryLabel.setTextColor(delegate?.batteryColor)
        siteBatteryHeader.setHidden(dataSource.batteryHidden)
        siteBatteryLabel.setHidden(dataSource.batteryHidden)

        // Raw data
        siteRawGroup.setHidden(dataSource.rawHidden)
        siteRawHeader.setText(LocalizedString.rawLabelShort.localized)
        siteRawLabel.setText(dataSource.rawFormatedLabel)
        siteRawLabel.setTextColor(delegate?.rawColor)
        
        let sgvString = dataSource.sgvLabel + " " + dataSource.direction.emojiForDirection
        // SGV formatted value
        siteSgvLabel.setText(sgvString)
        siteSgvLabel.setTextColor(delegate?.sgvColor)
        
        // Delta
        siteDirectionLabel.setText(dataSource.deltaLabel)
        siteDirectionLabel.setTextColor(delegate?.deltaColor)
        
        backgroundGroup.setBackgroundColor(delegate?.sgvColor.withAlphaComponent(0.2))
        
    }
}

