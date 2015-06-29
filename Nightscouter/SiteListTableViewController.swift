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
    
    //    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate // Here just in case I start moving data access to the delegate.
    
    var sites = [Site]() {
        didSet{
            showEmptyForm()
        }
    }
    var accessoryIndexPath: NSIndexPath?
    
    var lastUpdatedTime: NSDate? {
        didSet{

            let dateFormatter = NSDateFormatter()
            dateFormatter.timeStyle = NSDateFormatterStyle.MediumStyle
            dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
            dateFormatter.timeZone = NSTimeZone.localTimeZone()
            
            if let date = lastUpdatedTime {
            
            self.refreshControl!.attributedTitle = NSAttributedString(string:"Updated on: \(dateFormatter.stringFromDate(date))")
            }
        }
    }
    var timer: NSTimer = NSTimer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // The following line displys an Edit button in the navigation bar for this view controller.
        navigationItem.leftBarButtonItem = self.editButtonItem()
        tableView.rowHeight = 100
        
        // Load any saved meals, otherwise load sample data.
        if let savedSites = loadSites() {
            sites += savedSites
        } else {
            // Load the sample data.
            loadSampleSites()
        }
        
        showEmptyForm()
        
        self.timer = NSTimer.scheduledTimerWithTimeInterval(240.0, target: self, selector: Selector("updateData"), userInfo: nil, repeats: true)
        
        // Initialize the refresh control.
        self.refreshControl = UIRefreshControl()
    
        var updated = "Last updated on: \(lastUpdatedTime)"
        self.refreshControl!.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.refreshControl!.addTarget(self, action: "updateData", forControlEvents: UIControlEvents.ValueChanged)
        self.tableView.addSubview(refreshControl!)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.hidesBarsOnTap = false
        
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
        let cellIdentifier = "siteCell"
        
        // Configure the cell...
        
        //TODO:// Clean this up.
        //TODO:// Get better assets for battery and directions.
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! SiteTableViewCell
        let site = sites[indexPath.row]
        
        cell.siteURL.text = site.url.host
        
        if !(site.configuration != nil) {
            loadUpData(site, index: indexPath.row)
        }
        
        if (site.configuration == nil) { return cell }
        
        cell.siteName.text = site.configuration?.customTitle
        
        if let batteryLevel = site.watchEntry?.battery {
            let percentage = Float(batteryLevel)/100
            cell.siteBatteryLevel.text = "\(NSNumberFormatter.localizedStringFromNumber(percentage, numberStyle: NSNumberFormatterStyle.PercentStyle))"
        }
        
        if (site.watchEntry == nil) { return cell }
        
        if let watchFace = site.watchEntry {
            let numberFormat = NSNumberFormatter.localizedStringFromNumber(watchFace.bgdelta, numberStyle: .NoStyle)
            // I hand rolled this... probably could find a better class to this.
            let timeAgo = NSCalendar.autoupdatingCurrentCalendar().stringRepresentationOfElapsedTimeSinceNow(watchFace.date)
            
            cell.siteLastDirection.text = watchFace.sgv?.direction.emojiForDirection()
            
            if let sgvalue = watchFace.sgv {
                if sgvalue.sgv > 30 {
                    
                    let color = colorForDesiredColorState(site.configuration!.boundedColorForGlucoseValue(sgvalue.sgv))
                    
                    cell.siteColorBlock.backgroundColor = color
                    cell.siteLastSGV.text = sgvalue.sgvText//String(stringInterpolationSegment: sgvalue.sgv)
                    cell.siteLastDelta.text = "\(numberFormat) \(site.configuration!.units.rawValue)"
                    if let rawValue = watchFace.raw {
                        cell.siteRaw.text = "\(NSNumberFormatter.localizedStringFromNumber(rawValue, numberStyle: .DecimalStyle)) :  \(sgvalue.noise)"
                    }
                }
                cell.siteLastSGV.text = sgvalue.sgvText//String(stringInterpolationSegment: sgvalue.sgv)

            } else {
                
                cell.siteLastSGV.text = watchFace.sgv?.direction.description
                cell.siteLastDelta.text = "\(site.configuration!.units.rawValue)"
            }
            
            
            cell.siteTimeAgo.text = timeAgo
        }
        
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
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if let identifier = UIStoryboardSegue.SegueIdentifier(rawValue: segue.identifier!) {
            switch identifier {
                
            case .EditSite:
                print("Editing existing site")
                
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
    
    @IBAction func unwindToSiteList(sender: UIStoryboardSegue) {
        
        if let sourceViewController = sender.sourceViewController as? SiteFormViewController, site = sourceViewController.site {
            // This segue is triggered when we "save" or "next" out of the url form.
            if let selectedIndexPath = accessoryIndexPath { //tableView.indexPathForSelectedRow {
                // Update an existing meal.
                sites[selectedIndexPath.row] = site
                tableView.reloadRowsAtIndexPaths([selectedIndexPath], withRowAnimation: .None)
                accessoryIndexPath = nil
            } else {
                // Add a new meal.
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
    
    func showEmptyForm() {
        // If the sites array is empty show a vesion of the form that does not allow escape.
        if sites.isEmpty{
            let identifier = UIStoryboardSegue.SegueIdentifier.AddNewWhenEmpty.rawValue
            performSegueWithIdentifier(identifier, sender: self)
        }
    }
    
    // MARK: Fetch data via REST API
    
    func updateData(){
        print("Refresing all data")
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
        nsApi.fetchServerConfigurationData({ (configuration) -> Void in
            nsApi.fetchDataForWatchEntry({ (watchEntry) -> Void in
                // Get back on the main queue to update the user interface
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    site.configuration = configuration
                    site.watchEntry = watchEntry
                    //                    self.sites[index] = site
                    self.lastUpdatedTime = NSDate()
                    self.tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: .Automatic)
                    
                    if (self.refreshControl?.refreshing != nil) {
                        self.refreshControl?.endRefreshing()
                    }
                })
            })
        })
    }
    
    // MARK: NSCoding
    
    func saveSites() -> Void {
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(sites, toFile: Site.ArchiveURL.path!)
        if !isSuccessfulSave {
            print("Failed to save sites...")
        }
    }
    
    func loadSites() -> [Site]? {
        let sites = NSKeyedUnarchiver.unarchiveObjectWithFile(Site.ArchiveURL.path!) as? [Site]
        return sites
    }
    
    func loadSampleSites() -> Void {
        // Create a site URL.
        let site1URL = NSURL(string: "https://benscgm.herokuapp.com")!
        // Create a site.
        let site1 = Site(url: site1URL, apiSecret: " ")!
        
        // Add it to the site Array
        sites = [site1]
    }
    
}
