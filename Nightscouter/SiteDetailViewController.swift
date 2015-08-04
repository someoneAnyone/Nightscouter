//
//  ViewController.swift
//  Nightscout
//
//  Created by Peter Ina on 5/14/15.
//  Copyright (c) 2015 Peter Ina. All rights reserved.
//

import UIKit

class SiteDetailViewController: UIViewController, UIWebViewDelegate {
    
    // MARK: IBOutlets
    @IBOutlet weak var compassControl: CompassControl?
    @IBOutlet weak var lastReadingHeader: UILabel?
    @IBOutlet weak var lastReadingLabel: UILabel?
    @IBOutlet weak var batteryHeader: UILabel?
    @IBOutlet weak var uploaderBatteryLabel: UILabel?
    @IBOutlet weak var rawHeader: UILabel?
    @IBOutlet weak var rawReadingLabel: UILabel?
    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var webView: UIWebView?
    @IBOutlet weak var activityView: UIActivityIndicatorView?
    
    // MARK: Properties
    var site: Site? {
        didSet {
            if (site != nil){
                configureView()
            }
        }
    }
    var nsApi: NightscoutAPIClient?
    var data = [AnyObject]()
    var defaultTextColor: UIColor?
    
    // MARK: View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        defaultTextColor = self.titleLabel!.textColor
        
        // Do any additional setup after loading the view, typically from a nib.
        // navigationController?.hidesBarsOnTap = true
        // remove any uneeded decorations from this view if contained within a UI page view controller
        if let pageViewController = parentViewController as? UIPageViewController {
            // println("contained in UIPageViewController")
            self.view.backgroundColor = UIColor.clearColor()
            self.titleLabel?.removeFromSuperview()
        }
        
        configureView()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        data.removeAll()
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        self.webView?.reload()
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
}

extension SiteDetailViewController{
    @IBAction func unwindToSiteDetail(segue:UIStoryboardSegue) {
        // print(">>> Entering \(__FUNCTION__) <<<")
        // print("\(segue)")
    }
}

// Mark: WebKit WebView Delegates
extension SiteDetailViewController {
    func webViewDidFinishLoad(webView: UIWebView) {
        // print(">>> Entering \(__FUNCTION__) <<<")
        let updateData = "updateData(\(self.data))"
        
        if let units = self.site?.configuration?.unitsRoot {
            let updateUnits = "updateUnits(\(units.rawValue))"
            webView.stringByEvaluatingJavaScriptFromString(updateUnits)
        }
        webView.stringByEvaluatingJavaScriptFromString(updateData)
        webView.hidden = false
    }
}

extension SiteDetailViewController {
    
    func configureView() { // Just do it!
        self.compassControl?.color = NSAssetKit.predefinedNeutralColor
        self.loadWebView()
        
        if let siteOptional = site {
            nsApi = NightscoutAPIClient(url:siteOptional.url)
            AppDataManager.sharedInstance.shouldDisableIdleTimer = siteOptional.overrideScreenLock
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateSite:", name: Constants.Notification.DataIsStaleUpdateNow, object: nil)
            
            updateSite(nil)
        }
    }
    
