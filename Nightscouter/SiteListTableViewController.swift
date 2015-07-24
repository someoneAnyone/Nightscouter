//
//  SiteTableViewController.swift
//  Nightscouter
//
//  Created by Peter Ina on 6/16/15.
//  Copyright © 2015 Peter Ina. All rights reserved.
//

import UIKit

//TODO:// Add an updating mechanism, like pull to refresh, button and or timer. Maybe consider moving a timer to the API that observers can subscribe to.

class SiteListTableViewController: UITableViewController {
    
    // MARK: Properties
    
    // Computed Property: Grabs the common set of sites from the data manager.
    var sites: [Site] {
        return AppDataManager.sharedInstance.sites
    }
    
    // Whenever this changes, it updates the attributed title of the refresh control.
    var lastUpdatedTime: NSDate? {
        didSet{
            
            // Create and use a formatter.
            let dateFormatter = NSDateFormatter()
            dateFormatter.timeStyle = NSDateFormatterStyle.MediumStyle
            dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
            dateFormatter.timeZone = NSTimeZone.localTimeZone()
            
            if let date = lastUpdatedTime {
                let str = String(stringInterpolation:Constants.LocalizedString.lastUpdatedDateLabel.localized, dateFormatter.stringFromDate(date))
                self.refreshControl!.attributedTitle = NSAttributedString(string:str, attributes: [NSForegroundColorAttributeName:UIColor.whiteColor()])
            }
        }
    }
    
    // Holds the indexPath of an accessory that was tapped. Used for getting the right Site from the sites array before passing over to the next view.
    var accessoryIndexPath: NSIndexPath?
    
    // MARK: View controller lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Common setup.
        configureView()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Check if we should display a form.
        shouldIShowNewSiteForm()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        // Remove this class from the observer list. Was listening for a global update timer.
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return sites.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellIdentifier = Constants.CellIdentifiers.SiteTableViewStyle
        
        // Configure the cell...
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! SiteTableViewCell
        configureCell(cell, indexPath: indexPath)
        
