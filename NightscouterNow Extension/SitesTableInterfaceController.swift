

//
//  SitesTableInterfaceController.swift
//  Nightscouter
//
//  Created by Peter Ina on 10/4/15.
//  Copyright © 2015 Peter Ina. All rights reserved.
//

import WatchKit
import NightscouterWatchOSKit

class SitesTableInterfaceController: WKInterfaceController, SitesDataSourceProvider, SiteDetailViewDidUpdateItemDelegate {
    
    var sites: [Site] {
        return SitesDataSource.sharedInstance.sites
    }
    
    @IBOutlet var sitesTable: WKInterfaceTable!
    @IBOutlet var sitesLoading: WKInterfaceLabel!
    
    // Whenever this changes, it updates the attributed title of the refresh control.
    var lastUpdatedTime: Date? {
        didSet{
            
            // Create and use a formatter.
            let dateFormatter = DateFormatter()
            dateFormatter.timeStyle = DateFormatter.Style.short
            dateFormatter.dateStyle = DateFormatter.Style.short
            dateFormatter.timeZone = TimeZone.autoupdatingCurrent
            
            if let date = lastUpdatedTime {
                timeStamp = dateFormatter.string(from: date)
            }
            
            sitesLoading.setHidden(!self.sites.isEmpty)
        }
    }
    
    var timeStamp: String = ""
    
    var currentlyUpdating: Bool = false
    
    override func willActivate() {
        super.willActivate()
//        WatchSessionManager.sharedManager.addDataSourceChangedDelegate(self)
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        print(">>> Entering \(#function) <<<")
     
//        self.models = WatchSessionManager.sharedManager.models
        self.updateTableData()

//        let model = models.min{ (lModel, rModel) -> Bool in
//            return rModel.lastReadingDate.compare(lModel.lastReadingDate) == .orderedAscending
//        }
        
//        self.lastUpdatedTime = model?.lastReadingDate ?? Date(timeIntervalSince1970: 0)
        
        //WatchSessionManager.sharedManager.updateData(forceRefresh: false)
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        print(">>> Entering \(#function) <<<")
        super.didDeactivate()
        lastUpdatedTime = nil
        
        //WatchSessionManager.sharedManager.removeDataSourceChangedDelegate(self)
    }
    
    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        // create object.
        // push controller...
        print(">>> Entering \(#function) <<<")
        
//        WatchSessionManager.sharedManager.currentSiteIndex = rowIndex
        
//        pushController(withName: "SiteDetail", context: [WatchModel.PropertyKey.delegateKey: self])
    }
    
    fileprivate func updateTableData() {
        print(">>> Entering \(#function) <<<")
        DispatchQueue.main.async {

        let rowSiteTypeIdentifier: String = "SiteRowController"
        let rowEmptyTypeIdentifier: String = "SiteEmptyRowController"
        let rowUpdateTypeIdentifier: String = "SiteUpdateRowController"
        
            self.sitesTable.setNumberOfRows(0, withRowType: rowEmptyTypeIdentifier)
/*
            
        if self.models.isEmpty {
            self.sitesLoading.setHidden(true)
            
            self.sitesTable.setNumberOfRows(1, withRowType: rowEmptyTypeIdentifier)
            let row = self.sitesTable.rowController(at: 0) as? SiteEmptyRowController
            if let row = row {
                row.messageLabel.setText("No sites availble.")
            }
            
        } else {
            
            var rowSiteType = self.models.map{ _ in rowSiteTypeIdentifier }
            // datestamp/loading row
            rowSiteType.append(rowUpdateTypeIdentifier)
            
            self.sitesTable.setRowTypes(rowSiteType)
            
            for (index, model) in self.models.enumerated() {
                if let row = self.sitesTable.rowController(at: index) as? SiteRowController {
                    row.model = model
                }
            }
            
            let updateRow = self.sitesTable.rowController(at: self.models.count) as? SiteUpdateRowController
            if let updateRow = updateRow {
                updateRow.siteLastReadingLabel.setText(self.timeStamp)
                updateRow.siteLastReadingLabelHeader.setText("LAST UPDATE FROM PHONE")
            }
            }
        }*/
    }
    
        /*
    func dataSourceDidUpdateAppContext(_ models: [WatchModel]) {
        print(">>> Entering \(#function) <<<")
        OperationQueue.main.addOperation { 
            
        self.dismiss()
        self.models = models // WatchSessionManager.sharedManager.models
        self.lastUpdatedTime = Date()
        self.updateTableData()
            
        }

    }
    
    func dataSourceCouldNotConnectToPhone(_ error: Error) {
        self.presentErrorDialog(withTitle: "Phone not Reachable", message: error.localizedDescription)
    }
    
    func didUpdateItem(_ model: WatchModel){
        OperationQueue.main.addOperation {
            
            self.dismiss()
            self.models = WatchSessionManager.sharedManager.models
            self.lastUpdatedTime = Date()
            self.updateTableData()
        }
    }
    
    func didSetItemAsDefault(_ model: WatchModel) {
        WatchSessionManager.sharedManager.defaultSiteUUID = UUID(uuidString: model.uuid)
    }
    
    func presentErrorDialog(withTitle title: String, message: String) {
        // catch any errors here
        let retry = WKAlertAction(title: "Retry", style: .default, handler: { () -> Void in
            WatchSessionManager.sharedManager.updateData(forceRefresh: true)
        })
        
        let cancel = WKAlertAction(title: "Cancel", style: .cancel, handler: { () -> Void in
            self.dismiss()
        })
        
        let action = WKAlertAction(title: "Local Update", style: .default, handler: { () -> Void in
            for model in self.models {
                self.currentlyUpdating = true
                quickFetch(model.generateSite(), handler: { (returnedSite, error) -> Void in
                    OperationQueue.main.addOperation { () -> Void in
                        self.currentlyUpdating = false
                        WatchSessionManager.sharedManager.updateModel(returnedSite.viewModel)
                    }
                })
            }
            
        })
        
        DispatchQueue.main.async {
            self.presentAlert(withTitle: title, message: message, preferredStyle: .alert, actions: [retry, cancel, action])
        }
    }
    
    @IBAction func updateButton() {
        WatchSessionManager.sharedManager.updateData(forceRefresh: true)
    }
    
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
}

