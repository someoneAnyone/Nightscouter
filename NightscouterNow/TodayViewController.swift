//
//  TodayViewController.swift
//  NightscouterNow
//
//  Created by Peter Ina on 8/8/15.
//  Copyright (c) 2015 Peter Ina. All rights reserved.
//

import UIKit
import NotificationCenter
import NightscouterKit

class TodayViewController: UITableViewController, NCWidgetProviding {
    
    var sites:[Site] {
        return AppDataManager.sharedInstance.sites
    }
    
    // Whenever this changes, it updates the attributed title of the refresh control.
    var lastUpdatedTime: NSDate?

    //let expandButton = UIButton()
    
    let userDefaults = AppDataManager.sharedInstance.defaults
    
    /*
    var expanded : Bool {
        get {
            return userDefaults.boolForKey("expanded")
        }
        set (newExpanded) {
            userDefaults.setBool(newExpanded, forKey: "expanded")
            userDefaults.synchronize()
        }
    }
    */
    
//    let defaultNumRows = 3
//    let maxNumberOfRows = 6
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view from its nib.
        
//        updateExpandButtonTitle()
        //expandButton.addTarget(self, action: "toggleExpand", forControlEvents: .TouchUpInside)

        tableView.estimatedRowHeight = 80
//        tableView.sectionFooterHeight = 44
        
        updatePreferredContentSize()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)!) {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        // tableView.reloadData()
        completionHandler(NCUpdateResult.NewData)
    }
    
    func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        return UIEdgeInsetsZero
    }
    
    func updatePreferredContentSize() {
        preferredContentSize = tableView.contentSize
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animateAlongsideTransition({ context in
            self.tableView.frame = CGRectMake(0, 0, size.width, size.height)
            }, completion: nil)
    }
    
    // MARK: Table View Data Source
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !sites.isEmpty {
//            return min(sites.count, expanded ? maxNumberOfRows : defaultNumRows)
            return sites.count
        }
        return 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("nsSiteNow", forIndexPath: indexPath) as! SiteNSNowTableViewCell
        
        let site = sites[indexPath.row]
        cell.configureCell(site)
        
        if (lastUpdatedTime?.timeIntervalSinceNow > 60 || lastUpdatedTime == nil || site.configuration == nil) {
            // No configuration was there... go get some.
            // println("Attempting to get configuration data from site...")
            loadDataFor(site, index: indexPath.row)
        }

        return cell
    }
    
    /*
    override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return expandButton
    }
    */
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let item = sites[indexPath.row]
        
        if let context = extensionContext {

            AppDataManager.sharedInstance.currentSiteIndex = indexPath.row
            let url = NSURL(string: "nightscouter://link/\(Constants.StoryboardViewControllerIdentifier.SiteListPageViewController.rawValue)")
            context.openURL(url!, completionHandler: nil)
        }

    }

    
    // MARK: expand
    /*
    func updateExpandButtonTitle() {
        expandButton.setTitle(expanded ? "Show less" : "Show more", forState: .Normal)
    }
    
    func toggleExpand() {
        expanded = !expanded
        updateExpandButtonTitle()
        updatePreferredContentSize()
        tableView.reloadData()
    }
    */
    
    func updateData(){
        // Do not allow refreshing to happen if there is no data in the sites array.
        if sites.isEmpty == false {
            for site in sites {
                loadDataFor(site, index: find(sites, site)!)
            }
        } else {
            // No data in the sites array. Cancel the refreshing!
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
                        site.configuration = configuration
                        site.watchEntry = watchEntry
                        AppDataManager.sharedInstance.updateSite(site)
                        self.lastUpdatedTime = NSDate()
                        self.tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: .Automatic)
                    })
                })
            }
        }
    }
}
