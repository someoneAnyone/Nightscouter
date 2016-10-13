//
//  GlanceController.swift
//  Nightscouter Watch WatchKit Extension
//
//  Created by Peter Ina on 1/11/16.
//  Copyright © 2016 Nothingonline. All rights reserved.
//

import WatchKit
import Foundation
import NightscouterWatchOSKit

class GlanceController: WKInterfaceController {
    
    @IBOutlet var lastUpdateLabel: WKInterfaceLabel!
    @IBOutlet var batteryLabel: WKInterfaceLabel!
    @IBOutlet var siteDeltaLabel: WKInterfaceLabel!
    @IBOutlet var siteRawLabel: WKInterfaceLabel!
    @IBOutlet var siteNameLabel: WKInterfaceLabel!
    @IBOutlet var siteSgvLabel: WKInterfaceLabel!
    
    var site: Site? {
        didSet {
            self.configureView()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func willActivate() {
        super.willActivate()
        
        beginGlanceUpdates()
        //Update data.
        FIXME()
        SitesDataSource.sharedInstance.primarySite?.fetchDataFromNetwork(completion: { (updateSite, error) in
            
            SitesDataSource.sharedInstance.updateSite(updateSite)

        })
        endGlanceUpdates()
        
    }
    
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        self.configureView()
        
        NotificationCenter.default.addObserver(forName: .NightscoutDataUpdatedNotification, object: nil, queue: OperationQueue.main) { (notif) in
            
            self.site = SitesDataSource.sharedInstance.primarySite
        }
    }
    
    func configureView() {
        
        guard let site = self.site else {
            return
        }
        
        let  dataSource = SiteSummaryModelViewModel(withSite: site)
        
//        OperationQueue.main.addOperation {
        
            let dateString = NSCalendar.autoupdatingCurrent.stringRepresentationOfElapsedTimeSinceNow(dataSource.lastReadingDate)
            
            let formattedLastUpdateString = self.formattedStringWithHeaderFor(dateString, textColor: dataSource.lastReadingColor, textHeader: LocalizedString.lastReadingLabelShort.localized)
            
            let formattedRaw = self.formattedStringWithHeaderFor(dataSource.rawLabel, textColor: dataSource.rawColor, textHeader: LocalizedString.rawLabelShort.localized)
            
            let formattedBattery = self.formattedStringWithHeaderFor(dataSource.batteryLabel, textColor: dataSource.batteryColor, textHeader: LocalizedString.batteryLabelShort.localized)
            
            let sgvString = String(stringInterpolation:dataSource.sgvLabel, dataSource.direction.emojiForDirection)
            
            // Battery
            self.batteryLabel.setAttributedText(formattedBattery)
            self.lastUpdateLabel.setAttributedText(formattedLastUpdateString)
            
            // Delta
            self.siteDeltaLabel.setText(dataSource.deltaLabel)
            self.siteDeltaLabel.setTextColor(dataSource.deltaColor)
            
            // Name
            self.siteNameLabel.setText(dataSource.nameLabel)
            
            // Sgv
            self.siteSgvLabel.setText(sgvString)
            self.siteSgvLabel.setTextColor(dataSource.sgvColor)
            
            // Raw
            self.siteRawLabel.setAttributedText(formattedRaw)
            self.siteRawLabel.setHidden(dataSource.rawHidden)
//        }
        
        self.updateUserActivity("com.nothingonline.nightscouter.view", userInfo: [DefaultKey.lastViewedSiteIndex: SitesDataSource.sharedInstance.sites.index(of: site)], webpageURL: URL(string: dataSource.urlLabel))
    }
    
    func formattedStringWithHeaderFor(_ textValue: String, textColor: UIColor, textHeader: String) -> NSAttributedString {
        
        let headerFontDict = [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 8)]
        
        let headerString = NSMutableAttributedString(string: textHeader, attributes: headerFontDict)
        headerString.addAttribute(NSForegroundColorAttributeName, value: UIColor(white: 1.0, alpha: 0.5), range: NSRange(location:0,length:textHeader.characters.count))
        
        let valueString = NSMutableAttributedString(string: textValue)
        valueString.addAttribute(NSForegroundColorAttributeName, value: textColor, range: NSRange(location:0,length:textValue.characters.count))
        
        headerString.append(valueString)
        
        return headerString
    }
    
}
