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

class SiteListTableViewController: UITableViewController, SitesDataSourceProvider, SegueHandlerType {
    
    struct CellIdentifier {
        static let SiteTableViewStyle = "siteCell"
    }
    
    @IBOutlet fileprivate weak var snoozeAlarmButton: UIBarButtonItem!
    
    @IBOutlet fileprivate weak var headerView: BannerMessage!
    
    enum SegueIdentifier: String {
        case EditExisting, ShowDetail, AddNew, AddNewWhenEmpty, LaunchLabs, ShowPageView, unwindToSiteList
    }
    
    // MARK: Properties
    
    // Computed Property: Grabs the common set of sites from the data manager.
    var sites: [Site] {
        return SitesDataSource.sharedInstance.sites
    }
    
    var milliseconds: Double = 0 {
        didSet{
            let str = String(stringInterpolation:LocalizedString.lastUpdatedDateLabel.localized, AppConfiguration.lastUpdatedDateFormatter.string(from: date))
            self.refreshControl?.attributedTitle = NSAttributedString(string:str, attributes: [NSForegroundColorAttributeName: Color.white])
            self.refreshControl?.endRefreshing()
        }
    }
    
    var siteToDisplay: Site?
    
    // Holds the indexPath of an accessory that was tapped. Used for getting the right Site from the sites array before passing over to the next view.
    var accessoryIndexPath: IndexPath?
    
