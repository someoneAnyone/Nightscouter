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

class TodayViewController: UITableViewController, NCWidgetProviding {
    
    struct TableViewConstants {
        static let baseRowCount = 2
        static let todayRowHeight: CGFloat = 70
        
        struct CellIdentifiers {
            static let content = "nsSiteNow"
            static let message = "messageCell"
        }
    }
    
    var sites:[Site] = []
    
    var lastUpdatedTime: Date?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        sites = AppDataManageriOS.sharedInstance.sites
        
        tableView.backgroundColor = UIColor.clear
        tableView.estimatedRowHeight = TableViewConstants.todayRowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        preferredContentSize = tableView.contentSize
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
            
            cell.textLabel!.text = NSLocalizedString("No Nightscout sites were found.", comment: "")
            
            return cell
        } else {
            let contentCell = tableView.dequeueReusableCell(withIdentifier: TableViewConstants.CellIdentifiers.content, for: indexPath) as! SiteNSNowTableViewCell
            let site = sites[(indexPath as NSIndexPath).row]
            
            contentCell.configureCell(site)
            
            if site.updateNow {
                refreshDataFor(site, index: (indexPath as NSIndexPath).row)
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
        
        fetchSiteData(site) { (returnedSite, error: NightscoutAPIError) -> Void in
            
            switch error {
                
            case .noError :
                DispatchQueue.main.async(execute: { () -> Void in
                    AppDataManageriOS.sharedInstance.updateSite(returnedSite)
                    self.lastUpdatedTime = returnedSite.lastConnectedDate
                    self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                    self.preferredContentSize = self.tableView.contentSize
                })
            default:
                print("\(#function) ERROR recieved: \(error.description)")
            }
        }
    }
    
    func openApp(with indexPath: IndexPath) {
        if let context = extensionContext {
    
            let site = sites[(indexPath as NSIndexPath).row], _ = site.uuid.uuidString
            AppDataManageriOS.sharedInstance.currentSiteIndex = (indexPath as NSIndexPath).row
            AppDataManageriOS.sharedInstance.saveData()
            
            let url = URL(string: "nightscouter://link/\(Constants.StoryboardViewControllerIdentifier.SiteListPageViewController.rawValue)")
            
            context.open(url!, completionHandler: nil)
        }
    }
}
