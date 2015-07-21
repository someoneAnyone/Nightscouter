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
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    var sites = [Site]()
    var accessoryIndexPath: NSIndexPath?
    
    var lastUpdatedTime: NSDate? {
        didSet{
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
    
    // MARK: View controller lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        shouldIShowNewSiteForm()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
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
            sites.removeAtIndex(indexPath.row)
            // Save the meals.
            saveSites()
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
        sites.removeAtIndex(fromIndexPath.row)
        sites.insert(site, atIndex: toIndexPath.row)
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
                print("Editing existing site")
                self.setEditing(false, animated: true)
                
                let siteDetailViewController = segue.destinationViewController as! SiteFormViewController
                // Get the cell that generated this segue.
                if let selectedSiteCell = sender as? UITableViewCell {
                    let indexPath = tableView.indexPathForCell(selectedSiteCell)!
                    let selectedSite = sites[indexPath.row]
                    siteDetailViewController.site = selectedSite
                }
                
            case .AddNew:
                print("Adding new site")
                self.setEditing(false, animated: true)
                
            case .AddNewWhenEmpty:
                print("Adding new site when empty")
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
                    siteListPageViewController.sites = sites
                    siteListPageViewController.currentIndex = indexPath.row
                }
                
            default:
                print("Unhandled segue idendifier: \(segue.identifier)")
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
            if let selectedIndexPath = accessoryIndexPath { //tableView.indexPathForSelectedRow {
                // Update an existing meal.
                sites[selectedIndexPath.row] = site
                tableView.reloadRowsAtIndexPaths([selectedIndexPath], withRowAnimation: .None)
                accessoryIndexPath = nil
            } else {
                // Add a new site.
                let newIndexPath = NSIndexPath(forRow: sites.count, inSection: 0)
                
                sites.append(site)
                tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: .Bottom)
            }
        }
        
        if let pageViewController = sender.sourceViewController as? SiteListPageViewController {
            
            let modelController = pageViewController.modelController
            let site = modelController.sites[pageViewController.currentIndex]
            
            sites[pageViewController.currentIndex] = site
            tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: pageViewController.currentIndex, inSection: 0)], withRowAnimation: .None)
        }
        
        // Save the sites.
        saveSites()
    }
    
    // MARK: Private Methods
    func configureView() -> Void {
        
        // The following line displys an Edit button in the navigation bar for this view controller.
        navigationItem.leftBarButtonItem = self.editButtonItem()
        
        // Set table view's background view property
        tableView.backgroundView = TableViewBackgroundView()
        tableView.separatorColor = NSAssetKit.darkNavColor
        tableView.rowHeight = 200
        
        // Position refresh control above background view
        refreshControl?.layer.zPosition = tableView.backgroundView!.layer.zPosition + 1
        refreshControl?.tintColor = UIColor.whiteColor()
        
        // Load any saved meals, otherwise load sample data.
        if let savedSites = loadSites() {
            sites += savedSites
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateData", name: Constants.Notification.DataIsStaleUpdateNow, object: nil)

    }
    
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
                println("No watch data was found...")
                return
            }
        } else {
            
            println("No site current configuration was found for \(site.url.absoluteString))")
            // FIXME:// this prevents a loop, but needs to be fixed and errors need to be reported.
            if (lastUpdatedTime?.timeIntervalSinceNow > 60 || lastUpdatedTime == nil) {
                // No configuration was there... go get some.
                println("Attempting to get configuration data from site...")
                
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
                println("Finished presenting SiteFormViewController.")
            })
            
        }
    }
    
    // MARK: Fetch data via REST API
    
    func updateData(){
        if refreshControl?.refreshing == false {
            refreshControl?.beginRefreshing()
            tableView.setContentOffset(CGPointMake(0, tableView.contentOffset.y-refreshControl!.frame.size.height), animated: true)
        }

        println("Refreshing all data in [Sites]")
        for site in sites {
            loadUpData(site, index: find(sites, site)!)
        }
    }
    
    func loadUpData(site: Site, index: Int){
        // Start up the API
        let nsApi = NightscoutAPIClient(url: site.url)
        
        //TODO:// 1. There should be reachabiltiy checks before doing anything.
        //TODO:// 2. We should fail gracefully if things go wrong. Need to present a UI for reporting errors.
        //TODO:// 3. Probably need to move this code to the application delegate?
        
        // Get settings for a given site.
        
        nsApi.fetchServerConfiguration { (result) -> Void in
            switch (result) {
            case let .Error(error):
                // display error message
                println("test")
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
    
    // MARK: NSCoding
    
    func saveSites() -> Void {
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(sites, toFile: Site.ArchiveURL.path!)
        if !isSuccessfulSave {
            println("Failed to save sites...")
        }
        shouldIShowNewSiteForm()
    }
    
    func loadSites() -> [Site]? {
        return appDelegate.sites
    }
}