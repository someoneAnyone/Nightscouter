

//
//  SitesTableInterfaceController.swift
//  Nightscouter
//
//  Created by Peter Ina on 10/4/15.
//  Copyright © 2015 Peter Ina. All rights reserved.
//

import WatchKit
import NightscouterWatchOSKit

class SitesTableInterfaceController: WKInterfaceController, DataSourceChangedDelegate, SiteDetailViewDidUpdateItemDelegate {
    
    @IBOutlet var sitesTable: WKInterfaceTable!
    
    var models: [WatchModel] {
        return WatchSessionManager.sharedManager.models
    }
    
    var nsApi: [NightscoutAPIClient]?
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        print(">>> Entering \(__FUNCTION__) <<<")
    }
    
    override func willActivate() {
        super.willActivate()
        print(">>> Entering \(__FUNCTION__) <<<")
        
        WatchSessionManager.sharedManager.addDataSourceChangedDelegate(self)
        
        setupNotifications()
        
        updateTableData()
        updateData(forceRefresh: false)
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        print(">>> Entering \(__FUNCTION__) <<<")
        super.didDeactivate()
        
        WatchSessionManager.sharedManager.removeDataSourceChangedDelegate(self)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func setupNotifications() {
        // Listen for global update timer.
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("dataStaleUpdate:"), name: NightscoutAPIClientNotification.DataIsStaleUpdateNow, object: nil)
    }
    
    override func table(table: WKInterfaceTable, didSelectRowAtIndex rowIndex: Int) {
        // create object.
        // push controller...
        print(">>> Entering \(__FUNCTION__) <<<")
        
        let model = models[rowIndex]
        
        pushControllerWithName("SiteDetail", context: [WatchModel.PropertyKey.delegateKey: self, WatchModel.PropertyKey.modelKey: model.dictionary])
    }
    
    private func updateTableData() {
        print(">>> Entering \(__FUNCTION__) <<<")
        
        let rowSiteTypeIdentifier: String = "SiteRowController"
        let rowEmptyTypeIdentifier: String = "SiteEmptyRowController"
        
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            
            if self.models.isEmpty {
                self.sitesTable.setNumberOfRows(1, withRowType: rowEmptyTypeIdentifier)
                let row = self.sitesTable.rowControllerAtIndex(0) as? SiteEmptyRowController
                if let row = row {
                    
                    row.messageLabel.setText("No sites availble.")
                    
                }
            } else {
                
                self.sitesTable.setNumberOfRows(self.models.count, withRowType: rowSiteTypeIdentifier)
                for (index, model) in self.models.enumerate() {
                    if let row = self.sitesTable.rowControllerAtIndex(index) as? SiteRowController {
                        row.model = model
                    }
                }
                
            }
        }
    }
    
    func dataSourceDidUpdateAppContext(models: [WatchModel]) {
        print(">>> Entering \(__FUNCTION__) <<<")
        updateTableData()
    }
    
    func didUpdateItem(model: WatchModel) {
        print(">>> Entering \(__FUNCTION__) <<<")
        WatchSessionManager.sharedManager.updateModel(model)
    }
    
    func didSetItemAsDefault(model: WatchModel) {
        WatchSessionManager.sharedManager.defaultSiteUUID = NSUUID(UUIDString: model.uuid)
    }
    
    func dataStaleUpdate(notif: NSNotification) {
        updateData(forceRefresh: true)
    }
    
    func updateData(forceRefresh refresh: Bool) {
        print(">>> Entering \(__FUNCTION__) <<<")
        
        let ok = WKAlertAction(title: "OK", style: .Default) { () -> Void in
            self.dismissController()
        }
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
        self.presentAlertControllerWithTitle("Loading...", message: "Getting the latest readings your phone.", preferredStyle: WKAlertControllerStyle.Alert, actions: [ok])
        }
        let messageToSend = [WatchModel.PropertyKey.actionKey: WatchAction.AppContext.rawValue]
        WatchSessionManager.sharedManager.session.sendMessage(messageToSend, replyHandler: {(context:[String : AnyObject]) -> Void in
            // handle reply from iPhone app here
            print("recievedMessageReply from iPhone")
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                WatchSessionManager.sharedManager.processApplicationContext(context)
                self.updateTableData()
                self.dismissController()
            })    
            }, errorHandler: {(error: NSError ) -> Void in
                print("WatchSession Transfer Error: \(error)")
                self.presentErrorDialog(withTitle: "Phone not Reachable", message: error.localizedDescription, forceRefresh: refresh)
        })
    }
    
    func presentErrorDialog(withTitle title: String, message: String, forceRefresh refresh: Bool = false) {
        // catch any errors here
        NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
            
            let retry = WKAlertAction(title: "Retry", style: .Default, handler: { () -> Void in
                self.updateData(forceRefresh: true)
            })
            
            let action = WKAlertAction(title: "Local Update", style: .Default, handler: { () -> Void in
                for model in self.models {
                    if model.lastReadingDate.dateByAddingTimeInterval(Constants.NotableTime.StandardRefreshTime).compare(model.lastReadingDate) == .OrderedAscending || refresh {
                        quickFetch(model.generateSite(), handler: { (returnedSite, error) -> Void in
                            NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
                                WatchSessionManager.sharedManager.updateModel(returnedSite.viewModel)
                                self.updateTableData()
                            }
                        })
                    }
                }
                
            })
            self.presentAlertControllerWithTitle(title, message: message, preferredStyle: .Alert, actions: [retry, action])
        })
    }
    
    @IBAction func updateButton() {
        updateData(forceRefresh: true)
    }
    
    override func handleUserActivity(userInfo: [NSObject : AnyObject]?) {
        print(">>> Entering \(__FUNCTION__) <<<")
        
        guard let dict = userInfo?[WatchModel.PropertyKey.modelKey] as? [String : AnyObject], incomingModel = WatchModel (fromDictionary: dict) else {
            
            return
        }
        
        NSOperationQueue.mainQueue().addOperationWithBlock {
            self.dismissController()
            self.pushControllerWithName("SiteDetail", context: [WatchModel.PropertyKey.delegateKey: self, WatchModel.PropertyKey.modelKey: incomingModel.dictionary])
        }
    }
}

