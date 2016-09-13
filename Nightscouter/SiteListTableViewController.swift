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

class SiteListTableViewController: UITableViewController, AlarmManagerDelgate {
    
    @IBOutlet fileprivate weak var snoozeAlarmButton: UIBarButtonItem!
    
    @IBOutlet fileprivate weak var headerView: BannerMessage!
    
    // MARK: Properties
    
    // Computed Property: Grabs the common set of sites from the data manager.
    var sites: [Site] {
        editButtonItem.isEnabled = !AppDataManageriOS.sharedInstance.sites.isEmpty
        return AppDataManageriOS.sharedInstance.sites
    }
    
    // Whenever this changes, it updates the attributed title of the refresh control.
    var lastUpdatedTime: Date? {
        didSet{
            // Create and use a formatter.
            let dateFormatter = DateFormatter()
            dateFormatter.timeStyle = DateFormatter.Style.medium
            dateFormatter.dateStyle = DateFormatter.Style.medium
            dateFormatter.timeZone = TimeZone.autoupdatingCurrent
            
            if let date = lastUpdatedTime {
                let str = String(stringInterpolation:Constants.LocalizedString.lastUpdatedDateLabel.localized, dateFormatter.string(from: date))
                self.refreshControl!.attributedTitle = NSAttributedString(string:str, attributes: [NSForegroundColorAttributeName:UIColor.white])
            }
            
//            if let headerView = tableView.tableHeaderView as? BannerMessage {
//                headerView.hidden = false
//                headerView.message = AlarmManager.sharedManager.snoozeText
//            }
        }
    }
    
    var siteToDisplay: Site?
    
    // Holds the indexPath of an accessory that was tapped. Used for getting the right Site from the sites array before passing over to the next view.
    var accessoryIndexPath: IndexPath?
    
