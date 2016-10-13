//
//  SitesTableInterfaceController.swift
//  Nightscouter
//
//  Created by Peter Ina on 10/4/15.
//  Copyright © 2015 Peter Ina. All rights reserved.
//

import WatchKit
import NightscouterWatchOSKit

class SitesTableInterfaceController: WKInterfaceController, SitesDataSourceProvider {
    
    @IBOutlet var tableView: WKInterfaceTable!
    @IBOutlet var loadingLabel: WKInterfaceLabel!
    
    struct ControllerName {
        static let SiteDetail: String = "SiteDetail"
    }
    
    struct RowIdentifier {
        static let rowSiteTypeIdentifier = "SiteRowController"
        static let rowEmptyTypeIdentifier = "SiteEmptyRowController"
        static let rowUpdateTypeIdentifier = "SiteUpdateRowController"
    }
    
    var sites: [Site] {
        return SitesDataSource.sharedInstance.sites
    }
    
    // Whenever this changes, it updates the attributed title of the refresh control.
    var milliseconds: Double = 0 {
        didSet{
            timeStamp = AppConfiguration.lastUpdatedFromPhoneDateFormatter.string(from: date)
            loadingLabel.setHidden(!self.sites.isEmpty)
        }
    }
    
    var timeStamp: String = ""
    
    var currentlyUpdating: Bool = false {
        didSet{
            self.loadingLabel.setHidden(!currentlyUpdating)
        }
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        print(">>> Entering \(#function) <<<")
        
        setupNotifications()
        
        updateTableData()
    }
    
    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        // set the currently selected object in the datasource
        SitesDataSource.sharedInstance.lastViewedSiteIndex = rowIndex
        // push controller on to the navigation stack.
        pushController(withName: ControllerName.SiteDetail, context: [DefaultKey.lastViewedSiteIndex.rawValue: rowIndex])
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate func setupNotifications() {
        NotificationCenter.default.addObserver(forName: .NightscoutDataStaleNotification, object: nil, queue: .main) { (notif) in
            print(">>> Entering \(#function) <<<")
            self.milliseconds = Date().timeIntervalSince1970.millisecond
            self.updateButton()
        }
    }
    
    fileprivate func updateTableData() {
        print(">>> Entering \(#function) <<<")
        
        if self.sites.isEmpty {
            self.loadingLabel.setHidden(true)
            
            self.tableView.setNumberOfRows(1, withRowType: RowIdentifier.rowEmptyTypeIdentifier)
            let row = self.tableView.rowController(at: 0) as? SiteEmptyRowController
            if let row = row {
                row.messageLabel.setText(LocalizedString.emptyTableViewCellTitle.localized)
            }
            
        } else {
            self.tableView.setHidden(false)
            
            var rowSiteType = self.sites.map{ _ in RowIdentifier.rowSiteTypeIdentifier }
            rowSiteType.append(RowIdentifier.rowUpdateTypeIdentifier)
            
            self.tableView.setRowTypes(rowSiteType)
            
            for (index, site) in self.sites.enumerated() {
                if let row = self.tableView.rowController(at: index) as? SiteRowController {
                    let model = site.summaryViewModel
                    row.configure(withDataSource: model, delegate: model)
                }
                
                if site.updateNow {
                    refreshDataFor(site, index: index)
                }
            }
            
            let updateRow = self.tableView.rowController(at: self.sites.count) as? SiteUpdateRowController
            
            if let updateRow = updateRow {
                updateRow.siteLastReadingLabel.setText(self.timeStamp)
                updateRow.siteLastReadingLabelHeader.setText(LocalizedString.updateDateFromPhoneString.localized)
            }
        }
    }
    
    @IBAction func updateButton() {
        print(">>> Entering \(#function) <<<")
        for (index, site) in self.sites.enumerated() {
            self.refreshDataFor(site, index: index, userInitiated: true)
        }
    }
    
    func refreshDataFor(_ site: Site, index: Int, userInitiated: Bool = false) {
        print(">>> Entering \(#function) <<<")
        /// Tie into networking code.
        currentlyUpdating = true
        site.fetchDataFromNetwork(userInitiated: userInitiated) { (updatedSite, err) in
            
            self.currentlyUpdating = false
            if let error = err {
                // DispatchQueue.main.async {
                self.presentErrorDialog(withTitle: LocalizedString.cannotUpdate.localized, message: error.localizedDescription)
                //}
                return
            }
            
            SitesDataSource.sharedInstance.updateSite(updatedSite)
            self.milliseconds = updatedSite.milliseconds
            #if os(watchOS)
                ///Complications need to be updated smartly... also background refresh needs to be taken into account
                let complicationServer = CLKComplicationServer.sharedInstance()
                if let activeComplications = complicationServer.activeComplications {
                    for complication in activeComplications {
                        complicationServer.reloadTimeline(for: complication)
                    }
                }
            #endif
            
            self.updateTableData()
        }
    }
    
    func presentErrorDialog(withTitle title: String, message: String) {
        // catch any errors here
        let retry = WKAlertAction(title: LocalizedString.generalRetryLabel.localized, style: .default, handler: { () -> Void in
            self.updateButton()
        })
        
        let cancel = WKAlertAction(title: LocalizedString.generalCancelLabel.localized, style: .cancel, handler: { () -> Void in
            self.dismiss()
        })
        
        //DispatchQueue.main.sync {
        self.presentAlert(withTitle: title, message: message, preferredStyle: .alert, actions: [retry, cancel])
        //}
    }
    
    
    
    override func handleUserActivity(_ userInfo: [AnyHashable : Any]?) {
        
        print(">>> Entering \(#function) <<<")
        
        guard let index = userInfo?[DefaultKey.lastViewedSiteIndex.rawValue] as? Int else {
            return
        }
        
        DispatchQueue.main.sync {
            self.pop()
            self.dismiss()
            
            SitesDataSource.sharedInstance.lastViewedSiteIndex = index
            
            self.pushController(withName: ControllerName.SiteDetail, context: [DefaultKey.lastViewedSiteIndex.rawValue: index])
        }
    }
    
}


