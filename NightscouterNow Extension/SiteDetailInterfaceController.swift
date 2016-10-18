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

//protocol SiteDetailViewDidUpdateItemDelegate {
//    func didUpdateItem(_ model: WatchModel)
//    func didSetItemAsDefault(_ model: WatchModel)
//}

class SiteDetailInterfaceController: WKInterfaceController {
    
    @IBOutlet var compassGroup: WKInterfaceGroup!
    @IBOutlet var detailGroup: WKInterfaceGroup!
    @IBOutlet var lastUpdateLabel: WKInterfaceLabel!
    @IBOutlet var lastUpdateHeader: WKInterfaceLabel!
    @IBOutlet var batteryLabel: WKInterfaceLabel!
    @IBOutlet var batteryHeader: WKInterfaceLabel!
    @IBOutlet var compassImage: WKInterfaceImage!
    
    @IBOutlet var siteUpdateTimer: WKInterfaceTimer!
    
    var site: Site? {
        didSet {
            self.configureView()
        }
    }
    
    override func willActivate() {
        super.willActivate()
        print("willActivate")
        
        self.configureView()

    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Interface Builder Actions
    
    @IBAction func updateButton() {
        print(">>> Entering \(#function) <<<")

        guard let site = site else { return }
        refreshDataFor(site)
    }
    
    func refreshDataFor(_ site: Site, index: Int = 0) {
        print(">>> Entering \(#function) <<<")
        /// Tie into networking code.
        site.fetchDataFromNetwork() { (updatedSite, err) in
            if let _ = err {
                return
            }
            
            SitesDataSource.sharedInstance.updateSite(updatedSite)
        }
    }
    
    @IBAction func setAsComplication() {
        // TODO: Create icon and function that sets current site as the watch complication.
        SitesDataSource.sharedInstance.primarySite = site
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        if let context = context as? [String: AnyObject],let index = context[DefaultKey.lastViewedSiteIndex.rawValue] as? Int {
            self.site = SitesDataSource.sharedInstance.sites[index]
        }
        
        setupNotifications()
    }
    
    fileprivate func setupNotifications() {
        NotificationCenter.default.addObserver(forName: .NightscoutDataStaleNotification, object: nil, queue: .main) { (notif) in
            print(">>> Entering \(#function) <<<")
            self.configureView()
        }
    }
    

    func configureView() {
        
        guard let site = self.site else {
            
            let image = NSAssetKitWatchOS.imageOfWatchFace()
            compassImage.setImage(image)
            compassImage.setAlpha(0.5)
            
            return
        }
        
        let dataSource = SiteSummaryModelViewModel(withSite: site)
        let compassAlpha: CGFloat = dataSource.lookStale ? 0.5 : 1.0
        //let timerHidden: Bool = dataSource.lookStale
        let image = self.createImage(dataSource: dataSource, delegate: dataSource, frame: calculateFrameForImage())
        
        //OperationQueue.main.addOperation {
            
            self.setTitle(dataSource.nameLabel)
            
            // Compass Image
            self.compassImage.setAlpha(compassAlpha)
            self.compassImage.setImage(image)
            
            // Battery label
            self.batteryLabel.setText(dataSource.batteryLabel)
            self.batteryLabel.setTextColor(dataSource.batteryColor)
            self.batteryHeader.setText(LocalizedString.batteryLabel.localized)
            self.batteryHeader.setHidden(dataSource.batteryHidden)
            self.batteryLabel.setHidden(dataSource.batteryHidden)
            
            // Last reading label
            self.lastUpdateLabel.setText(PlaceHolderStrings.date)
            self.lastUpdateLabel.setTextColor(PlaceHolderStrings.defaultColor.colorValue)
            self.lastUpdateLabel.setHidden(true)
            
            self.siteUpdateTimer.setDate(dataSource.lastReadingDate)
            self.siteUpdateTimer.setTextColor(dataSource.lastReadingColor)
            self.siteUpdateTimer.setHidden(false)
        //}
        
    }
    
    func calculateFrameForImage() -> CGRect {
        let frame = self.contentFrame
        let smallest = min(min(frame.height, frame.width), 134)
        let groupFrame = CGRect(x: 0, y: 0, width: smallest, height: smallest)
        
        return groupFrame
    }
    
    func createImage(dataSource:CompassViewDataSource, delegate:CompassViewDelegate, frame: CGRect) -> UIImage {
        let sgvColor = delegate.sgvColor
        let rawColor = delegate.rawColor
        
        let image = NSAssetKitWatchOS.imageOfWatchFace(frame, arrowTintColor: sgvColor, rawColor: rawColor , isDoubleUp: dataSource.direction.isDoubleRingVisible, isArrowVisible: dataSource.direction.isArrowVisible, isRawEnabled: !dataSource.rawHidden, deltaString: dataSource.deltaLabel, sgvString: dataSource.sgvLabel, rawString: dataSource.rawLabel , angle: CGFloat(dataSource.direction.angleForCompass))
        
        return image
    }
    
    override func handleUserActivity(_ userInfo: [AnyHashable: Any]?) {
        print(">>> Entering \(#function) <<<")
        
        guard let indexOfSite = userInfo?[DefaultKey.lastViewedSiteIndex] as? Int else {
            return
        }
        
        SitesDataSource.sharedInstance.lastViewedSiteIndex = indexOfSite
        
        DispatchQueue.main.async {
            self.site = SitesDataSource.sharedInstance.sites[indexOfSite]
        }
    }
}
