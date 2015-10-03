//
//  SiteTableViewController.swift
//  Nightscouter
//
//  Created by Peter Ina on 6/16/15.
//  Copyright © 2015 Peter Ina. All rights reserved.
//

import UIKit
import NightscouterKit

//TODO:// Add an updating mechanism, like pull to refresh, button and or timer. Maybe consider moving a timer to the API that observers can subscribe to.

class SiteListTableViewController: UITableViewController, NightscoutAPIClientDelegate {
    
    // MARK: Properties
    
    // Computed Property: Grabs the common set of sites from the data manager.
    var sites: [Site] {
        editButtonItem().enabled = !AppDataManager.sharedInstance.sites.isEmpty
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
    
    var siteToDisplay: Site?
    
    // Holds the indexPath of an accessory that was tapped. Used for getting the right Site from the sites array before passing over to the next view.
    var accessoryIndexPath: NSIndexPath?
    
    // MARK: View controller lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let site = siteToDisplay {
            performSegueWithIdentifier(Constants.SegueIdentifier.ShowPageView.rawValue, sender: site)
        }
        
        // Common setup.
        configureView()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Check if we should display a form.
        shouldIShowNewSiteForm()
        
        // Make sure the idle screen timer is turned back to normal. Screen will time out.
        AppDataManager.sharedInstance.shouldDisableIdleTimer = false
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
            
            let site = sites[indexPath.row]
            
            for notification in site.notifications {
                UIApplication.sharedApplication().cancelLocalNotification(notification)
            }
            
