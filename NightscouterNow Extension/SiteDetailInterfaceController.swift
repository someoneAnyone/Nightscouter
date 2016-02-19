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
        didSet {
            
            if let model = model {
                if model.updateNow {
                    print("time to update")
                    updateData()
                }
                self.configureView(model)
            }
        }
    }
    
    override func willActivate() {
        super.willActivate()
        print("willActivate")
        WatchSessionManager.sharedManager.addDataSourceChangedDelegate(self)
        
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
        
        // Remove this class from the observer list. Was listening for a global update timer.
        WatchSessionManager.sharedManager.removeDataSourceChangedDelegate(self)
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func dataSourceDidUpdateAppContext(models: [WatchModel]) {
        if let model = self.model, index = models.indexOf(model) {
            self.model = models[index]
        }
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
        print(">>> Entering \(__FUNCTION__) <<<")
        
        let messageToSend = [WatchModel.PropertyKey.actionKey: WatchAction.AppContext.rawValue]
        
        WatchSessionManager.sharedManager.session.sendMessage(messageToSend, replyHandler: {(context:[String : AnyObject]) -> Void in
            // handle reply from iPhone app here
            print("recievedMessageReply from iPhone")
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                print("WatchSession success...")                
                WatchSessionManager.sharedManager.processApplicationContext(context)
            })
            }, errorHandler: {(error: NSError ) -> Void in
                print("WatchSession Transfer Error: \(error)")
                
                self.presentErrorDialog(withTitle: "Phone not Reachable", message: error.localizedDescription)
        })
    }
    
    func presentErrorDialog(withTitle title: String, message: String, forceRefresh refresh: Bool = false) {
        // catch any errors here
            let retry = WKAlertAction(title: "Retry", style: .Default, handler: { () -> Void in
                self.updateData()
            })
            
            let action = WKAlertAction(title: "Local Update", style: .Default, handler: { () -> Void in
                if let model = self.model {
                    if model.updateNow || refresh {
                        fetchSiteData(model.generateSite(), handler: { (returnedSite, error) -> Void in
                            NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
                                WatchSessionManager.sharedManager.updateModel(returnedSite.viewModel)
                                self.model = returnedSite.viewModel
                            }
                        })
                    }
                }
            })
        NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
            self.presentAlertControllerWithTitle(title, message: message, preferredStyle: .Alert, actions: [retry, action])
        })
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
        
        NSOperationQueue.mainQueue().addOperationWithBlock {
            
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
        updateData()
    }
    
    @IBAction func setAsDefaultSite(){
        if let model = self.model {
            dispatch_async(dispatch_get_main_queue()) { [weak self] in
                self?.delegate?.didSetItemAsDefault(model)
            }
        }
    }
    
    override func handleUserActivity(userInfo: [NSObject : AnyObject]?) {
        print(">>> Entering \(__FUNCTION__) <<<")
        
        guard let dict = userInfo?[WatchModel.PropertyKey.modelKey] as? [String : AnyObject], incomingModel = WatchModel (fromDictionary: dict) else {
            return
        }
        
        NSOperationQueue.mainQueue().addOperationWithBlock {
            let modelDict = incomingModel.dictionary
            self.awakeWithContext(modelDict)
        }
    }
    
}

