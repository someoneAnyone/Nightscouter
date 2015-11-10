//
//  SiteDetailInterfaceController.swift
//  Nightscouter
//
//  Created by Peter Ina on 11/8/15.
//  Copyright © 2015 Peter Ina. All rights reserved.
//

import WatchKit
import Foundation
import NightscouterWatchOSKit

protocol SiteDetailViewDidUpdateItemDelegate {
    func didUpdateItem(site: Site)
}

class SiteDetailInterfaceController: WKInterfaceController {
    
    @IBOutlet var compassGroup: WKInterfaceGroup!
    @IBOutlet var detailGroup: WKInterfaceGroup!
    @IBOutlet var lastUpdateLabel: WKInterfaceLabel!
    @IBOutlet var lastUpdateHeader: WKInterfaceLabel!
    @IBOutlet var batteryLabel: WKInterfaceLabel!
    @IBOutlet var batteryHeader: WKInterfaceLabel!
    @IBOutlet var compassImage: WKInterfaceImage!
    
    var nsApi: NightscoutAPIClient?
    
    var task: NSURLSessionDataTask?
    
    var isActive: Bool = false
    
    var delegate: SiteDetailViewDidUpdateItemDelegate?
    
    var site: Site? {
        didSet {
            
            print("didSet Site? in SiteDetailInterfaceController")
            loadDataFor(site!)
        }
    }
    var lastUpdatedTime: NSDate?
    
    override func willActivate() {
        super.willActivate()
        print("willActivate")
        
        let image = NSAssetKitWatchOS.imageOfWatchFace()
        
        compassImage.setImage(image)
        self.isActive = true
    }
    
    override func didDeactivate() {
        super.didDeactivate()
        print("didDeactivate \(self)")
        
        self.isActive = false
        if let t = self.nsApi?.task {
            if t.state == NSURLSessionTaskState.Running {
                t.cancel()
            }
        }
    }
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        if let site = context as? Site { self.site = site }
        
        if let site = context!["site"] as? Site { self.site = site }
        