    // MARK: View controller lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let site = siteToDisplay {
            performSegue(withIdentifier: SegueIdentifier.ShowPageView.rawValue, sender: site)
        }
        tableView.tableHeaderView = nil
        // Common setup.
        configureView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
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
        let cellIdentifier = CellIdentifier.SiteTableViewStyle
        
        // Configure the cell...
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! SiteTableViewCell
        
        configureCell(cell, indexPath: indexPath)
        
        return cell
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            
            let site = sites[indexPath.row]
            SitesDataSource.sharedInstance.deleteSite(site)
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
        let site = sites[fromIndexPath.row]
        SitesDataSource.sharedInstance.deleteSite(site)
        SitesDataSource.sharedInstance.createSite(site, atIndex: toIndexPath.row)
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
        return LocalizedString.tableViewCellRemove.localized
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
        
        if let identifier = SegueIdentifier(rawValue: segue.identifier!) {
            switch identifier {
                
            case .EditExisting:
                #if DEBUG
                    print("Editing existing site", terminator: "")
                #endif
                isEditing = false
                let siteDetailViewController = segue.destination as! SiteFormViewController
                // Get the cell that generated this segue.
                if let selectedSiteCell = sender as? UITableViewCell {
                    let indexPath = tableView.indexPath(for: selectedSiteCell)!
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
                let siteDetailViewController = segue.destination as! SiteDetailViewController
                // Get the cell that generated this segue.
                if let selectedSiteCell = sender as? UITableViewCell {
                    let indexPath = tableView.indexPath(for: selectedSiteCell)!
                    let selectedSite = sites[indexPath.row]
                    siteDetailViewController.site = selectedSite
                }
                
            case .ShowPageView:
                // let siteListPageViewController = segue.destinationViewController as! SiteListPageViewController
                // Get the cell that generated this segue.
                if let selectedSiteCell = sender as? UITableViewCell {
                    let indexPath = tableView.indexPath(for: selectedSiteCell)!
                    SitesDataSource.sharedInstance.lastViewedSiteIndex = indexPath.row
                }
                
                if let incomingSite = sender as? Site{
                    if let indexOfSite = sites.index(of: incomingSite) {
                        SitesDataSource.sharedInstance.lastViewedSiteIndex = indexOfSite
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
//        AlarmManager.sharedManager.presentSnoozePopup(forViewController: self)
    }
    
    @IBAction func goToSettings(_ sender: AnyObject?) {
        let settingsUrl = URL(string: UIApplicationOpenSettingsURLString)
        UIApplication.shared.openURL(settingsUrl!)
    }
    
    @IBAction func unwindToSiteList(_ sender: UIStoryboardSegue) {
        
        if let sourceViewController = sender.source as? SiteFormViewController, let site = sourceViewController.site {
            
            var newSite = site
            
            newSite.disabled = false
            // This segue is triggered when we "save" or "next" out of the url form.
            if let selectedIndexPath = accessoryIndexPath {
                // Update an existing site.
                SitesDataSource.sharedInstance.updateSite(newSite)
                self.refreshDataFor(site, index: selectedIndexPath.row)
                //tableView.reloadRowsAtIndexPaths([selectedIndexPath], withRowAnimation: .None)
                accessoryIndexPath = nil
            } else {
                // Add a new site.
                isEditing = false
                let newIndexPath = IndexPath(row: 0, section: 0)
                SitesDataSource.sharedInstance.createSite(site, atIndex: newIndexPath.row)
                
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
        
      
        
        self.setupNotifications()
      
        self.timer = Timer(timeInterval: 60.0, target: self, selector: #selector(SiteListTableViewController.updateUI as (SiteListTableViewController) -> () -> ()), userInfo: nil, repeats: true)
        
        // Make sure the idle screen timer is turned back to normal. Screen will time out.
        UIApplication.shared.isIdleTimerDisabled = false
        
        
        
        // TODO: If there is only one site in the array, push to the detail controller right away. If a new or second one is added dismiss and return to table view.
        // TODO: Faking a data transfter date.
        // TODO: Need to update the table when data changes... also need to call updateTable if empty to show an empty row.
        //        NSNotificationCenter.defaultCenter().addObserverForName(DataUpdatedNotification, object: nil, queue: NSOperationQueue.mainQueue()) { (_) -> Void in
        //            self.tableView.reloadData()
        //        }
    }
    
    func updateUI() {
        self.tableView.reloadData()
    }
    
    func setupNotifications() {
        // Listen for global update timer.
        NotificationCenter.default.addObserver(self, selector: #selector(SiteListTableViewController.updateData), name: .NightscoutDataStaleNotification, object: nil)
    }
    
    // For a given cell and index path get the appropriate site object and assign various properties.
    func configureCell(_ cell: SiteTableViewCell, indexPath: IndexPath) -> Void {
        let site = sites[indexPath.row]
        let model = site.summaryViewModel
        cell.configure(withDataSource: model, delegate: model)
        // FIXME:// this prevents a loop, but needs to be fixed and errors need to be reported.
        if (site.updateNow || site.configuration == nil) {
            refreshDataFor(site, index: indexPath.row)
        }
    }
    
    func shouldIShowNewSiteForm() {
        // If the sites array is empty show a vesion of the form that does not allow escape.
        if sites.isEmpty{
            let vc = storyboard?.instantiateViewController(withIdentifier: StoryboardIdentifier.formViewController.rawValue) as! SiteFormViewController
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
             //   tableView.setContentOffset(CGPoint(x: 0, y: tableView.contentOffset.y-refreshControl!.frame.size.height), animated: true)
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
        
        Nightscout().networkRequest(forNightscoutURL: site.url, apiPassword: site.apiSecret, userInitiated: false) { (config, sgvs, cals, mbgs, devices, err) in
            
            defer {
                print("setting networkActivityIndicatorVisible: false and stopping animation.")
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                
                if (self.refreshControl?.isRefreshing != nil) {
                    self.refreshControl?.endRefreshing()
                }
            }
            
            if let error = err {
                print(error.kind)
                fatalError()
            }
            
            // Process the updates to the site.
            var updatedSite = site
            
            if let conf = config {
                updatedSite.configuration = conf
                
            }
            
            if let sgvs = sgvs {
                updatedSite.sgvs = sgvs
            }
            
            if let mbgs = mbgs {
                updatedSite.mbgs = mbgs
            }
            
            if let cals = cals {
                updatedSite.cals = cals
            }
            
            if let deviceStatus = devices {
                updatedSite.deviceStatuses = deviceStatus
            }
            
            self.milliseconds = Date().timeIntervalSince1970.millisecond
            updatedSite.lastUpdatedDate =  self.milliseconds.toDateUsingMilliseconds()
            updatedSite.generateComplicationData()
            
            SitesDataSource.sharedInstance.updateSite(updatedSite)

            OperationQueue.main.addOperation {
                //self.sites[indexPath.item] = updatedSite
            
                

//                if let _ = self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) , self.tableView.numberOfRows(inSection: 0)<0 {
//                    
//                    self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
//                } else {
                    self.tableView.reloadData()
//                }

                
            }
        }
        /*
        fetchSiteData(site) { (returnedSite, error: NightscoutAPIError) -> Void in
            defer {
                print("setting networkActivityIndicatorVisible: false and stopping animation.")
                SitesDataSource.sharedInstance.updateSite(returnedSite)
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
         */
    }
    
    // Attempt to handle an error.
    func presentAlertDialog(_ siteURL:URL, index: Int, error: String) {
        
        let alertController = UIAlertController(title: LocalizedString.uiAlertBadSiteTitle.localized, message: String(format: LocalizedString.uiAlertBadSiteMessage.localized, siteURL as CVarArg, error), preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: LocalizedString.generalCancelLabel.localized, style: .cancel) { (action) in
            // ...
        }
        alertController.addAction(cancelAction)
        
        let retryAction = UIAlertAction(title: LocalizedString.generalRetryLabel.localized, style: .default) { (action) in
            let indexPath = IndexPath(row: index, section: 0)
            var site = SitesDataSource.sharedInstance.sites[indexPath.row]
            site.disabled = false
            SitesDataSource.sharedInstance.updateSite(site)
            
            self.refreshDataFor(site, index: indexPath.row)
            // self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
        }
        alertController.addAction(retryAction)
        
        let editAction = UIAlertAction(title: LocalizedString.generalEditLabel.localized, style: .default) { (action) in
            let indexPath = IndexPath(row: index, section: 0)
            let tableViewCell = self.tableView.cellForRow(at: indexPath)
            self.accessoryIndexPath = indexPath
            self.performSegue(withIdentifier: SegueIdentifier.EditExisting.rawValue, sender:tableViewCell)
        }
        alertController.addAction(editAction)
        
        let removeAction = UIAlertAction(title: LocalizedString.tableViewCellRemove.localized, style: .destructive) { (action) in
            self.tableView.beginUpdates()
            
            let site = SitesDataSource.sharedInstance.sites[index]
            SitesDataSource.sharedInstance.deleteSite(site)
            self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
            self.tableView.endUpdates()
        }
        alertController.addAction(removeAction)
        
        alertController.view.tintColor = NSAssetKit.darkNavColor
        
        self.view.window?.tintColor = nil
        
        let _ = self.navigationController?.popToRootViewController(animated: true)
        
        self.present(alertController, animated: true) {
            // remove nsnotification observer?
            // ...
        }
    }
    
    
}



//    func alarmManagerHasChangedAlarmingState(isActive alarm: Bool, urgent: Bool, snoozed: Bool) {
//
//        if alarm == true || snoozed {
//            let activeColor = urgent ? NSAssetKit.predefinedAlertColor : NSAssetKit.predefinedWarningColor
//
//            snoozeAlarmButton.isEnabled = true
//            snoozeAlarmButton.tintColor = activeColor
//
//            tableView.tableHeaderView = headerView
//            tableView.reloadData()
//
//            if let headerView = tableView.tableHeaderView as? BannerMessage {
//                headerView.isHidden = false
//                headerView.tintColor = activeColor
////                headerView.message = snoozed ? AlarmManager.sharedManager.snoozeText : "One or more of your sites are sounding an alarm."
//            }
//
//        } else if alarm == false && !snoozed {
//            snoozeAlarmButton.isEnabled = false
//            snoozeAlarmButton.tintColor = nil
//            tableView.tableHeaderView = nil
//
//        } else {
//            snoozeAlarmButton.image = UIImage(named: "alarmIcon")
//            tableView.tableHeaderView = nil
//        }
//    }

/*
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
*/

