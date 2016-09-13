//
//  ViewController.swift
//  Nightscout
//
//  Created by Peter Ina on 5/14/15.
//  Copyright (c) 2015 Peter Ina. All rights reserved.
//

import UIKit
import NightscouterKit

class SiteDetailViewController: UIViewController, UIWebViewDelegate, AlarmManagerDelgate {
    
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
    
    @IBOutlet fileprivate weak var snoozeAlarmButton: UIBarButtonItem!
    @IBOutlet fileprivate weak var headerView: BannerMessage?
    
    // MARK: Properties
    var site: Site? {
        didSet {
            if (site != nil){
                configureView()
            }
        }
    }
    // var nsApi: NightscoutAPIClient?
    var data = [AnyObject]()
    
    // MARK: View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // remove any uneeded decorations from this view if contained within a UI page view controller
        if let _ = parent as? UIPageViewController {
            // println("contained in UIPageViewController")
            self.view.backgroundColor = UIColor.clear
            self.siteNameLabel?.removeFromSuperview()
        }
        
        AlarmManager.sharedManager.addAlarmManagerDelgate(self)
        configureView()
    }
    
    func alarmManagerHasChangedAlarmingState(isActive alarm: Bool, urgent: Bool, snoozed: Bool) {
        
        if alarm == true {
            let activeColor = urgent ? NSAssetKit.predefinedAlertColor : NSAssetKit.predefinedWarningColor
            
            snoozeAlarmButton.isEnabled = true
            snoozeAlarmButton.tintColor = activeColor
            
            
            headerView?.isHidden = false
            
            headerView?.tintColor = activeColor
            headerView?.message = "One or more of your sites are sounding an alarm."
            
            
        } else if alarm == false && !snoozed {
            headerView?.isHidden = true
            snoozeAlarmButton.isEnabled = false
            snoozeAlarmButton.tintColor = nil
        }
        
        if snoozed {
            headerView?.isHidden = false
            headerView?.message = AlarmManager.sharedManager.snoozeText
            
            snoozeAlarmButton.image = UIImage(named: "alarmSliencedIcon")
        } else {
            snoozeAlarmButton.image = UIImage(named: "alarmIcon")
        }
        
    }
    
    deinit {
        AlarmManager.sharedManager.removeAlarmManagerDelgate(self)
        
        NotificationCenter.default.removeObserver(self)
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        // nsApi?.task?.cancel()
        data.removeAll()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        self.siteWebView?.reload()
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
}

extension SiteDetailViewController{
    @IBAction func unwindToSiteDetail(_ segue:UIStoryboardSegue) {
        // print(">>> Entering \(#function) <<<")
        // print("\(segue)")
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        UIApplication.shared.isIdleTimerDisabled = false
    }
}

// MARK: WebKit WebView Delegates
extension SiteDetailViewController {
    func webViewDidFinishLoad(_ webView: UIWebView) {
        // print(">>> Entering \(#function) <<<")
        let updateData = "updateData(\(self.data))"
        
        if let configuration = site?.configuration {
            
            let updateUnits = "updateUnits(\(configuration.displayUnits.hashValue))"
            webView.stringByEvaluatingJavaScript(from: updateUnits)
        }
        webView.stringByEvaluatingJavaScript(from: updateData)
        webView.isHidden = false
        
        if let configuration = self.site?.configuration {
            updateTitles(configuration.displayName)
        }
    }
}

extension SiteDetailViewController {
    