    // MARK: View controller lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let site = siteToDisplay {
            performSegue(withIdentifier: Constants.SegueIdentifier.ShowPageView.rawValue, sender: site)
        }
        
        // Common setup.
        configureView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Check if we should display a form.
        shouldIShowNewSiteForm()
        
    }
    
    func alarmManagerHasChangedAlarmingState(isActive alarm: Bool, urgent: Bool, snoozed: Bool) {
        
        if alarm == true || snoozed {
            let activeColor = urgent ? NSAssetKit.predefinedAlertColor : NSAssetKit.predefinedWarningColor
            
            snoozeAlarmButton.isEnabled = true
            snoozeAlarmButton.tintColor = activeColor
            
            tableView.tableHeaderView = headerView
            tableView.reloadData()
            
            if let headerView = tableView.tableHeaderView as? BannerMessage {
                headerView.isHidden = false
                headerView.tintColor = activeColor
                headerView.message = snoozed ? AlarmManager.sharedManager.snoozeText : "One or more of your sites are sounding an alarm."
            }
            
        } else if alarm == false && !snoozed {
            snoozeAlarmButton.isEnabled = false
            snoozeAlarmButton.tintColor = nil
            tableView.tableHeaderView = nil
            
        } else {
            snoozeAlarmButton.image = UIImage(named: "alarmIcon")
            tableView.tableHeaderView = nil
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        AlarmManager.sharedManager.removeAlarmManagerDelgate(self)
        
        // Remove this class from the observer list. Was listening for a global update timer.
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return sites.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = Constants.CellIdentifiers.SiteTableViewStyle
        
        // Configure the cell...
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! SiteTableViewCell
        
        configureCell(cell, indexPath: indexPath)
        
        return cell
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            AppDataManageriOS.sharedInstance.deleteSiteAtIndex((indexPath as NSIndexPath).row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            shouldIShowNewSiteForm()
        } else if editingStyle == .insert {
            // self.editing = false
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to toIndexPath: IndexPath) {
        // update the item in my data source by first removing at the from index, then inserting at the to index.
        let site = sites[(fromIndexPath as NSIndexPath).row]
        AppDataManageriOS.sharedInstance.deleteSiteAtIndex((fromIndexPath as NSIndexPath).row)
        AppDataManageriOS.sharedInstance.addSite(site, index: (toIndexPath as NSIndexPath).row)
    }
    
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        if sites.count == 1 {
            return false
        }
        return true
    }
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        accessoryIndexPath = indexPath
    }
    
    override func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return Constants.LocalizedString.tableViewCellRemove.localized
    }
    
    override func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        // cell?.contentView.backgroundColor = NSAssetKit.darkNavColor
        let highlightView = UIView()
        highlightView.backgroundColor = NSAssetKit.darkNavColor
        cell?.selectedBackgroundView = highlightView
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if let identifier = Constants.SegueIdentifier(rawValue: segue.identifier!) {
            switch identifier {
                
            case .EditSite:
                #if DEBUG
                    print("Editing existing site", terminator: "")
                #endif
                isEditing = false
                let siteDetailViewController = segue.destination as! SiteFormViewController
                // Get the cell that generated this segue.
                if let selectedSiteCell = sender as? UITableViewCell {
                    let indexPath = tableView.indexPath(for: selectedSiteCell)!
                    let selectedSite = sites[(indexPath as NSIndexPath).row]
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
                let siteDetailViewController = segue.destination as! SiteDetailViewController
                // Get the cell that generated this segue.
                if let selectedSiteCell = sender as? UITableViewCell {
                    let indexPath = tableView.indexPath(for: selectedSiteCell)!
                    let selectedSite = sites[(indexPath as NSIndexPath).row]
                    siteDetailViewController.site = selectedSite
                }
                
            case .ShowPageView:
                // let siteListPageViewController = segue.destinationViewController as! SiteListPageViewController
                // Get the cell that generated this segue.
                if let selectedSiteCell = sender as? UITableViewCell {
                    let indexPath = tableView.indexPath(for: selectedSiteCell)!
                    AppDataManageriOS.sharedInstance.currentSiteIndex = (indexPath as NSIndexPath).row
                }
                
                if let incomingSite = sender as? Site{
                    if let indexOfSite = sites.index(of: incomingSite) {
                        AppDataManageriOS.sharedInstance.currentSiteIndex = indexOfSite
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
    
    @IBAction func manageAlarm(_ sender: AnyObject?) {
        AlarmManager.sharedManager.presentSnoozePopup(forViewController: self)
    }
    
    @IBAction func goToSettings(_ sender: AnyObject?) {
        let settingsUrl = URL(string: UIApplicationOpenSettingsURLString)
        UIApplication.shared.openURL(settingsUrl!)
    }
    
    @IBAction func unwindToSiteList(_ sender: UIStoryboardSegue) {
        
        if let sourceViewController = sender.source as? SiteFormViewController, let site = sourceViewController.site {
            site.disabled = false
            // This segue is triggered when we "save" or "next" out of the url form.
            if let selectedIndexPath = accessoryIndexPath {
                // Update an existing site.
                AppDataManageriOS.sharedInstance.updateSite(site)
                self.refreshDataFor(site, index: (selectedIndexPath as NSIndexPath).row)
                //tableView.reloadRowsAtIndexPaths([selectedIndexPath], withRowAnimation: .None)
                accessoryIndexPath = nil
            } else {
                // Add a new site.
                isEditing = false
                let newIndexPath = IndexPath(row: 0, section: 0)
                AppDataManageriOS.sharedInstance.addSite(site, index: (newIndexPath as NSIndexPath).row)
                
                accessoryIndexPath = nil
                guard let _ = tableView.cellForRow(at: newIndexPath) else {
                    
                    tableView.reloadData()
                    return
                }

                tableView.insertRows(at: [newIndexPath], with: .automatic)
                
            }
        }
        
        if let pageViewController = sender.source as? SiteListPageViewController {
            // let modelController = pageViewController.modelController
            // let site = modelController.sites[pageViewController.currentIndex]
            tableView.reloadRows(at: [IndexPath(row: pageViewController.currentIndex, section: 0)], with: .none)
        }
        shouldIShowNewSiteForm()
    }
    
    var timer: Timer?
    // MARK: Private Methods
    func configureView() -> Void {
        // The following line displys an Edit button in the navigation bar for this view controller.
        navigationItem.leftBarButtonItem = self.editButtonItem
        
        // Only allow the edit button to be enabled if there are items in the sites array.
        clearsSelectionOnViewWillAppear = true
        
        // Configure table view properties.
        tableView.estimatedRowHeight = 200
        tableView.rowHeight = UITableViewAutomaticDimension//240
        tableView.backgroundView = BackgroundView() // TODO: Move this out to a theme manager.
        tableView.separatorColor = NSAssetKit.darkNavColor
        
        // Position refresh control above background view
        refreshControl?.tintColor = UIColor.white
        refreshControl?.layer.zPosition = tableView.backgroundView!.layer.zPosition + 1
        
        
        let triggerTime = (Int64(NSEC_PER_SEC) * 5)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(triggerTime) / Double(NSEC_PER_SEC), execute: { () -> Void in
            self.setupNotifications()
            self.timer = Timer(timeInterval: 60.0, target: self, selector: #selector(SiteListTableViewController.updateUI as (SiteListTableViewController) -> () -> ()), userInfo: nil, repeats: true)
        })
        
        // Make sure the idle screen timer is turned back to normal. Screen will time out.
        UIApplication.shared.isIdleTimerDisabled = false
        
        
        AlarmManager.sharedManager.addAlarmManagerDelgate(self)
    }
    
    func updateUI() {
        self.tableView.reloadData()
    }
    
    func setupNotifications() {
        // Listen for global update timer.
        NotificationCenter.default.addObserver(self, selector: #selector(SiteListTableViewController.updateData), name: NSNotification.Name(rawValue: NightscoutAPIClientNotification.DataIsStaleUpdateNow), object: nil)
    }
    
    // For a given cell and index path get the appropriate site object and assign various properties.
    func configureCell(_ cell: SiteTableViewCell, indexPath: IndexPath) -> Void {
        let site = sites[(indexPath as NSIndexPath).row]
        cell.configureCell(site)
        // FIXME:// this prevents a loop, but needs to be fixed and errors need to be reported.
        if (site.updateNow || lastUpdatedTime == nil || site.configuration == nil) {
            refreshDataFor(site, index: (indexPath as NSIndexPath).row)
        }
    }
    
    func shouldIShowNewSiteForm() {
        // If the sites array is empty show a vesion of the form that does not allow escape.
        if sites.isEmpty{
            let vc = storyboard?.instantiateViewController(withIdentifier: Constants.StoryboardViewControllerIdentifier.SiteFormViewController.rawValue) as! SiteFormViewController
            self.parent!.present(vc, animated: true, completion: { () -> Void in
                // println("Finished presenting SiteFormViewController.")
            })
        } else {
            dismiss(animated: true, completion: { () -> Void in
                self.updateData()
            })
        }
    }
    
    // MARK: Fetch data via REST API
    
    func updateData(){
        // Do not allow refreshing to happen if there is no data in the sites array.
        if sites.isEmpty == false {
            if refreshControl?.isRefreshing == false {
                refreshControl?.beginRefreshing()
                tableView.setContentOffset(CGPoint(x: 0, y: tableView.contentOffset.y-refreshControl!.frame.size.height), animated: true)
            }
            for (index, site) in sites.enumerated() {
                refreshDataFor(site, index: index)
            }
            
        } else {
            // No data in the sites array. Cancel the refreshing!
            refreshControl?.endRefreshing()
        }
    }
    
    func refreshDataFor(_ site: Site, index: Int){
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        fetchSiteData(site) { (returnedSite, error: NightscoutAPIError) -> Void in
            defer {
                print("setting networkActivityIndicatorVisible: false and stopping animation.")
                AppDataManageriOS.sharedInstance.updateSite(returnedSite)
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                
                if (self.refreshControl?.isRefreshing != nil) {
                    self.refreshControl?.endRefreshing()
                }
            }
            
            switch error {
            case .noError:
                self.lastUpdatedTime = returnedSite.lastConnectedDate
                if let _ = self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) , self.tableView.numberOfRows(inSection: 0)<0 {

                    self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                } else {
                    self.tableView.reloadData()
                }
                return
                
            default:
                let err = error
                self.presentAlertDialog(site.url, index: index, error: err.description)
            }
        }
    }
    
    // Attempt to handle an error.
    func presentAlertDialog(_ siteURL:URL, index: Int, error: String) {
        
        let alertController = UIAlertController(title: Constants.LocalizedString.uiAlertBadSiteTitle.localized, message: String(format: Constants.LocalizedString.uiAlertBadSiteMessage.localized, siteURL as CVarArg, error), preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: Constants.LocalizedString.generalCancelLabel.localized, style: .cancel) { (action) in
            // ...
        }
        alertController.addAction(cancelAction)
        
        let retryAction = UIAlertAction(title: Constants.LocalizedString.generalRetryLabel.localized, style: .default) { (action) in
            let indexPath = IndexPath(row: index, section: 0)
            let site = AppDataManageriOS.sharedInstance.sites[(indexPath as NSIndexPath).row]
            site.disabled = false
            AppDataManageriOS.sharedInstance.updateSite(site)
            
            self.refreshDataFor(site, index: (indexPath as NSIndexPath).row)
            // self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
        }
        alertController.addAction(retryAction)
        
        let editAction = UIAlertAction(title: Constants.LocalizedString.generalEditLabel.localized, style: .default) { (action) in
            let indexPath = IndexPath(row: index, section: 0)
            let tableViewCell = self.tableView.cellForRow(at: indexPath)
            self.accessoryIndexPath = indexPath
            self.performSegue(withIdentifier: Constants.SegueIdentifier.EditSite.rawValue, sender:tableViewCell)
        }
        alertController.addAction(editAction)
        
        let removeAction = UIAlertAction(title: Constants.LocalizedString.tableViewCellRemove.localized, style: .destructive) { (action) in
            self.tableView.beginUpdates()
            AppDataManageriOS.sharedInstance.deleteSiteAtIndex(index)
            self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
            self.tableView.endUpdates()
        }
        alertController.addAction(removeAction)
        
        alertController.view.tintColor = NSAssetKit.darkNavColor
        
        self.view.window?.tintColor = nil
        
        self.navigationController?.popToRootViewController(animated: true)
        
        self.present(alertController, animated: true) {
            // remove nsnotification observer?
            // ...
        }
    }
    
    
}


extension SiteListTableViewController: UpdatableUserInterfaceType {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startUpdateUITimer()
    }
    
    func updateUI(_ notif: Timer) {
        print("updating ui for: \(notif)")
        self.tableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        updateUITimer.invalidate()
    }
}


