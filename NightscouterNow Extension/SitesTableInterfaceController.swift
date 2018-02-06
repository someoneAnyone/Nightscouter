//
//  SitesTableInterfaceController.swift
//  Nightscouter
//
//  Created by Peter Ina on 10/4/15.
//  Copyright © 2015 Peter Ina. All rights reserved.
//

import WatchKit
import NightscouterWatchOSKit
import WatchConnectivity

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
    var milliseconds: Mills? = 0 {
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
        
        NotificationCenter.default.removeObserver(self, name: .dataDidFlow, object: nil)
        NotificationCenter.default.removeObserver(self, name: .activationDidComplete, object: nil)
        NotificationCenter.default.removeObserver(self, name: .reachabilityDidChange, object: nil)
    }
    
    fileprivate func setupNotifications() {
        
        NotificationCenter.default.addObserver(forName: .nightscoutDataStaleNotification, object: nil, queue: .main) { (notif) in
            print(">>> Entering \(#function) <<<")
            self.milliseconds = Date().timeIntervalSince1970.millisecond
            self.updateButton()
        }
        // Install notification observer.
        //
        NotificationCenter.default.addObserver(
            self, selector: #selector(type(of:self).dataDidFlow(_:)),
            name: .dataDidFlow, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(type(of:self).activationDidComplete(_:)),
            name: .activationDidComplete, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(type(of:self).reachabilityDidChange(_:)),
            name: .reachabilityDidChange, object: nil
        )
        
    }
    
    // .dataDidFlow notification handler.
    // Update the UI based on the userInfo dictionary of the notification.
    //
    @objc func dataDidFlow(_ notification: Notification) {
        // Notification should have userInfo, which contains channel, phrase, and timedColor.
        //
        guard let aUserInfo = notification.userInfo as? [String: Any],
            let notificationChannel = aUserInfo[UserInfoKey.channel] as? Channel,
            let phrase = aUserInfo[UserInfoKey.phrase] as? Phrase,
            let siteData = aUserInfo[UserInfoKey.siteData] as? [String: Any] else { return }
        
        
        SitesDataSource.sharedInstance.sites = try! PropertyListDecoder().decode([Site].self, from: siteData["siteData"] as! Data)
        
        
        // If the data is from current channel, simple update color and time stamp, then return.
        //
        updateTableData()
    }
    
    // .activationDidComplete notification handler.
    //
    @objc func activationDidComplete(_ notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: Any],
            let activationStatus = userInfo[UserInfoKey.activationStatus] as? WCSessionActivationState
            else { return }
        
        print("\(#function): activationState:\(activationStatus.rawValue)")
    }
    
    // .reachabilityDidChange notification handler.
    //
    @objc func reachabilityDidChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: Any],
            let isReachable = userInfo[UserInfoKey.reachable] as? Bool else { return }
        
        print("\(#function): isReachable:\(isReachable)")
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
            self.refreshDataFor(site, index: index)
        }
    }
    
    func refreshDataFor(_ site: Site, index: Int) {
        print(">>> Entering \(#function) <<<")
        /// Tie into networking code.
        currentlyUpdating = true
        site.fetchDataFromNetwork() { (updatedSite, err) in
            
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


