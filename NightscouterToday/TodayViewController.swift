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
        static let todayRowHeight = 70
        
        struct CellIdentifiers {
            static let content = "nsSiteNow"
            static let message = "messageCell"
        }
    }
    
    var sites:[Site] = [Site]()
    
    // Whenever this changes, it updates the attributed title of the refresh control.
    var lastUpdatedTime: NSDate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view from its nib.
        // tableView.rowHeight = UITableViewAutomaticDimension
        tableView.backgroundColor = UIColor.clearColor()
        
        if let  sitesData = AppDataManageriOS.sharedInstance.defaults.dataForKey(DefaultKey.sitesArrayObjectsKey) {
            if let sitesArray = NSKeyedUnarchiver.unarchiveObjectWithData(sitesData) as? [Site] {
                sites = sitesArray
            }
        }
        
        // sites = AppDataManager.sharedInstance.sites
        
        let itemCount = sites.isEmpty ? 1 : sites.count
        
        preferredContentSize = CGSize(width: preferredContentSize.width, height: CGFloat(itemCount * TableViewConstants.todayRowHeight))
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: NCWidgetProviding
    
    func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        return UIEdgeInsets(top: defaultMarginInsets.top, left: 0, bottom: defaultMarginInsets.bottom, right: defaultMarginInsets.right)
    }
    
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        completionHandler(NCUpdateResult.NewData)
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if (sites.isEmpty) {
            // Make sure to allow for a row to note that no incomplete items remain.
            return 1
        }
        
        return  sites.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if sites.isEmpty {
            let cell = tableView.dequeueReusableCellWithIdentifier(TableViewConstants.CellIdentifiers.message, forIndexPath: indexPath)
            
            cell.textLabel!.text = NSLocalizedString("No Nightscout sites were found.", comment: "")
            
            return cell
        } else {
            let contentCell = tableView.dequeueReusableCellWithIdentifier(TableViewConstants.CellIdentifiers.content, forIndexPath: indexPath) as! SiteNSNowTableViewCell
            let site = sites[indexPath.row]
            
            contentCell.configureCell(site)
            if (lastUpdatedTime?.timeIntervalSinceNow > 60 || lastUpdatedTime == nil || site.configuration == nil) {
                // No configuration was there... go get some.
                // println("Attempting to get configuration data from site...")
                refreshDataFor(site, index: indexPath.row)
            }
            
            return contentCell
        }
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.layer.backgroundColor = UIColor.clearColor().CGColor
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        openApp(with: indexPath)
    }
    
    func updateData(){
        // Do not allow refreshing to happen if there is no data in the sites array.
        if sites.isEmpty == false {
            for (index, site) in sites.enumerate() {
                refreshDataFor(site, index: index)
            }
        } else {
            // No data in the sites array. Cancel the refreshing!
        }
    }
    
    func refreshDataFor(site: Site, index: Int){
        // Start up the API
        
        
        loadDataFor(site, index: index) { (returnedModel, returnedSite, returnedIndex, returnedError) -> Void in
            

            if let error = returnedError {
            print("\(__FUNCTION__) ERROR recieved: \(error)")
                
            } else {
                self.lastUpdatedTime = returnedSite!.lastConnectedDate
                self.tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: returnedIndex!, inSection: 0)], withRowAnimation: .Automatic)
                AppDataManageriOS.sharedInstance.updateSite(returnedSite!)
            }
        }
    }
    
    func openApp(with indexPath: NSIndexPath) {
        if let context = extensionContext {
            
            let site = sites[indexPath.row], uuidString = site.uuid.UUIDString
            AppDataManageriOS.sharedInstance.currentSiteIndex = indexPath.row
            
            let url = NSURL(string: "nightscouter://link/\(Constants.StoryboardViewControllerIdentifier.SiteListPageViewController.rawValue)/\(uuidString)")
            context.openURL(url!, completionHandler: nil)
        }
    }
}
