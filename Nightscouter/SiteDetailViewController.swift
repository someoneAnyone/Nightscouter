//
//  ViewController.swift
//  Nightscout
//
//  Created by Peter Ina on 5/14/15.
//  Copyright (c) 2015 Peter Ina. All rights reserved.
//

import UIKit
import NightscouterKit

class SiteDetailViewController: UIViewController, UIWebViewDelegate {
    
    // MARK: IBOutlets
    @IBOutlet weak var siteCompassControl: CompassControl?
    @IBOutlet weak var siteLastReadingHeader: UILabel?
    @IBOutlet weak var siteLastReadingLabel: UILabel?
    @IBOutlet weak var siteBatteryHeader: UILabel?
    @IBOutlet weak var siteBatteryLabel: UILabel?
    @IBOutlet weak var siteRawHeader: UILabel?
    @IBOutlet weak var siteRawLabel: UILabel?
    @IBOutlet weak var siteNameLabel: UILabel?
    @IBOutlet weak var siteWebView: UIWebView?
    @IBOutlet weak var siteActivityView: UIActivityIndicatorView?
    
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
    var defaultTextColor: UIColor? {
        return Theme.Color.labelTextColor
    }
    
    // MARK: View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        // navigationController?.hidesBarsOnTap = true
        // remove any uneeded decorations from this view if contained within a UI page view controller
        if let pageViewController = parentViewController as? UIPageViewController {
            // println("contained in UIPageViewController")
            self.view.backgroundColor = UIColor.clearColor()
            self.siteNameLabel?.removeFromSuperview()
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
        self.siteWebView?.reload()
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
        
        if let configuration = site?.configuration {
            
            let updateUnits = "updateUnits(\(configuration.displayUnits.hashValue))"
            webView.stringByEvaluatingJavaScriptFromString(updateUnits)
        }
        webView.stringByEvaluatingJavaScriptFromString(updateData)
        webView.hidden = false
    }
}

extension SiteDetailViewController {
    
