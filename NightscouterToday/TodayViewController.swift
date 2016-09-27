//
//  TodayViewController.swift
//  NightscouterToday
//
//  Created by Peter Ina on 8/12/15.
//  Copyright (c) 2015 Peter Ina. All rights reserved.
//

import UIKit
import NotificationCenter
import NightscouterKit

class TodayViewController: UITableViewController, NCWidgetProviding, SitesDataSourceProvider  {
    
    struct TableViewConstants {
        static let baseRowCount = 2
        static let todayRowHeight: CGFloat = 70
        
        struct CellIdentifiers {
            static let content = "nsSiteNow"
            static let message = "messageCell"
        }
    }
    
    var sites:[Site] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        self.sites = SitesDataSource.sharedInstance.sites

        tableView.backgroundColor = Color.clear
        tableView.estimatedRowHeight = TableViewConstants.todayRowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = Color(white: 1.0, alpha: 0.5)
        
        if #available(iOSApplicationExtension 10.0, *) {
            extensionContext?.widgetLargestAvailableDisplayMode = .expanded
            
            let effect = UIVibrancyEffect.widgetPrimary()
            tableView.separatorEffect = effect
        } else {
            
            let effect = UIVibrancyEffect.notificationCenter()
            tableView.separatorEffect = effect
            preferredContentSize = tableView.contentSize
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(TodayViewController.updateData), name: .NightscoutDataStaleNotification, object: nil)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: NCWidgetProviding
    
    func widgetMarginInsets(forProposedMarginInsets defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        return UIEdgeInsets(top: defaultMarginInsets.top, left: 0, bottom: defaultMarginInsets.bottom, right: defaultMarginInsets.right)
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        completionHandler(NCUpdateResult.newData)
    }
    
    @available(iOSApplicationExtension 10.0, *)
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        if (activeDisplayMode == .compact) {
            preferredContentSize = maxSize
        }
        else {
            preferredContentSize = tableView.contentSize
        }
    }
    
    
    // MARK: UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if (sites.isEmpty) {
            // Make sure to allow for a row to note that no incomplete items remain.
            return 1
        }
        
        return sites.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if sites.isEmpty {
            let cell = tableView.dequeueReusableCell(withIdentifier: TableViewConstants.CellIdentifiers.message, for: indexPath)
            
            cell.textLabel!.text = LocalizedString.emptyTableViewCellTitle.localized
            
            return cell
        } else {
            let contentCell = tableView.dequeueReusableCell(withIdentifier: TableViewConstants.CellIdentifiers.content, for: indexPath) as! SiteNSNowTableViewCell
            let site = sites[indexPath.row]
            let model = site.summaryViewModel
            
            contentCell.configure(withDataSource: model, delegate: model)
            
            let os = ProcessInfo().operatingSystemVersion
            if os.majorVersion >= 10 {
                contentCell.contentView.backgroundColor = Color(hexString: "1e1e1f")//Color.black.withAlphaComponent(0.7)
            }
            
            if site.updateNow {
                refreshDataFor(site, index: indexPath.row)
            }
            
            return contentCell
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.layer.backgroundColor = UIColor.clear.cgColor
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        openApp(with: indexPath)
    }
    
    
    // MARK: Private Methods
    
    func updateData(){
        // Do not allow refreshing to happen if there is no data in the sites array.
        if sites.isEmpty == false {
            for (index, site) in sites.enumerated() {
                refreshDataFor(site, index: index)
            }
        }
    }
    
    func refreshDataFor(_ site: Site, index: Int, completionHandler: ((NCUpdateResult) -> Void)? = nil){
        // Start up the API
        FIXME()
        site.fetchDataFromNetwrok(userInitiated: true) { (updatedSite, err) in
            if let _ = err {
              
                return
            }
            
            SitesDataSource.sharedInstance.updateSite(updatedSite)
            
            OperationQueue.main.addOperation {
                self.tableView.reloadData()
                
                if (self.refreshControl?.isRefreshing != nil) {
                    self.refreshControl?.endRefreshing()
                }
            }
        }
    }
    
    func openApp(with indexPath: IndexPath) {
        if let context = extensionContext {
            let site = sites[indexPath.row], _ = site.uuid.uuidString
            SitesDataSource.sharedInstance.lastViewedSiteIndex = indexPath.row
            
            let url = LinkBuilder.buildLink(forType: .link, withViewController: .siteListPageViewController)
            context.open(url, completionHandler: nil)
        }
    }
}
