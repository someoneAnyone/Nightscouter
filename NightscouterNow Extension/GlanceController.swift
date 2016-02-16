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
    
    var modelUpdateTimer: NSTimer?
    var updateUITimer: NSTimer?
    
    var model: WatchModel? {
        didSet{
            self.configureView()
        }
    }
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        // Configure interface objects here.
    }
    
    override func willActivate() {
        super.willActivate()
        
        // This method is called when watch view controller is about to be visible to user
        self.model = WatchSessionManager.sharedManager.defaultModel()
        
        modelUpdateTimer = NSTimer.scheduledTimerWithTimeInterval(250.0 , target: self, selector: "updateModel", userInfo: nil, repeats: true)
        updateUITimer = NSTimer.scheduledTimerWithTimeInterval(60.0 , target: self, selector: "configureView", userInfo: nil, repeats: true)
        
        modelUpdateTimer?.fire()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        
        modelUpdateTimer?.invalidate()
        updateUITimer?.invalidate()
    }
    
    func updateModel(){
        if let model = model {
            if WatchSessionManager.sharedManager.requestLatestAppContext(watchAction: .AppContext) {
                quickFetch(model.generateSite(), handler: { (returnedSite, error) -> Void in
                    NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
                        WatchSessionManager.sharedManager.updateModel(returnedSite.viewModel)
                        self.model = returnedSite.viewModel
                        self.updateUserActivity("com.nothingonline.nightscouter.view", userInfo: [WatchModel.PropertyKey.modelKey: model.dictionary], webpageURL: NSURL(string: model.urlString)!)
                    }
                })
            }
        }
    }
    
    func configureView() {
        
        guard let model = self.model else {
            
            self.siteDeltaLabel.setText("Launch Nightscouter")
            self.siteRawLabel.setText("and add a site.")
            
            return
        }
        
        NSOperationQueue.mainQueue().addOperationWithBlock {
            
            let dateString = NSCalendar.autoupdatingCurrentCalendar().stringRepresentationOfElapsedTimeSinceNow(model.lastReadingDate)
            
            let formattedLastUpdateString = self.formattedStringWithHeaderFor(dateString, textColor: UIColor(hexString: model.lastReadingColor), textHeader: "LR")
            
            let formattedRaw = self.formattedStringWithHeaderFor(model.rawString, textColor:  UIColor(hexString: model.rawColor), textHeader: "R")
            
            let formattedBattery = self.formattedStringWithHeaderFor(model.batteryString, textColor:  UIColor(hexString: model.batteryColor), textHeader: "B")
            
            let sgvString = String(stringInterpolation:model.sgvStringWithEmoji.stringByReplacingOccurrencesOfString(" ", withString: ""))
            
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
        }
    }
    
    func formattedStringWithHeaderFor(textValue: String, textColor: UIColor, textHeader: String) -> NSAttributedString {
        
        let headerFontDict = [NSFontAttributeName: UIFont.boldSystemFontOfSize(8)]
        
        let headerString = NSMutableAttributedString(string: textHeader, attributes: headerFontDict)
        headerString.addAttribute(NSForegroundColorAttributeName, value: UIColor(white: 1.0, alpha: 0.5), range: NSRange(location:0,length:textHeader.characters.count))
        
        let valueString = NSMutableAttributedString(string: textValue)
        valueString.addAttribute(NSForegroundColorAttributeName, value: textColor, range: NSRange(location:0,length:textValue.characters.count))
        
        headerString.appendAttributedString(valueString)
        
        return headerString
    }
    
}