    func configureView() {
        self.siteCompassControl?.color = NSAssetKit.predefinedNeutralColor
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

                    self.updateTitles(configuration.displayName)
                    
                    if let enabledOptions = configuration.enabledOptions {
                        let rawEnabled =  contains(enabledOptions, EnabledOptions.rawbg)
                        if !rawEnabled {
                            // self.rawHeader!.removeFromSuperview() // Screws with the layout contstraints.
                            // self.rawReadingLabel!.removeFromSuperview()
                            if let rawHeader = self.siteRawHeader {
                                self.siteRawHeader?.hidden = true
                                self.siteRawLabel?.hidden = true
                            }
                        }
                    }
                    self.updateData()
                })
            }
        }
    }
    
    func updateTitles(title: String) {
        self.navigationItem.title = title
        self.navigationController?.navigationItem.title = title
        self.siteNameLabel?.text = title
    }
    
    func updateData() {
        // print(">>> Entering \(__FUNCTION__) <<<")
        if let site = self.site, configuration = site.configuration {
            self.siteActivityView?.startAnimating()
            nsApi!.fetchDataForWatchEntry{ (watchEntry, errorCode) -> Void in
                if let watchEntry = watchEntry, sgv = watchEntry.sgv {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        
                        self.siteCompassControl?.configureWith(site)
                        
                        // Battery label
                        self.siteBatteryLabel?.text = watchEntry.batteryString
                        self.siteBatteryLabel?.textColor = colorForDesiredColorState(watchEntry.batteryColorState)
                        
                        // Last reading label
                        self.siteLastReadingLabel?.text = watchEntry.dateTimeAgoString
                        self.siteLastReadingLabel?.textColor = self.defaultTextColor
                        
                        // Raw label
                        if let rawValue = watchEntry.raw {
                            let color = colorForDesiredColorState(configuration.boundedColorForGlucoseValue(rawValue))
                            
                            var raw = "\(rawValue.formattedForMgdl)"
                            if configuration.displayUnits == .Mmol {
                                raw = rawValue.formattedForMmol
                            }

                            self.siteRawLabel?.textColor = color
                            self.siteRawLabel?.text = "\(raw) : \(sgv.noise)"
                        }
                        
                        let timeAgo = watchEntry.date.timeIntervalSinceNow
                        let isStaleData = configuration.isDataStaleWith(interval: timeAgo)
                        self.siteCompassControl?.shouldLookStale(look: isStaleData.warn)
                        
                        if isStaleData.warn {
                            self.siteBatteryLabel?.text = "---"
                            self.siteBatteryLabel?.textColor = self.defaultTextColor
                            
                            self.siteRawLabel?.text = "--- : ---"
                            self.siteRawLabel?.textColor = self.defaultTextColor
                            
                            self.siteLastReadingLabel?.textColor = NSAssetKit.predefinedWarningColor
                        }
                        
                        if isStaleData.urgent{
                            self.siteLastReadingLabel?.textColor = NSAssetKit.predefinedAlertColor
                        }
                        
                        if timeAgo >= Constants.StandardTimeFrame.TwoHoursInSeconds.inThePast {
                            self.nsApi!.fetchDataForEntries(count: Constants.EntryCount.NumberForChart) { (entries, errorCode) -> Void in
                                if let entries = entries {
                                    for entry in entries {
                                        if let sgv = entry.sgv {
                                            if (sgv.sgv > Double(Constants.EntryCount.LowerLimitForValidSGV)) {
                                                self.data.append(entry.jsonForChart)
                                            }
                                        }
                                    }
                                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                        self.siteActivityView?.stopAnimating()
                                        self.siteWebView?.reload()
                                    })
                                }
                            }
                        } else {
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                self.siteActivityView?.stopAnimating()
                            })
                        }
                    })
                }
            }
        }
    }
    
    func loadWebView () {
        self.siteWebView?.delegate = self
        self.siteWebView?.scrollView.bounces = false
        self.siteWebView?.scrollView.scrollEnabled = false
        
        let filePath = NSBundle.mainBundle().pathForResource("index", ofType: "html", inDirectory: "html")
        let defaultDBPath =  NSBundle.mainBundle().resourcePath?.stringByAppendingPathComponent("html")
        
        let fileExists = NSFileManager.defaultManager().fileExistsAtPath(filePath!)
        if !fileExists {
            NSFileManager.defaultManager().copyItemAtPath(defaultDBPath!, toPath: filePath!, error: nil)
        }
        let request = NSURLRequest(URL: NSURL.fileURLWithPath(filePath!)!)
        self.siteWebView?.loadRequest(request)
    }
    
    func updateScreenOverride(shouldOverride: Bool) {
        self.site!.overrideScreenLock = shouldOverride
        
        AppDataManager.sharedInstance.shouldDisableIdleTimer = self.site!.overrideScreenLock
        AppDataManager.sharedInstance.updateSite(site!)
        UIApplication.sharedApplication().idleTimerDisabled = site!.overrideScreenLock

        #if DEBUG
            println("{site.overrideScreenLock:\(site?.overrideScreenLock), AppDataManager.shouldDisableIdleTimer:\(AppDataManager.sharedInstance.shouldDisableIdleTimer), UIApplication.idleTimerDisabled:\(UIApplication.sharedApplication().idleTimerDisabled)}")
        #endif
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
    
    @IBAction func gotoLabs(sender: UITapGestureRecognizer) {
        #if DEBUG
            let storyboard = UIStoryboard(name: Constants.StoryboardName.Labs.rawValue, bundle: NSBundle.mainBundle())
            NSUserDefaults.standardUserDefaults().setURL(site!.url, forKey: "url")
            
            presentViewController(storyboard.instantiateInitialViewController() as! UIViewController, animated: true) { () -> Void in
                println("Present Labs as a modal controller!")
            }
        #endif
    }
    
    // MARK: Handoff
    
    override func updateUserActivityState(activity: NSUserActivity) {
        activity.webpageURL = site?.url
        super.updateUserActivityState(activity)
    }
}