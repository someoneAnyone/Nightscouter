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
    
    var updateUITimer: Timer?
    
    /*
    var model: WatchModel? {
        return WatchSessionManager.sharedManager.defaultModel()
    }
 */
    var model: WatchModel? {
        didSet{
            DispatchQueue.main.async {
                self.configureView()
            }
        }
    }
    
    override func willActivate() {
        
        updateUITimer = Timer.scheduledTimer(timeInterval: 60.0 , target: self, selector: #selector(GlanceController.configureView), userInfo: nil, repeats: true)
        
        beginGlanceUpdates()
        
        // self.configureView()
        WatchSessionManager.sharedManager.updateComplication { (timline) in
            self.model = WatchSessionManager.sharedManager.defaultModel()
            self.endGlanceUpdates()
        }
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        // Configure interface objects here.
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        
        updateUITimer?.invalidate()
    }
    
    func configureView() {
        
        guard let model = self.model else {
            OperationQueue.main.addOperation {
                self.siteDeltaLabel.setText("Launch Nightscouter")
                self.siteRawLabel.setText("and add a site.")
                self.siteNameLabel.setText("")
                self.siteSgvLabel.setText("")
            }
            
            self.invalidateUserActivity()
            return
        }
        
        
            let dateString = Calendar.autoupdatingCurrent.stringRepresentationOfElapsedTimeSinceNow(model.lastReadingDate)
            
            let formattedLastUpdateString = self.formattedStringWithHeaderFor(dateString, textColor: UIColor(hexString: model.lastReadingColor), textHeader: "LR")
            
            let formattedRaw = self.formattedStringWithHeaderFor(model.rawString, textColor:  UIColor(hexString: model.rawColor), textHeader: "R")
            
            let formattedBattery = self.formattedStringWithHeaderFor(model.batteryString, textColor:  UIColor(hexString: model.batteryColor), textHeader: "B")
            
            let sgvString = String(stringInterpolation:model.sgvStringWithEmoji.replacingOccurrences(of: " ", with: ""))

        OperationQueue.main.addOperation {

            // Battery
            self.batteryLabel.setAttributedText(formattedBattery)
            self.lastUpdateLabel.setAttributedText(formattedLastUpdateString)
            
            // Delta
            self.siteDeltaLabel.setText(model.deltaString)
            self.siteDeltaLabel.setTextColor(UIColor(hexString: model.deltaColor))
            
            // Name
            self.siteNameLabel.setText(model.displayName)
            
            // Sgv
            self.siteSgvLabel.setText(sgvString)
            self.siteSgvLabel.setTextColor(UIColor(hexString: model.sgvColor))
            
            // Raw
            self.siteRawLabel.setAttributedText(formattedRaw)
            self.siteRawLabel.setHidden(!model.rawVisible)
            
            self.updateUserActivity("com.nothingonline.nightscouter.view", userInfo: [WatchModel.PropertyKey.modelKey: model.dictionary], webpageURL: URL(string: model.urlString)!)
        }
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
