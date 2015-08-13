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
        static let todayRowHeight = 80
        
        struct CellIdentifiers {
            static let content = "nsSiteNow"
            static let message = "messageCell"
        }
    }
    
    var sites:[Site] {
        return AppDataManager.sharedInstance.sites
    }
    
    // Whenever this changes, it updates the attributed title of the refresh control.
    var lastUpdatedTime: NSDate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view from its nib.
        // tableView.rowHeight = UITableViewAutomaticDimension
        tableView.backgroundColor = UIColor.clearColor()
                updatePreferredContentSize()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: NCWidgetProviding
    
    func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        return UIEdgeInsets(top: defaultMarginInsets.top, left: 27.0, bottom: defaultMarginInsets.bottom, right: defaultMarginInsets.right)
    }
    
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)!) {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        completionHandler(NCUpdateResult.NewData)
    }
    
    var preferredViewHeight: CGFloat {
        // Determine the total number of items available for presentation.
        let itemCount = sites.isEmpty ? sites.count : 1
        
        /*
        On first launch only display up to `TableViewConstants.baseRowCount + 1` rows. An additional row
        is used to display the "Show All" row.
        */
//        let rowCount = showingAll ? itemCount : min(itemCount, TableViewConstants.baseRowCount + 1)
        
        return CGFloat((itemCount) * TableViewConstants.todayRowHeight)
    }

    
    func updatePreferredContentSize() {
        preferredContentSize.width = tableView.frame.size.width
        preferredContentSize.height = preferredViewHeight //min(tableView.frame.size.height, tableView.contentSize.height)
    }
    
        override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
            coordinator.animateAlongsideTransition({ context in
                self.tableView.frame = CGRectMake(0, 0, size.width, size.height)
                }, completion: nil)
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
            let cell = tableView.dequeueReusableCellWithIdentifier(TableViewConstants.CellIdentifiers.message, forIndexPath: indexPath) as! UITableViewCell
            
            cell.textLabel!.text = NSLocalizedString("No Nighscout sites were found.", comment: "")
            
            return cell
        } else {
            let contentCell = tableView.dequeueReusableCellWithIdentifier(TableViewConstants.CellIdentifiers.content, forIndexPath: indexPath) as! SiteNSNowTableViewCell
            let site = sites[indexPath.row]
            contentCell.configureCell(site)
            
            if (lastUpdatedTime?.timeIntervalSinceNow > 60 || lastUpdatedTime == nil || site.configuration == nil) {
                // No configuration was there... go get some.
                // println("Attempting to get configuration data from site...")
                loadDataFor(site, index: indexPath.row)
            }
            
            
            return contentCell
        }
        
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.layer.backgroundColor = UIColor.clearColor().CGColor
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        // let site = sites[indexPath.row]
        if let context = extensionContext {
            AppDataManager.sharedInstance.currentSiteIndex = indexPath.row
            let url = NSURL(string: "nightscouter://link/\(Constants.StoryboardViewControllerIdentifier.SiteListPageViewController.rawValue)")
            context.openURL(url!, completionHandler: nil)
        }
        
    }
    
    func updateData(){
        // Do not allow refreshing to happen if there is no data in the sites array.
        if sites.isEmpty == false {
            for site in sites {
                loadDataFor(site, index: find(sites, site)!)
            }
        }
    }
    
    func loadDataFor(site: Site, index: Int){
        // Start up the API
        let nsApi = NightscoutAPIClient(url: site.url)
        
        //TODO: 1. There should be reachabiltiy checks before doing anything.
        //TODO: 2. We should fail gracefully if things go wrong. Need to present a UI for reporting errors.
        //TODO: 3. Probably need to move this code to the application delegate?
        
        // Get settings for a given site.
        
        println("Loading data for \(site.url!)")
        nsApi.fetchServerConfiguration { (result) -> Void in
            switch (result) {
            case let .Error(error):
                // display error message
                println("loadUpData ERROR recieved: \(error)")
            case let .Value(boxedConfiguration):
                let configuration:ServerConfiguration = boxedConfiguration.value
                // do something with user
                nsApi.fetchDataForWatchEntry({ (watchEntry, watchEntryErrorCode) -> Void in
                    // Get back on the main queue to update the user interface
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        println("back with data")
                        site.configuration = configuration
                        site.watchEntry = watchEntry
                        AppDataManager.sharedInstance.updateSite(site)
                        self.lastUpdatedTime = NSDate()
                        self.tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: .Automatic)
                        self.updatePreferredContentSize()
                    })
                })
            }
        }
    }
}