    func updateSite(notification: NSNotification?) {
        nsApi!.fetchServerConfiguration { (result) -> Void in
            switch (result) {
            case let .Error(error):
                // display error message
                // println("error: \(error)")
                self.navigationController?.popViewControllerAnimated(true)
                
            case let .Value(boxedConfiguration):
                let configuration:ServerConfiguration = boxedConfiguration.value
                // Get back on the main queue to update the user interface
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    if let defaults = configuration.defaults {
                        self.navigationItem.title = defaults.customTitle
                        self.navigationController?.navigationItem.title = defaults.customTitle
                        self.titleLabel?.text = defaults.customTitle
                    } else {
                        self.navigationItem.title = configuration.name
                        self.navigationController?.navigationItem.title = configuration.name
                        self.titleLabel?.text = configuration.name
                    }
                    
                    if let enabledOptions = configuration.enabledOptions {
                        let rawEnabled =  contains(enabledOptions, EnabledOptions.rawbg)
                        if !rawEnabled {
                            // self.rawHeader!.removeFromSuperview() // Screws with the layout contstraints.
                            // self.rawReadingLabel!.removeFromSuperview()
                            if let rawHeader = self.rawHeader {
                                self.rawHeader?.hidden = true
                                self.rawReadingLabel?.hidden = true
                            }
                        }
                    }
                    self.updateData()
                })
            }
        }
    }
    
    func updateData() {
        // print(">>> Entering \(__FUNCTION__) <<<")
        self.activityView?.startAnimating()
        
        if let site = self.site, configuration = site.configuration, defaults = configuration.defaults {
            
            nsApi!.fetchDataForWatchEntry{ (watchEntry, errorCode) -> Void in
                if let watchEntry = watchEntry, sgv = watchEntry.sgv {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        
                        self.compassControl?.configureWith(site)
                        
                        // Battery label
                        self.uploaderBatteryLabel?.text = watchEntry.batteryString
                        self.uploaderBatteryLabel?.textColor = colorForDesiredColorState(watchEntry.batteryColorState)
                        
                        // Last reading label
                        self.lastReadingLabel?.text = watchEntry.dateTimeAgoString
                        self.lastReadingLabel?.textColor = self.defaultTextColor
                        
                        // Raw label
                        if let rawValue = watchEntry.raw {
                            let color = colorForDesiredColorState(configuration.boundedColorForGlucoseValue(Int(rawValue)))
                            self.rawReadingLabel?.textColor = color
                            self.rawReadingLabel?.text = "\(NSNumberFormatter.localizedStringFromNumber(rawValue, numberStyle: NSNumberFormatterStyle.DecimalStyle)) : \(sgv.noise)"
                        }
                        
                        let timeAgo = watchEntry.date.timeIntervalSinceNow
                        let isStaleData = configuration.isDataStaleWith(interval: timeAgo)
                        self.compassControl?.shouldLookStale(look: isStaleData.warn)
                        
                        if isStaleData.warn {
                            self.uploaderBatteryLabel?.text = "---"
                            self.uploaderBatteryLabel?.textColor = self.defaultTextColor
                            
                            self.rawReadingLabel?.text = "--- : ---"
                            self.rawReadingLabel?.textColor = self.defaultTextColor
                            
                            self.lastReadingLabel?.textColor = NSAssetKit.predefinedWarningColor
                        }
                        
                        if isStaleData.urgent{
                            self.lastReadingLabel?.textColor = NSAssetKit.predefinedAlertColor
                        }
                        
                        if timeAgo >= Constants.StandardTimeFrame.TwoHoursInSeconds.inThePast {
                            self.nsApi!.fetchDataForEntries(count: Constants.EntryCount.NumberForChart) { (entries, errorCode) -> Void in
                                if let entries = entries {
                                    for entry in entries {
                                        if let sgv = entry.sgv {
                                            if (sgv.sgv > Constants.EntryCount.LowerLimitForValidSGV) {
                                                self.data.append(entry.jsonForChart)
                                            }
                                        }
                                    }
                                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                        self.activityView?.stopAnimating()
                                        self.webView?.reload()
                                    })
                                }
                            }
                        } else {
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                self.activityView?.stopAnimating()
                            })
                        }
                    })
                }
            }
        }
    }
    
    func loadWebView () {
        self.webView?.delegate = self
        self.webView?.scrollView.bounces = false
        self.webView?.scrollView.scrollEnabled = false
        
        let filePath = NSBundle.mainBundle().pathForResource("index", ofType: "html", inDirectory: "html")
        let defaultDBPath =  NSBundle.mainBundle().resourcePath?.stringByAppendingPathComponent("html")
        
        let fileExists = NSFileManager.defaultManager().fileExistsAtPath(filePath!)
        if !fileExists {
            NSFileManager.defaultManager().copyItemAtPath(defaultDBPath!, toPath: filePath!, error: nil)
        }
        let request = NSURLRequest(URL: NSURL.fileURLWithPath(filePath!)!)
        self.webView?.loadRequest(request)
    }
    
    @IBAction func gotoSiteSettings(sender: UIBarButtonItem) {
        
        let alertController = UIAlertController(title: Constants.LocalizedString.uiAlertScreenOverrideTitle.localized, message: Constants.LocalizedString.uiAlertScreenOverrideMessage.localized, preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        alertController.view.tintColor = NSAssetKit.darkNavColor
        
        let cancelAction = UIAlertAction(title: Constants.LocalizedString.generalCancelLabel.localized, style: .Cancel) { (action) in
            #if DEBUG
                println("Canceled action: \(action)")
            #endif
        }
        alertController.addAction(cancelAction)
        
        let checkEmoji = "✓ "
        
        var yesString = "   "
        if site!.overrideScreenLock == true {
            yesString = checkEmoji
        }
        let yesAction = UIAlertAction(title: "\(yesString)\(Constants.LocalizedString.generalYesLabel.localized)", style: UIAlertActionStyle.Default) { (action) -> Void in
            self.updateScreenOverride(true)
            #if DEBUG
                println("Yes action: \(action)")
            #endif
        }
        alertController.addAction(yesAction)
        
        var noString = "   "
        if (site!.overrideScreenLock == false) {
            noString = checkEmoji
        }
        let noAction = UIAlertAction(title: "\(noString)\(Constants.LocalizedString.generalNoLabel.localized)", style: UIAlertActionStyle.Default) { (action) -> Void in
            self.updateScreenOverride(false)
            #if DEBUG
                println("No action: \(action)")
            #endif
        }
        alertController.addAction(noAction)
        
        self.presentViewController(alertController, animated: true) {
            #if DEBUG
                println("presentViewController: \(alertController.debugDescription)")
            #endif
        }
    }
    
    func updateScreenOverride(shouldOverride: Bool) {
        self.site!.overrideScreenLock = shouldOverride
        
        AppDataManager.sharedInstance.shouldDisableIdleTimer = self.site!.overrideScreenLock
        AppDataManager.sharedInstance.updateSite(site!)
        
        #if DEBUG
            println("{site.overrideScreenLock:\(site?.overrideScreenLock), AppDataManager.shouldDisableIdleTimer:\(AppDataManager.sharedInstance.shouldDisableIdleTimer), UIApplication.idleTimerDisabled:\(UIApplication.sharedApplication().idleTimerDisabled)}")
        #endif
    }
    
    @IBAction func gotoLabs(sender: UITapGestureRecognizer) {
        // #if DEBUG
        let storyboard = UIStoryboard(name: UIStoryboard.StoryboardName.Labs.rawValue, bundle: NSBundle.mainBundle())
        NSUserDefaults.standardUserDefaults().setURL(site!.url, forKey: "url")
        
        presentViewController(storyboard.instantiateInitialViewController() as! UIViewController, animated: true) { () -> Void in
            println("Present Labs as a modal controller!")
        }
        // #endif
    }
    
    
    
    
    // MARK: Handoff
    
    override func updateUserActivityState(activity: NSUserActivity) {
        activity.webpageURL = site?.url
        //        activity.addUserInfoEntriesFromDictionary([Constants.ActivityKey.ActivitySiteKey: site])
        super.updateUserActivityState(activity)
    }
    /*
    override func restoreUserActivityState(activity: NSUserActivity) {
    if let userInfo = activity.userInfo {
    var activityItem: AnyObject? = userInfo[Constants.ActivityKey.ActivitySiteKey]
    if let itemToRestore = activityItem as? String {
    //                item = itemToRestore
    //                textField?.text = item
    }
    }
    super.restoreUserActivityState(activity)
    }
    */
}