        return cell
    }
    
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            AppDataManager.sharedInstance.deleteSiteAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            self.editing = false
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
        // update the item in my data source by first removing at the from index, then inserting at the to index.
        let site = sites[fromIndexPath.row]
        AppDataManager.sharedInstance.deleteSiteAtIndex(fromIndexPath.row)
        AppDataManager.sharedInstance.addSite(site, index: toIndexPath.row)
    }
    
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        if sites.count == 1 {
            return false
        }
        return true
    }
    
    override func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        accessoryIndexPath = indexPath
    }
    
    override func tableView(tableView: UITableView, titleForDeleteConfirmationButtonForRowAtIndexPath indexPath: NSIndexPath) -> String! {
        return Constants.LocalizedString.tableViewCellRemove.localized
    }
    
    override func tableView(tableView: UITableView, didHighlightRowAtIndexPath indexPath: NSIndexPath) {
        var cell = tableView.cellForRowAtIndexPath(indexPath)
        cell?.contentView.backgroundColor = NSAssetKit.darkNavColor
        let highlightView = UIView()
        highlightView.backgroundColor = NSAssetKit.darkNavColor
        cell?.selectedBackgroundView = highlightView
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if let identifier = UIStoryboardSegue.SegueIdentifier(rawValue: segue.identifier!) {
            switch identifier {
                
            case .EditSite:
                #if DEBUG
                    print("Editing existing site")
                #endif
                self.setEditing(false, animated: true)
                
                let siteDetailViewController = segue.destinationViewController as! SiteFormViewController
                // Get the cell that generated this segue.
                if let selectedSiteCell = sender as? UITableViewCell {
                    let indexPath = tableView.indexPathForCell(selectedSiteCell)!
                    let selectedSite = sites[indexPath.row]
                    siteDetailViewController.site = selectedSite
                }
                
            case .AddNew:
                #if DEBUG
                    print("Adding new site")
                #endif
                self.setEditing(false, animated: true)
                
            case .AddNewWhenEmpty:
                #if DEBUG
                    print("Adding new site when empty")
                #endif
                self.setEditing(false, animated: true)
                return
                
            case .ShowDetail:
                let siteDetailViewController = segue.destinationViewController as! SiteDetailViewController
                // Get the cell that generated this segue.
                if let selectedSiteCell = sender as? UITableViewCell {
                    let indexPath = tableView.indexPathForCell(selectedSiteCell)!
                    let selectedSite = sites[indexPath.row]
                    siteDetailViewController.site = selectedSite
                }
                
            case .ShowPageView:
                let siteListPageViewController = segue.destinationViewController as! SiteListPageViewController
                // Get the cell that generated this segue.
                if let selectedSiteCell = sender as? UITableViewCell {
                    let indexPath = tableView.indexPathForCell(selectedSiteCell)!
                    AppDataManager.sharedInstance.currentSiteIndex = indexPath.row
                }
                
            default:
                #if DEBUG
                    print("Unhandled segue idendifier: \(segue.identifier)")
                #endif
            }
        }
        
    }
    
    // MARK: Actions
    @IBAction func refreshTable() {
        updateData()
    }
    
    @IBAction func unwindToSiteList(sender: UIStoryboardSegue) {
        
        if let sourceViewController = sender.sourceViewController as? SiteFormViewController, site = sourceViewController.site {
            // This segue is triggered when we "save" or "next" out of the url form.
            if let selectedIndexPath = accessoryIndexPath {
                // Update an existing site.
                AppDataManager.sharedInstance.sites[selectedIndexPath.row] = site
                tableView.reloadRowsAtIndexPaths([selectedIndexPath], withRowAnimation: .None)
                accessoryIndexPath = nil
            } else {
                // Add a new site.
                let newIndexPath = NSIndexPath(forRow: sites.count, inSection: 0)
                AppDataManager.sharedInstance.addSite(site, index: newIndexPath.row)
                tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: .Bottom)
            }
        }
        
        if let pageViewController = sender.sourceViewController as? SiteListPageViewController {
            
            let modelController = pageViewController.modelController
            let site = modelController.sites[pageViewController.currentIndex]
            
            AppDataManager.sharedInstance.sites[pageViewController.currentIndex] = site
            tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: pageViewController.currentIndex, inSection: 0)], withRowAnimation: .None)
        }
        shouldIShowNewSiteForm()
    }
    
    // MARK: Private Methods
    func configureView() -> Void {
        
        // The following line displys an Edit button in the navigation bar for this view controller.
        navigationItem.leftBarButtonItem = self.editButtonItem()
        // Only allow the edit button to be enabled if there are items in the sites array.
        self.editButtonItem().enabled = !sites.isEmpty
        
        // Configure table view properties.
        tableView.rowHeight = 240
        // Position refresh control above background view
        
        // Set table view's background view property
        // TODO: Move this out to a theme manager.
        tableView.backgroundView = TableViewBackgroundView()
        tableView.separatorColor = NSAssetKit.darkNavColor
        refreshControl?.tintColor = UIColor.whiteColor()
        refreshControl?.layer.zPosition = tableView.backgroundView!.layer.zPosition + 1
        
        // Listen for global update timer.
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateData", name: Constants.Notification.DataIsStaleUpdateNow, object: nil)
    }
    
    // For a given cell and index path get the appropriate site object and assign various properties.
    func configureCell(cell: SiteTableViewCell, indexPath: NSIndexPath) -> Void {
        
        let site = sites[indexPath.row]
        
        cell.siteURL.text = site.url.host
        
        if let configuration = site.configuration {
            
            if let defaults = configuration.defaults {
                cell.siteName.text = defaults.customTitle
            } else {
                cell.siteName.text = configuration.name
            }
            
            if let watch = site.watchEntry {
                
                cell.siteBatteryLevel.text = watch.batteryString
                cell.siteTimeAgo.text = watch.dateTimeAgoString
                cell.compassControl.configureWith(site)
                
                if let sgvValue = watch.sgv {
                    
                    let color = colorForDesiredColorState(site.configuration!.boundedColorForGlucoseValue(sgvValue.sgv))
                    cell.siteColorBlock.backgroundColor = color
                    
                    
                    if let enabledOptions = configuration.enabledOptions {
                        
                        let rawEnabled =  contains(enabledOptions, EnabledOptions.rawbg)
                        if rawEnabled {
                            if let rawValue = watch.raw {
                                cell.siteRaw.text = "\(NSNumberFormatter.localizedStringFromNumber(rawValue, numberStyle: .DecimalStyle)) : \(sgvValue.noise)"
                            }
                        } else {
                            cell.rawHeader.removeFromSuperview()
                            cell.siteRaw.removeFromSuperview()
                        }
                    }
                    
                    let timeAgo = watch.date.timeIntervalSinceNow
                    if timeAgo < -Constants.NotableTime.StaleDataTimeFrame {
                        cell.compassControl.alpha = 0.5
                        cell.compassControl.color = NSAssetKit.predefinedNeutralColor
                        cell.compassControl.sgvText = "---"
                        cell.compassControl.delta = "--"
                        cell.siteBatteryLevel.text = "---"
                        cell.siteRaw.text = "--- : ---"
                        cell.siteColorBlock.backgroundColor = colorForDesiredColorState(DesiredColorState.Neutral)
                        cell.compassControl.direction = .None
                    } else {
                        cell.compassControl.alpha = 1.0
                    }
                }
                
            } else {
                // No watch was there...
                #if DEBUG
                    println("No watch data was found...")
                #endif
                return
            }
        } else {
            #if DEBUG
                println("No site current configuration was found for \(site.url)")
            #endif
            
            // FIXME:// this prevents a loop, but needs to be fixed and errors need to be reported.
            if (lastUpdatedTime?.timeIntervalSinceNow > 60 || lastUpdatedTime == nil || site.configuration == nil) {
                // No configuration was there... go get some.
                // println("Attempting to get configuration data from site...")
                loadUpData(site, index: indexPath.row)
            }
            return
        }
    }
    
    func shouldIShowNewSiteForm() {
        // If the sites array is empty show a vesion of the form that does not allow escape.
        if sites.isEmpty{
            let vc = storyboard?.instantiateViewControllerWithIdentifier(UIStoryboard.StoryboardViewControllerIdentifier.SiteFormViewController.rawValue) as! SiteFormViewController
            self.parentViewController!.presentViewController(vc, animated: true, completion: { () -> Void in
                // println("Finished presenting SiteFormViewController.")
            })
        }
    }
    
    // MARK: Fetch data via REST API
    
    func updateData(){
        // Do not allow refreshing to happen if there is no data in the sites array.
        if sites.isEmpty == false {
            if refreshControl?.refreshing == false {
                refreshControl?.beginRefreshing()
                tableView.setContentOffset(CGPointMake(0, tableView.contentOffset.y-refreshControl!.frame.size.height), animated: true)
            }
            for site in sites {
                loadUpData(site, index: find(sites, site)!)
            }
        } else {
            // No data in the sites array. Cancel the refreshing!
            refreshControl?.endRefreshing()
        }
    }
    
    func loadUpData(site: Site, index: Int){
        // Start up the API
        let nsApi = NightscoutAPIClient(url: site.url)
        
        //TODO:// 1. There should be reachabiltiy checks before doing anything.
        //TODO:// 2. We should fail gracefully if things go wrong. Need to present a UI for reporting errors.
        //TODO:// 3. Probably need to move this code to the application delegate?
        
        // Get settings for a given site.
        println("Loading data for \(site.url!)")
        nsApi.fetchServerConfiguration { (result) -> Void in
            switch (result) {
            case let .Error(error):
                // display error message
                
                println("loadUpData ERROR recieved: \(error)")
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.presentAlertDialog(site.url, index: index, error: error)
                })
                
            case let .Value(boxedConfiguration):
                let configuration:ServerConfiguration = boxedConfiguration.value
                // do something with user
                nsApi.fetchDataForWatchEntry({ (watchEntry, watchEntryErrorCode) -> Void in
                    // Get back on the main queue to update the user interface
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        site.configuration = configuration
                        site.watchEntry = watchEntry
                        self.lastUpdatedTime = NSDate()
                        self.tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: .Automatic)
                        
                        if (self.refreshControl?.refreshing != nil) {
                            self.refreshControl?.endRefreshing()
                        }
                    })
                })
                
            }
        }
    }
    
    
    // Attempt to handle an error.
    func presentAlertDialog(siteURL:NSURL, index: Int, error: NSError) {
        
        let alertController = UIAlertController(title: Constants.LocalizedString.uiAlertBadSiteTitle.localized, message: String(format: Constants.LocalizedString.uiAlertBadSiteMessage.localized, siteURL, error.localizedDescription), preferredStyle: .Alert)
        alertController.view.tintColor = NSAssetKit.darkNavColor
        
        let cancelAction = UIAlertAction(title: Constants.LocalizedString.generalCancelLabel.localized, style: .Cancel) { (action) in
            // ...
        }
        alertController.addAction(cancelAction)
        
        let editAction = UIAlertAction(title: Constants.LocalizedString.generalEditLabel.localized, style: .Default) { (action) in
            let tableViewCell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: index, inSection: 0))
            self.performSegueWithIdentifier(UIStoryboardSegue.SegueIdentifier.EditSite.rawValue, sender:tableViewCell)
        }
        alertController.addAction(editAction)
        
        let removeAction = UIAlertAction(title: Constants.LocalizedString.tableViewCellRemove.localized, style: .Destructive) { (action) in
            self.tableView.beginUpdates()
            AppDataManager.sharedInstance.deleteSiteAtIndex(index)
            self.tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: .Automatic)
            self.tableView.endUpdates()
        }
        alertController.addAction(removeAction)
        
        self.presentViewController(alertController, animated: true) {
            // ...
        }
    }
}