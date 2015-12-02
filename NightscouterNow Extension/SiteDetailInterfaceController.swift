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
    func didUpdateItem(site: Site, withModel model: WatchModel)
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
    
    var model: WatchModel? {
        didSet {
            print("didSet WatchModel in SiteDetailInterfaceController")
            NSOperationQueue.mainQueue().addOperationWithBlock {
                self.configureView()
            }
            updateData()
        }
    }
    var lastUpdatedTime: NSDate?
    
    override func willActivate() {
        super.willActivate()
        print("willActivate")
        
        let image = NSAssetKitWatchOS.imageOfWatchFace()
        compassImage.setImage(image)
        
        self.isActive = true
        
        if let _ = model {
            NSOperationQueue.mainQueue().addOperationWithBlock {
                self.configureView()
            }
        }
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
        
        if let modelDict = context![WatchModel.PropertyKey.modelKey] as? [String : AnyObject], model = WatchModel(fromDictionary: modelDict) { self.model = model }
        if let delegate = context![WatchModel.PropertyKey.delegateKey] as? SiteDetailViewDidUpdateItemDelegate { self.delegate = delegate }
        
    }
    
    func updateData(){
        
        guard let model = self.model else {
            print("No model was found...")
            return
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            
            // Start up the API
            
            let url = NSURL(string: model.urlString)!
            
            let site = Site(url: url, apiSecret: nil)!
            self.nsApi = NightscoutAPIClient(url: site.url)
            
            if (self.lastUpdatedTime?.timeIntervalSinceNow > 120) || self.lastUpdatedTime == nil {
                
                // Get settings for a given site.
                // print("Loading data for \(site.url!)")
                self.nsApi!.fetchServerConfiguration { (result) -> Void in
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
                                self.model = WatchModel(fromSite: site)!
                                dispatch_async(dispatch_get_main_queue()) { [weak self] in
                                    self?.delegate?.didUpdateItem(site, withModel: (self?.model)!)
                                }
                            })
                        })
                    }
                }
            }
        }
    }
    
    func configureView(){
        
        let watchModel = self.model!
        
        let compassAlpha: CGFloat = watchModel.warn ? 0.5 : 1.0
        
        let frame = self.contentFrame
        let smallest = min(min(frame.height, frame.width), 134)
        let groupFrame = CGRect(x: 0, y: 0, width: smallest, height: smallest)
        
        let sgvColor = UIColor(hexString: watchModel.sgvColor)
        let rawColor = UIColor(hexString: watchModel.rawColor)
        let batteryColor = UIColor(hexString: watchModel.batteryColor)
        let lastReadingColor = UIColor(hexString: watchModel.lastReadingColor)
        
        let image = NSAssetKitWatchOS.imageOfWatchFace(arrowTintColor: sgvColor, rawColor: rawColor, isDoubleUp: watchModel.isDoubleUp, isArrowVisible: watchModel.isArrowVisible, isRawEnabled: watchModel.rawVisible, deltaString: watchModel.deltaString, sgvString: watchModel.sgvString, rawString: watchModel.rawString, angle: watchModel.angle, watchFrame: groupFrame)
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            
            self.setTitle(watchModel.displayName)
            
            self.compassImage.setAlpha(compassAlpha)
            self.compassImage.setImage(image)
            
            // Battery label
            self.batteryLabel.setText(watchModel.batteryString)
            self.batteryLabel.setTextColor(batteryColor)
            self.batteryLabel.setAlpha(compassAlpha)
            
            let date = NSCalendar.autoupdatingCurrentCalendar().stringRepresentationOfElapsedTimeSinceNow(watchModel.lastReadingDate)
            // Last reading label
            self.lastUpdateLabel.setText(date)//watchModel.lastReadingString)
            self.lastUpdateLabel.setTextColor(lastReadingColor)
            
            
            self.lastUpdatedTime = watchModel.lastReadingDate
        })
    }
}

