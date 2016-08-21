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
    func didSetItemAsDefault(model: WatchModel)
}

class SiteDetailInterfaceController: WKInterfaceController, DataSourceChangedDelegate {
    
    @IBOutlet var compassGroup: WKInterfaceGroup!
    @IBOutlet var detailGroup: WKInterfaceGroup!
    @IBOutlet var lastUpdateLabel: WKInterfaceLabel!
    @IBOutlet var lastUpdateHeader: WKInterfaceLabel!
    @IBOutlet var batteryLabel: WKInterfaceLabel!
    @IBOutlet var batteryHeader: WKInterfaceLabel!
    @IBOutlet var compassImage: WKInterfaceImage!
    
    @IBOutlet var siteUpdateTimer: WKInterfaceTimer!
    
    var delegate: SiteDetailViewDidUpdateItemDelegate?
    
    var model: WatchModel? {
        didSet{
            self.configureView()
        }
    }
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        if let delegate = context![WatchModel.PropertyKey.delegateKey] as? SiteDetailViewDidUpdateItemDelegate { self.delegate = delegate }
    }
    
    override func willActivate() {
        super.willActivate()
        print("willActivate")
        
        if WatchSessionManager.sharedManager.models.isEmpty { popController() }
        
        self.model = WatchSessionManager.sharedManager.models[WatchSessionManager.sharedManager.currentSiteIndex]
        
        let image = NSAssetKitWatchOS.imageOfWatchFace()
        compassImage.setImage(image)
        
        self.configureView()
        
        WatchSessionManager.sharedManager.addDataSourceChangedDelegate(self)
        WatchSessionManager.sharedManager.updateData(forceRefresh: false)
    }
    
    
    override func didDeactivate() {
        super.didDeactivate()
        print("didDeactivate \(self)")
        
        // Remove this class from the observer list. Was listening for a global update timer.
        WatchSessionManager.sharedManager.removeDataSourceChangedDelegate(self)
        
        // NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func dataSourceDidUpdateAppContext(models: [WatchModel]) {
        dispatch_async(dispatch_get_main_queue()) { [weak self] in
            let model = WatchSessionManager.sharedManager.models[WatchSessionManager.sharedManager.currentSiteIndex]
            self?.model = model
            self?.delegate?.didUpdateItem(model)
        }
    }
    
    func dataSourceCouldNotConnectToPhone(error: NSError) {
        self.presentErrorDialog(withTitle: "Phone not Reachable", message: error.localizedDescription)
    }
    
    func presentErrorDialog(withTitle title: String, message: String, forceRefresh refresh: Bool = false) {
        // catch any errors here
        let retry = WKAlertAction(title: "Retry", style: .Default, handler: { () -> Void in
            WatchSessionManager.sharedManager.updateData(forceRefresh: true)
        })
        
        let cancel = WKAlertAction(title: "Cancel", style: .Cancel, handler: { () -> Void in
            self.dismissController()
        })
        
        guard let model = model else {
            return
        }
        
        let action = WKAlertAction(title: "Local Update", style: .Default, handler: { () -> Void in
            if model.updateNow || refresh {
                fetchSiteData(model.generateSite(), handler: { (returnedSite, error) -> Void in
                    WatchSessionManager.sharedManager.updateModel(returnedSite.viewModel)
                    self.configureView()
                })
            }
        })
        NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
            self.presentAlertControllerWithTitle(title, message: message, preferredStyle: .Alert, actions: [retry, action, cancel])
        })
    }
    
    func configureView(){
        
        guard let model = self.model else {
            return
        }
        
        NSOperationQueue.mainQueue().addOperationWithBlock {
            let compassAlpha: CGFloat = model.warn ? 0.5 : 1.0
            
            let frame = self.contentFrame
            let smallest = min(min(frame.height, frame.width), 134)
            let groupFrame = CGRect(x: 0, y: 0, width: smallest, height: smallest)
            
            let sgvColor = UIColor(hexString: model.sgvColor)
            let rawColor = UIColor(hexString: model.rawColor)
            let batteryColor = UIColor(hexString: model.batteryColor)
            let lastReadingColor = UIColor(hexString: model.lastReadingColor)
            
            let image = NSAssetKitWatchOS.imageOfWatchFace(arrowTintColor: sgvColor, rawColor: rawColor, isDoubleUp: model.isDoubleUp, isArrowVisible: model.isArrowVisible, isRawEnabled: model.rawVisible, deltaString: model.deltaString, sgvString: model.sgvString, rawString: model.rawString, angle: model.angle, watchFrame: groupFrame)
            
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
        WatchSessionManager.sharedManager.updateData(forceRefresh: true)
    }
    
    @IBAction func setAsDefaultSite(){
        dispatch_async(dispatch_get_main_queue()) { [weak self] in
            self?.delegate?.didSetItemAsDefault(self!.model!)
        }
    }
    
    override func handleUserActivity(userInfo: [NSObject : AnyObject]?) {
        print(">>> Entering \(#function) <<<")
        
        guard let dict = userInfo?[WatchModel.PropertyKey.modelKey] as? [String : AnyObject], incomingModel = WatchModel (fromDictionary: dict) else {
            return
        }
        
        if let index = WatchSessionManager.sharedManager.models.indexOf(incomingModel) {
            WatchSessionManager.sharedManager.currentSiteIndex = index
        }
        
        dispatch_async(dispatch_get_main_queue()) {
            let modelDict = incomingModel.dictionary
            // self.awakeWithContext(modelDict)
            self.model = WatchModel(fromDictionary: modelDict)
        }
    }
    
}