        if let delegate = context!["delegate"] as? SiteDetailViewDidUpdateItemDelegate { self.delegate = delegate }
        
    }
    
    func loadDataFor(site: Site){
        // Start up the API
        nsApi = NightscoutAPIClient(url: site.url)
        
        if (lastUpdatedTime?.timeIntervalSinceNow > 120 || lastUpdatedTime == nil || site.configuration == nil) {
            
            // Get settings for a given site.
            // print("Loading data for \(site.url!)")
            nsApi!.fetchServerConfiguration { (result) -> Void in
                switch (result) {
                case let .Error(error):
                    // display error message
                    print("\(__FUNCTION__) ERROR recieved: \(error)")
                case let .Value(boxedConfiguration):
                    let configuration:ServerConfiguration = boxedConfiguration.value
                    // do something with user
                    self.nsApi!.fetchDataForWatchEntry({ (watchEntry, watchEntryErrorCode) -> Void in
                        // Get back on the main queue to update the user interface
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            
                            // print("recieved data: { configuration: \(configuration), watchEntry: \(watchEntry) })")
                            
                            site.configuration = configuration
                            site.watchEntry = watchEntry
                            self.lastUpdatedTime = site.lastConnectedDate
                            self.delegate?.didUpdateItem(site)
                            self.updateUI()
                        })
                    })
                }
            }
        }
    }
    
    func updateUI(){
        
        
        guard let configuration = self.site?.configuration, watchEntry = self.site?.watchEntry else {
            return
        }
        
        let units: Units = configuration.displayUnits
        
        let timeAgo = watchEntry.date.timeIntervalSinceNow
        let isStaleData = configuration.isDataStaleWith(interval: timeAgo)
        
        guard let sgvValue = watchEntry.sgv  else {
            #if DEBUG
                println("No SGV was found in the watch")
            #endif
            
            return
        }
        
        let defaultTextColor = NSAssetKitWatchOS.predefinedNeutralColor
        
        var sgvString: String = ""
        var sgvColor: UIColor = defaultTextColor
        
        var deltaString: String = ""
        
        var isRawDataAvailable: Bool = false
        var rawString: String = ""
        var rawColor: UIColor = defaultTextColor
        
        var batteryString: String = watchEntry.batteryString
        var batteryColor: UIColor = colorForDesiredColorState(watchEntry.batteryColorState)
        
        var lastUpdatedColor: UIColor = defaultTextColor
        
        var boundedColor = configuration.boundedColorForGlucoseValue(sgvValue.sgv)
        if units == .Mmol {
            boundedColor = configuration.boundedColorForGlucoseValue(sgvValue.sgv.toMgdl)
        }
        
        sgvString =  "\(sgvValue.sgvString)"// \(sgvValue.direction.emojiForDirection)"
        deltaString = "\(watchEntry.bgdelta.formattedForBGDelta) \(units.description)"
        sgvColor = colorForDesiredColorState(boundedColor)
        
        if let enabledOptions = configuration.enabledOptions {
            let rawEnabled =  enabledOptions.contains(EnabledOptions.rawbg)
            isRawDataAvailable = true
            if rawEnabled {
                if let rawValue = watchEntry.raw {
                    rawColor = colorForDesiredColorState(configuration.boundedColorForGlucoseValue(rawValue))
                    
                    var raw = "\(rawValue.formattedForMgdl)"
                    if configuration.displayUnits == .Mmol {
                        raw = rawValue.formattedForMmol
                    }
                    
                    rawString = "\(raw) : \(sgvValue.noise)"
                }
                
            }
        }
        
        
        var isArrowVisible : Bool = true
        var isDoubleUp : Bool = false
        var angle: CGFloat = 0
        
        switch sgvValue.direction {
        case .None:
            isArrowVisible = false
        case .DoubleUp:
            isDoubleUp = true
        case .SingleUp:
            break
        case .FortyFiveUp:
            angle = -45
        case .Flat:
            angle = -90
        case .FortyFiveDown:
            angle = -120
        case .SingleDown:
            angle = -180
        case .DoubleDown:
            isDoubleUp = true
            angle = -180
        case .NotComputable:
            isArrowVisible = false
        case .RateOutOfRange:
            isArrowVisible = false
        }
        
        if isStaleData.warn {
            
            batteryString = ("---%")
            batteryColor = defaultTextColor
            
            rawString = "--- : ---"
            rawColor = defaultTextColor
            
            deltaString = "- --/--"
            
            sgvString = "---"
            sgvColor = colorForDesiredColorState(.Neutral)
            
            isArrowVisible = false
        }
        
        if isStaleData.urgent{
            lastUpdatedColor = NSAssetKitWatchOS.predefinedAlertColor
        }
        

        let compassAlpha: CGFloat = isStaleData.warn ? 0.5 : 1.0
        
        let frame = self.contentFrame
        let smallest = min(min(frame.height, frame.width), 134)
        let groupFrame = CGRect(x: 0, y: 0, width: smallest, height: smallest)
        
        let image = NSAssetKitWatchOS.imageOfWatchFace(arrowTintColor: sgvColor, rawColor: rawColor, isDoubleUp: isDoubleUp, isArrowVisible: isArrowVisible, isRawEnabled: isRawDataAvailable, deltaString: deltaString, sgvString: sgvString, rawString: rawString, angle: angle, watchFrame: groupFrame)
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            // self.animateWithDuration(0.1, animations: { () -> Void in
            
            self.compassImage.setAlpha(compassAlpha)
            self.compassImage.setImage(image)
            self.setTitle(configuration.displayName)
            
            // Battery label
            self.batteryLabel.setText(batteryString)
            self.batteryLabel.setTextColor(batteryColor)
            
            // Last reading label
            self.lastUpdateLabel.setText(watchEntry.dateTimeAgoString)
            self.lastUpdateLabel.setTextColor(lastUpdatedColor)
            
            // })
        })
        
        
    }
    
    
}