    func configureView() {
        self.siteCompassControl?.color = NSAssetKit.predefinedNeutralColor
        self.loadWebView()


        NotificationCenter.default.addObserver(self, selector: #selector(SiteDetailViewController.updateSite(_:)), name: NSNotification.Name(rawValue: NightscoutAPIClientNotification.DataIsStaleUpdateNow), object: nil)
        
        if let siteOptional = site {
            // nsApi = NightscoutAPIClient(url:siteOptional.url)
            UIApplication.shared.isIdleTimerDisabled = siteOptional.overrideScreenLock
            
        } else {
            site = AppDataManageriOS.sharedInstance.sites[AppDataManageriOS.sharedInstance.currentSiteIndex]
        }
        
        updateData()
    }
    
    func updateSite(_ notification: Notification?) {
        print(">>> Entering \(#function) <<<")
        self.updateData()
    }
    
    func updateTitles(_ title: String) {
        self.navigationItem.title = title
        self.navigationController?.navigationItem.title = title
        self.siteNameLabel?.text = title
    }
    
    func updateData(forceUpdate force: Bool = false) {
        guard let site = self.site else { return }
        
        if (site.lastConnectedDate?.compare(site.nextRefreshDate) == .orderedDescending || site.entries == nil || site.configuration == nil || force == true) {
            
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            self.siteActivityView?.startAnimating()
            
            fetchSiteData(site, handler: { (returnedSite, error) -> Void in
                AppDataManageriOS.sharedInstance.updateSite(returnedSite)
                self.updateUI()
            })
        } else {
            self.updateUI()
        }
    }
    
    func updateUI() {
        defer {
            print("setting networkActivityIndicatorVisible: false and stopping animation.")
            
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            DispatchQueue.main.async(execute: { () -> Void in
                self.siteActivityView?.stopAnimating()
                
                
            })
        }
        
        guard let site = site else { return }
        self.updateTitles(site.viewModel.displayName)
        
        if let entries = site.entries {
            for entry in entries {
                if let sgv = entry.sgv {
                    if (sgv.sgv > Double(Constants.EntryCount.LowerLimitForValidSGV)) {
                        self.data.append(entry.jsonForChart as AnyObject)
                    }
                }
            }
        }
        
        DispatchQueue.main.async(execute: { () -> Void in
            let model = site.viewModel
            
            // Configure the Compass
            self.siteCompassControl?.configureWith(model)
            
            // Battery label
            self.siteBatteryHeader?.isHidden = !model.batteryVisible
            self.siteBatteryLabel?.isHidden = !model.batteryVisible
            self.siteBatteryLabel?.text = model.batteryString
            self.siteBatteryLabel?.textColor = UIColor(hexString: model.batteryColor)
            
            // Get date object as string.
            let dateString = Calendar.autoupdatingCurrent.stringRepresentationOfElapsedTimeSinceNow(model.lastReadingDate)
            
            // Last reading label
            self.siteLastReadingLabel?.text = dateString
            self.siteLastReadingLabel?.textColor = UIColor(hexString: model.lastReadingColor)
            
            self.siteRawLabel?.isHidden = !model.rawVisible
            self.siteRawHeader?.isHidden = !model.rawVisible
            
            self.siteRawLabel?.text = model.rawString
            self.siteRawLabel?.textColor = UIColor(hexString: model.rawColor)
            
            //self.updateTitles(model.displayName)
            
            // Reload the webview.
            self.siteWebView?.reload()
        })
        
    }
    
    func loadWebView () {
        self.siteWebView?.delegate = self
        self.siteWebView?.scrollView.bounces = false
        self.siteWebView?.scrollView.isScrollEnabled = false
        
        let filePath = Bundle.main.path(forResource: "index", ofType: "html", inDirectory: "html")
        let defaultDBPath = "\(Bundle.main.resourcePath)\\html"
        
        let fileExists = FileManager.default.fileExists(atPath: filePath!)
        if !fileExists {
            do {
                try FileManager.default.copyItem(atPath: defaultDBPath, toPath: filePath!)
            } catch _ {
            }
        }
        let request = URLRequest(url: URL(fileURLWithPath: filePath!))
        self.siteWebView?.loadRequest(request)
    }
    
    func updateScreenOverride(_ shouldOverride: Bool) {
        guard let site = self.site else {
            return
        }
        UIApplication.shared.isIdleTimerDisabled = shouldOverride
        site.overrideScreenLock = shouldOverride
        AppDataManageriOS.sharedInstance.updateSite(site)
        
        
        #if DEBUG
            print("{site.overrideScreenLock:\(site.overrideScreenLock), UIApplication.idleTimerDisabled:\(UIApplication.shared.isIdleTimerDisabled)}")
        #endif
    }
    
    @IBAction func manageAlarm(_ sender: AnyObject?) {
        AlarmManager.sharedManager.presentSnoozePopup(forViewController: self)
    }
    
    @IBAction func gotoSiteSettings(_ sender: UIBarButtonItem) {
        
        let alertController = UIAlertController(title: Constants.LocalizedString.uiAlertScreenOverrideTitle.localized, message: Constants.LocalizedString.uiAlertScreenOverrideMessage.localized, preferredStyle: .actionSheet)
        
        let cancelAction = UIAlertAction(title: Constants.LocalizedString.generalCancelLabel.localized, style: .cancel) { (action) in
            #if DEBUG
                print("Canceled action: \(action)")
            #endif
        }
        alertController.addAction(cancelAction)
        
        let checkEmoji = "✓ "
        var yesString = "   "
        if site?.overrideScreenLock == true {
            yesString = checkEmoji
        }
        
        let yesAction = UIAlertAction(title: "\(yesString)\(Constants.LocalizedString.generalYesLabel.localized)", style: .default) { (action) -> Void in
            self.updateScreenOverride(true)
            #if DEBUG
                print("Yes action: \(action)")
            #endif
        }
        
        alertController.addAction(yesAction)
        
        alertController.preferredAction = yesAction
        
        var noString = "   "
        if (site!.overrideScreenLock == false) {
            noString = checkEmoji
        }
        
        let noAction = UIAlertAction(title: "\(noString)\(Constants.LocalizedString.generalNoLabel.localized)", style: .destructive) { (action) -> Void in
            self.updateScreenOverride(false)
            #if DEBUG
                print("No action: \(action)")
            #endif
        }
        alertController.addAction(noAction)
        
        alertController.view.tintColor = NSAssetKit.darkNavColor
        
        self.view.window?.tintColor = nil
        
        // Resolving Incident with Identifier: 1169918A-77AC-4D15-8610-E62C1D74E386
        // Crash in UIPopoverPresentationController
        if let popoverController = alertController.popoverPresentationController {
            popoverController.barButtonItem = sender
        }
        
        self.present(alertController, animated: true) {
            #if DEBUG
                print("presentViewController: \(alertController.debugDescription)")
            #endif
        }
    }
}

extension SiteDetailViewController: UpdatableUserInterfaceType {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startUpdateUITimer()
    }
    
    func updateUI(_ notif: Timer) {
        
        print("updating ui for: \(notif)")
        self.updateData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        updateUITimer.invalidate()
    }
}
