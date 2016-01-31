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
    func didUpdateItem(model: WatchModel)
}

class SiteDetailInterfaceController: WKInterfaceController {
    
    @IBOutlet var compassGroup: WKInterfaceGroup!
    @IBOutlet var detailGroup: WKInterfaceGroup!
    @IBOutlet var lastUpdateLabel: WKInterfaceLabel!
    @IBOutlet var lastUpdateHeader: WKInterfaceLabel!
    @IBOutlet var batteryLabel: WKInterfaceLabel!
    @IBOutlet var batteryHeader: WKInterfaceLabel!
    @IBOutlet var compassImage: WKInterfaceImage!
    
    @IBOutlet var siteUpdateTimer: WKInterfaceTimer!
    var nsApi: NightscoutAPIClient?
    
    var task: NSURLSessionDataTask?
    
    var isActive: Bool = false
    
    var delegate: SiteDetailViewDidUpdateItemDelegate?
    
    var model: WatchModel? {
        didSet {
            
            if let model = model {
                print("didSet WatchModel in SiteDetailInterfaceController")
                
                self.configureView(model)
                
                if (model.lastReadingDate.timeIntervalSinceNow < -Constants.NotableTime.StandardRefreshTime) {
                    updateData()
                }
                
            }
        }
    }
    // var lastUpdatedTime: NSDate?
    
    override func willActivate() {
        super.willActivate()
        print("willActivate")
        
        let image = NSAssetKitWatchOS.imageOfWatchFace()
        compassImage.setImage(image)
        
        if let model = model {
            self.configureView(model)
        }
        
        setupNotifications()
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
        
        // Remove this class from the observer list. Was listening for a global update timer.
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        if let modelDict = context![WatchModel.PropertyKey.modelKey] as? [String : AnyObject], model = WatchModel(fromDictionary: modelDict) { self.model = model }
        if let delegate = context![WatchModel.PropertyKey.delegateKey] as? SiteDetailViewDidUpdateItemDelegate { self.delegate = delegate }
        
    }
    
    func setupNotifications() {
        // Listen for global update timer.
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateData", name: NightscoutAPIClientNotification.DataIsStaleUpdateNow, object: nil)
    }
    
    func updateData(){
        self.isActive = true
        if let model = model {
            loadDataFor(model) { (model) -> Void in
                self.isActive = false
                self.model = model
                
                dispatch_async(dispatch_get_main_queue()) { [weak self] in
                    self?.delegate?.didUpdateItem(model)
                }
                
            }
        }
    }
    
    func configureView(model: WatchModel){
        
        let compassAlpha: CGFloat = model.warn ? 0.5 : 1.0
        
        let frame = self.contentFrame
        let smallest = min(min(frame.height, frame.width), 134)
        let groupFrame = CGRect(x: 0, y: 0, width: smallest, height: smallest)
        
        let sgvColor = UIColor(hexString: model.sgvColor)
        let rawColor = UIColor(hexString: model.rawColor)
        let batteryColor = UIColor(hexString: model.batteryColor)
        let lastReadingColor = UIColor(hexString: model.lastReadingColor)
        
        let image = NSAssetKitWatchOS.imageOfWatchFace(arrowTintColor: sgvColor, rawColor: rawColor, isDoubleUp: model.isDoubleUp, isArrowVisible: model.isArrowVisible, isRawEnabled: model.rawVisible, deltaString: model.deltaString, sgvString: model.sgvString, rawString: model.rawString, angle: model.angle, watchFrame: groupFrame)
        
        NSOperationQueue.mainQueue().addOperationWithBlock {
            self.setTitle(model.displayName)
            
            self.compassImage.setAlpha(compassAlpha)
            self.compassImage.setImage(image)
            
            // Battery label
            self.batteryLabel.setText(model.batteryString)
            self.batteryLabel.setTextColor(batteryColor)
            self.batteryLabel.setAlpha(compassAlpha)
            
            let date = NSCalendar.autoupdatingCurrentCalendar().stringRepresentationOfElapsedTimeSinceNow(model.lastReadingDate)
            // Last reading label
            self.lastUpdateLabel.setText(date)//watchModel.lastReadingString)
            self.lastUpdateLabel.setTextColor(lastReadingColor)
            
            self.siteUpdateTimer.setDate(model.lastReadingDate)
            self.siteUpdateTimer.setTextColor(lastReadingColor)
            
            // self.lastUpdatedTime = model.lastReadingDate
        }
    }
    
    @IBAction func updateButton() {
        updateData()
    }
    
    @IBAction func setAsDefaultSite(){
        
    }
}

