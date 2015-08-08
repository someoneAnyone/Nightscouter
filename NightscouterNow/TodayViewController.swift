//
//  TodayViewController.swift
//  NightscouterNow
//
//  Created by Peter Ina on 8/7/15.
//  Copyright (c) 2015 Peter Ina. All rights reserved.
//

import UIKit
import NotificationCenter
import NightscouterKit

class TodayViewController: UITableViewController, NCWidgetProviding {
    
    var sites: [Site] {
        return AppDataManager.sharedInstance.sites
    }

    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)!) {
        // Perform any setup necessary in order to update the view.

        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData

        completionHandler(NCUpdateResult.NewData)
    }
    
    let expandButton = UIButton()
    
    let userDefaults = AppDataManager.sharedInstance.defaults
    
    var expanded : Bool {
        get {
            return userDefaults.boolForKey("expanded")
        }
        set (newExpanded) {
            userDefaults.setBool(newExpanded, forKey: "expanded")
            userDefaults.synchronize()
        }
    }
    
    let defaultNumRows = 3
    let maxNumberOfRows = 6
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateExpandButtonTitle()
        expandButton.addTarget(self, action: "toggleExpand", forControlEvents: .TouchUpInside)
        tableView.sectionFooterHeight = 44
        
//        updatePreferredContentSize()
    }
    
//    func updatePreferredContentSize() {
//        preferredContentSize = CGSizeMake(CGFloat(0), CGFloat(tableView(tableView, numberOfRowsInSection: 0)) * CGFloat(tableView.rowHeight) + tableView.sectionFooterHeight)
//    }
//    
//    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
//        coordinator.animateAlongsideTransition({ context in
//            self.tableView.frame = CGRectMake(0, 0, size.width, size.height)
//            }, completion: nil)
//    }
    
//    func loadFeed(completionHandler: ((NCUpdateResult) -> Void)!) {
//        
//        let url = NSURL(string: "http://blog.xebia.com/feed/")
//        let req = NSURLRequest(URL: url)
//        
//        RSSParser.parseRSSFeedForRequest(req,
//            success: { feedItems in
//                if self.hasNewData(feedItems as [RSSItem]) {
//                    self.items = feedItems as? [RSSItem]
//                    self.tableView .reloadData()
//                    self.updatePreferredContentSize()
//                    self.cachedItems = self.items
//                    completionHandler(.NewData)
//                } else {
//                    completionHandler(.NoData)
//                }
//            },
//            failure: { error in
//                println(error)
//                completionHandler(.Failed)
//                
//        })
//    }
    
    
    // MARK: Table view data source
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if sites.isEmpty { return 0 }
        return min(sites.count, expanded ? maxNumberOfRows : defaultNumRows)
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("nsNowCell", forIndexPath: indexPath) as! UITableViewCell
        
        cell.textLabel?.text = "\(indexPath.row)"
        return cell
    }
    
    override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return expandButton
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
         let site = sites[indexPath.row]
            if let context = extensionContext {
//                context.openURL(site.uuid, completionHandler: nil)
        }
    }
    
    // MARK: expand
    
    func updateExpandButtonTitle() {
        expandButton.setTitle(expanded ? "Show less" : "Show more", forState: .Normal)
    }
    
    func toggleExpand() {
        expanded = !expanded
        updateExpandButtonTitle()
//        updatePreferredContentSize()
        tableView.reloadData()
    }

}
