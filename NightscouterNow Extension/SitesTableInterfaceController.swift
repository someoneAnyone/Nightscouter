

//
//  SitesTableInterfaceController.swift
//  Nightscouter
//
//  Created by Peter Ina on 10/4/15.
//  Copyright © 2015 Peter Ina. All rights reserved.
//

import WatchKit
import NightscouterWatchOSKit

class SitesTableInterfaceController: WKInterfaceController, SitesDataSourceProvider {//, SiteDetailViewDidUpdateItemDelegate {
    
    @IBOutlet var sitesTable: WKInterfaceTable!
    @IBOutlet var sitesLoading: WKInterfaceLabel!
    
    
    var sites: [Site] = [] {
        didSet{
            updateTableData()
        }
    }
    struct ControllerName {
        static let SiteDetail: String = "SiteDetail"
    }
    
    struct RowIdentifier {
        static let rowSiteTypeIdentifier = "SiteRowController"
        static let rowEmptyTypeIdentifier = "SiteEmptyRowController"
        static let rowUpdateTypeIdentifier = "SiteUpdateRowController"
    }
    
    
    // Whenever this changes, it updates the attributed title of the refresh control.
    var milliseconds: Double? {
        didSet{
            timeStamp = AppConfiguration.lastUpdatedFromPhoneDateFormatter.string(from: date)
            sitesLoading.setHidden(!self.sites.isEmpty)
        }
    }
    
    var timeStamp: String = ""
    
    var currentlyUpdating: Bool = false
    
    override func willActivate() {
        super.willActivate()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        print(">>> Entering \(#function) <<<")
     
        sites = SitesDataSource.sharedInstance.sites
        
        NotificationCenter.default.addObserver(forName: .NightscoutDataUpdatedNotification, object: nil, queue: OperationQueue.main) { (notif) in
            self.milliseconds = Date().timeIntervalSince1970.millisecond
            self.sites = SitesDataSource.sharedInstance.sites
        }
        
        NotificationCenter.default.addObserver(forName: .NightscoutDataStaleNotification, object: nil, queue: .main) { (notif) in
            self.milliseconds = Date().timeIntervalSince1970.millisecond
            self.sites = SitesDataSource.sharedInstance.sites
            
        }
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        print(">>> Entering \(#function) <<<")
        super.didDeactivate()
        for (index, site) in self.sites.enumerated() {
            self.refreshDataFor(site, index: index, userInitiated: false)
        }

    }
    
    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        // create object.
        // push controller...
        print(">>> Entering \(#function) <<<")
        
        SitesDataSource.sharedInstance.lastViewedSiteIndex = rowIndex
        
        pushController(withName: ControllerName.SiteDetail, context: [DefaultKey.lastViewedSiteIndex.rawValue: rowIndex])
    }
    
    fileprivate func updateTableData() {
        print(">>> Entering \(#function) <<<")
        
        if self.sites.isEmpty {
            self.sitesLoading.setHidden(true)
            
            self.sitesTable.setNumberOfRows(1, withRowType: RowIdentifier.rowEmptyTypeIdentifier)
            let row = self.sitesTable.rowController(at: 0) as? SiteEmptyRowController
            if let row = row {
                row.messageLabel.setText(LocalizedString.emptyTableViewCellTitle.localized)
            }
            
        } else {
            self.sitesLoading.setHidden(true)
            
            var rowSiteType = self.sites.map{ _ in RowIdentifier.rowSiteTypeIdentifier }
            rowSiteType.append(RowIdentifier.rowUpdateTypeIdentifier)
            
            self.sitesTable.setRowTypes(rowSiteType)
            
            for (index, site) in self.sites.enumerated() {
                if let row = self.sitesTable.rowController(at: index) as? SiteRowController {
                    let model = site.summaryViewModel
                    row.configure(withDataSource: model, delegate: model)
                }
            }
            
            let updateRow = self.sitesTable.rowController(at: self.sites.count) as? SiteUpdateRowController
            
            if let updateRow = updateRow {
                updateRow.siteLastReadingLabel.setText(self.timeStamp)
                updateRow.siteLastReadingLabelHeader.setText(LocalizedString.updateDateFromPhoneString.localized)
            }
        }
    }
    
    @IBAction func updateButton() {
        FIXME()
        for (index, site) in self.sites.enumerated() {
            self.refreshDataFor(site, index: index, userInitiated: true)
        }
    }
    
    func refreshDataFor(_ site: Site, index: Int, userInitiated: Bool = false){
        /// Tie into networking code.
        FIXME()
        
        
        site.fetchDataFromNetwrok(userInitiated: userInitiated) { (updatedSite, err) in
            if let error = err {
                OperationQueue.main.addOperation {
                    self.presentErrorDialog(withTitle: "Oh no!", message: error.localizedDescription)
                    
                }
                return
            }
            
            SitesDataSource.sharedInstance.updateSite(updatedSite)
            if let date = updatedSite.lastUpdatedDate {
                self.milliseconds = date.timeIntervalSince1970.millisecond
            }
            OperationQueue.main.addOperation {
               self.updateTableData()
            }
        }
    }

    func presentErrorDialog(withTitle title: String, message: String) {
        // catch any errors here
        let retry = WKAlertAction(title: "Retry", style: .default, handler: { () -> Void in
            
            self.updateButton()
        })
        
        let cancel = WKAlertAction(title: "Cancel", style: .cancel, handler: { () -> Void in
            self.dismiss()
        })

        DispatchQueue.main.async {
            self.presentAlert(withTitle: title, message: message, preferredStyle: .alert, actions: [retry, cancel])
        }
    }

    
        /*
    
    override func handleUserActivity(_ userInfo: [AnyHashable: Any]?) {
        print(">>> Entering \(#function) <<<")
        
        guard let dict = userInfo?[WatchModel.PropertyKey.modelKey] as? [String : AnyObject], let incomingModel = WatchModel (fromDictionary: dict) else {
            
            return
        }
        
        DispatchQueue.main.async {
            self.pop()
            self.dismiss()
            
            if let index = WatchSessionManager.sharedManager.models.index(of: incomingModel) {
                WatchSessionManager.sharedManager.currentSiteIndex = index
            }
            
            self.pushController(withName: "SiteDetail", context: [WatchModel.PropertyKey.delegateKey: self, WatchModel.PropertyKey.modelKey: incomingModel.dictionary])
        }
    }
 */
    }