            AppDataManager.sharedInstance.deleteSiteAtIndex(indexPath.row)
        
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            shouldIShowNewSiteForm()
        } else if editingStyle == .Insert {
            // self.editing = false
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
    
    override func tableView(tableView: UITableView, titleForDeleteConfirmationButtonForRowAtIndexPath indexPath: NSIndexPath) -> String? {
        return Constants.LocalizedString.tableViewCellRemove.localized
    }
    
    override func tableView(tableView: UITableView, didHighlightRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        //        cell?.contentView.backgroundColor = NSAssetKit.darkNavColor
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
        
        if let identifier = Constants.SegueIdentifier(rawValue: segue.identifier!) {
            switch identifier {
                
            case .EditSite:
                #if DEBUG
                    print("Editing existing site", terminator: "")
                #endif
                editing = false
                let siteDetailViewController = segue.destinationViewController as! SiteFormViewController
                // Get the cell that generated this segue.
                if let selectedSiteCell = sender as? UITableViewCell {
                    let indexPath = tableView.indexPathForCell(selectedSiteCell)!
                    let selectedSite = sites[indexPath.row]
                    siteDetailViewController.site = selectedSite
                }
                
            case .AddNew:
                #if DEBUG
                    print("Adding new site", terminator: "")
                #endif
                self.setEditing(false, animated: true)
                
            case .AddNewWhenEmpty:
                #if DEBUG
                    print("Adding new site when empty", terminator: "")
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
//                let siteListPageViewController = segue.destinationViewController as! SiteListPageViewController
                // Get the cell that generated this segue.
                if let selectedSiteCell = sender as? UITableViewCell {
                    let indexPath = tableView.indexPathForCell(selectedSiteCell)!
                    AppDataManager.sharedInstance.currentSiteIndex = indexPath.row
                }
                
                if let incomingSite = sender as? Site{
                    if let indexOfSite = sites.indexOf(incomingSite) {
                        AppDataManager.sharedInstance.currentSiteIndex = indexOfSite
                    }
                }
                
            default:
                #if DEBUG
                    print("Unhandled segue idendifier: \(segue.identifier)", terminator: "")
                #endif
            }
        }
        
    }
    
    // MARK: Actions
    @IBAction func refreshTable() {
        updateData()
    }
    
    @IBAction func goToSettings(sender: AnyObject?) {
        let settingsUrl = NSURL(string: UIApplicationOpenSettingsURLString)
        UIApplication.sharedApplication().openURL(settingsUrl!)
    }
    
    @IBAction func unwindToSiteList(sender: UIStoryboardSegue) {
        
        if let sourceViewController = sender.sourceViewController as? SiteFormViewController, site = sourceViewController.site {
            site.disabled = false
            // This segue is triggered when we "save" or "next" out of the url form.
            if let selectedIndexPath = accessoryIndexPath {
                // Update an existing site.
                AppDataManager.sharedInstance.updateSite(site)
                tableView.reloadRowsAtIndexPaths([selectedIndexPath], withRowAnimation: .None)
                accessoryIndexPath = nil
            } else {
                // Add a new site.
                editing = false
                let newIndexPath = NSIndexPath(forRow: 0, inSection: 0)
                AppDataManager.sharedInstance.addSite(site, index: newIndexPath.row)
                tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: .Automatic)
                accessoryIndexPath = nil
            }
        }
        
        if let pageViewController = sender.sourceViewController as? SiteListPageViewController {
            // let modelController = pageViewController.modelController
            // let site = modelController.sites[pageViewController.currentIndex]
            tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: pageViewController.currentIndex, inSection: 0)], withRowAnimation: .None)
        }
        shouldIShowNewSiteForm()
    }
    
    // MARK: Private Methods
    func configureView() -> Void {
        // The following line displys an Edit button in the navigation bar for this view controller.
        navigationItem.leftBarButtonItem = self.editButtonItem()
        
        // Only allow the edit button to be enabled if there are items in the sites array.
        clearsSelectionOnViewWillAppear = true
        
        // Configure table view properties.
        tableView.rowHeight = 240
        tableView.backgroundView = BackgroundView() // TODO: Move this out to a theme manager.
        tableView.separatorColor = NSAssetKit.darkNavColor
        
        // Position refresh control above background view
        refreshControl?.tintColor = UIColor.whiteColor()
        refreshControl?.layer.zPosition = tableView.backgroundView!.layer.zPosition + 1
        
        setupNotifications()
        
        // Make sure the idle screen timer is turned back to normal. Screen will time out.
        AppDataManager.sharedInstance.shouldDisableIdleTimer = false
        
        startUserActivity()
    }
    
    func setupNotifications() {
        // Listen for global update timer.
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateData", name: Constants.Notification.DataIsStaleUpdateNow, object: nil)
    }
    
    // For a given cell and index path get the appropriate site object and assign various properties.
    func configureCell(cell: SiteTableViewCell, indexPath: NSIndexPath) -> Void {
        let site = sites[indexPath.row]
        cell.configureCell(site)
        // FIXME:// this prevents a loop, but needs to be fixed and errors need to be reported.
        if (lastUpdatedTime?.timeIntervalSinceNow > Constants.StandardTimeFrame.TwoAndHalfMinutesInSeconds || lastUpdatedTime == nil || site.configuration == nil) {
            // No configuration was there... go get some.
            // println("Attempting to get configuration data from site...")
            loadDataFor(site, index: indexPath.row)
        }
    }
    
    func shouldIShowNewSiteForm() {
        // If the sites array is empty show a vesion of the form that does not allow escape.
        if sites.isEmpty{
            let vc = storyboard?.instantiateViewControllerWithIdentifier(Constants.StoryboardViewControllerIdentifier.SiteFormViewController.rawValue) as! SiteFormViewController
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
                loadDataFor(site, index: sites.indexOf(site)!)
            }
        } else {
            // No data in the sites array. Cancel the refreshing!
            refreshControl?.endRefreshing()
        }
    }
    
    func loadDataFor(site: Site, index: Int){
        // Start up the API
        let nsApi = NightscoutAPIClient(url: site.url)
        nsApi.delegate = self
        //TODO: 1. There should be reachabiltiy checks before doing anything.
        //TODO: 2. We should fail gracefully if things go wrong. Need to present a UI for reporting errors.
        //TODO: 3. Probably need to move this code to the application delegate?
        
        // Get settings for a given site.
        print("Loading data for \(site.url!)")
        nsApi.fetchServerConfiguration { (result) -> Void in
            switch (result) {
            case let .Error(error):
                // display error message
                
                // println("loadUpData ERROR recieved: \(error)")
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    site.disabled = true
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
                        AppDataManager.sharedInstance.updateSite(site)
                        
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
        
        let retryAction = UIAlertAction(title: Constants.LocalizedString.generalRetryLabel.localized, style: .Default) { (action) in
            let indexPath = NSIndexPath(forRow: index, inSection: 0)
            let site = AppDataManager.sharedInstance.sites[indexPath.row]
            site.disabled = false
            AppDataManager.sharedInstance.updateSite(site)
            
            self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
        }
        alertController.addAction(retryAction)
        
        let editAction = UIAlertAction(title: Constants.LocalizedString.generalEditLabel.localized, style: .Default) { (action) in
            let indexPath = NSIndexPath(forRow: index, inSection: 0)
            let tableViewCell = self.tableView.cellForRowAtIndexPath(indexPath)
            self.accessoryIndexPath = indexPath
            self.performSegueWithIdentifier(Constants.SegueIdentifier.EditSite.rawValue, sender:tableViewCell)
        }
        alertController.addAction(editAction)
        
        let removeAction = UIAlertAction(title: Constants.LocalizedString.tableViewCellRemove.localized, style: .Destructive) { (action) in
            self.tableView.beginUpdates()
            AppDataManager.sharedInstance.deleteSiteAtIndex(index)
            self.tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: .Automatic)
            self.tableView.endUpdates()
        }
        alertController.addAction(removeAction)
        
        self.navigationController?.popToRootViewControllerAnimated(true)
        
        self.presentViewController(alertController, animated: true) {
            // remove nsnotification observer?
            // ...
        }
    }
    
    // MARK: Handoff
    
    func startUserActivity() {
        let activity = NSUserActivity(activityType: Constants.ActivityType.sites.absoluteString)
        activity.title = "Viewing Nightscout List of Sites"
        activity.userInfo = [Constants.ActivityKey.SitesKey: sites]
        userActivity = activity
        userActivity?.becomeCurrent()
    }
    
    override func updateUserActivityState(activity: NSUserActivity) {
        activity.addUserInfoEntriesFromDictionary([Constants.ActivityKey.SitesKey: sites])
        super.updateUserActivityState(activity)
    }
    
    func stopUserActivity() {
        userActivity?.invalidate()
    }
    
    func nightscoutAPIClient(nightscoutAPIClient: NightscoutAPIClient, usingNetwork: Bool) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = usingNetwork
    }
}