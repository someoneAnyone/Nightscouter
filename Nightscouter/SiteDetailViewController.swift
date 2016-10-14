//
//  ViewController.swift
//  Nightscout
//
//  Created by Peter Ina on 5/14/15.
//  Copyright (c) 2015 Peter Ina. All rights reserved.
//

import UIKit
import NightscouterKit

class SiteDetailViewController: UIViewController, UIWebViewDelegate, AlarmStuff {
    
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
            guard let site = site else {
                return
            }
            configureView(withSite: site)
        }
    }
    
    var data = [AnyObject]() {
        didSet {
            loadWebView()
        }
    }
    
    var timer: Timer?
    
    // MARK: View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // remove any uneeded decorations from this view if contained within a UI page view controller
        if let _ = parent as? UIPageViewController {
            // println("contained in UIPageViewController")
            self.view.backgroundColor = UIColor.clear
            self.siteNameLabel?.removeFromSuperview()
        }
        
        configureView()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        self.siteWebView?.reload()
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        UIApplication.shared.isIdleTimerDisabled = false
    }
}

// MARK: WebKit WebView Delegates
extension SiteDetailViewController {
    func webViewDidFinishLoad(_ webView: UIWebView) {
        print(">>> Entering \(#function) <<<")
        let updateData = "updateData(\(self.data))"
        if let configuration = site?.configuration {
            let updateUnits = "updateUnits(\(configuration.displayUnits.hashValue))"
            webView.stringByEvaluatingJavaScript(from: updateUnits)
        }
        webView.stringByEvaluatingJavaScript(from: updateData)
        webView.isHidden = false
        siteActivityView?.stopAnimating()
    }
}

extension SiteDetailViewController {
    
    func configureView() {
        
        headerView?.isHidden = true
        
        self.siteCompassControl?.color = NSAssetKit.predefinedNeutralColor
        
        if let siteOptional = site {
            UIApplication.shared.isIdleTimerDisabled = siteOptional.overrideScreenLock
        } else {
            site = SitesDataSource.sharedInstance.sites[SitesDataSource.sharedInstance.lastViewedSiteIndex]
        }
        
        
        if #available(iOS 10.0, *) {
            self.timer = Timer.scheduledTimer(withTimeInterval: TimeInterval.OneMinute, repeats: true, block: { (timer) in
                DispatchQueue.main.async {
                    self.updateUI()
                }
            })
        } else {
            self.timer = Timer.scheduledTimer(timeInterval: TimeInterval.OneMinute, target: self, selector: #selector(SiteListTableViewController.updateUI), userInfo: nil, repeats: true)
        }
        
        setupNotifications()

        updateData()
    }
    
    func setupNotifications() {
        // Listen for global update timer.
        NotificationCenter.default.addObserver(self, selector: #selector(updateSite(_:)), name: .NightscoutDataStaleNotification, object: nil)
        
        NotificationCenter.default.addObserver(forName: .NightscoutAlarmNotification, object: nil, queue: .main) { (notif) in
            if (notif.object as? AlarmObject) != nil {
                self.updateUI()
            }
        }
        //NotificationCenter.default.addObserver(self, selector: #selector(SiteListTableViewController.updateData), name: .NightscoutDataUpdatedNotification, object: nil)
    }
    
    
    func updateSite(_ notification: Notification?) {
        print(">>> Entering \(#function) <<<")
        self.updateData()
    }
    
    func updateData() {
        guard let site = self.site else { return }
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        self.siteActivityView?.startAnimating()
        site.fetchDataFromNetwork() { (updatedSite, err) in
            if let _ = err {
                DispatchQueue.main.async {
                    // self.presentAlertDialog(site.url, index: index, error: error.kind.description)
                }
                return
            }
            
            SitesDataSource.sharedInstance.updateSite(updatedSite)
            self.site = updatedSite
            
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                self.siteActivityView?.stopAnimating()
                self.updateUI()
            }
        }
    }
    
    func updateUI() {
        guard let site = site else {
            return
        }
        configureView(withSite: site)
    }
    
    @IBAction func unwindToSiteDetail(_ segue:UIStoryboardSegue) {
        // print(">>> Entering \(#function) <<<")
        // print("\(segue)")
    }
    
    @IBAction func manageAlarm(_ sender: AnyObject?) {
        presentSnoozePopup(forViewController: self)
    }
    
    @IBAction func gotoSiteSettings(_ sender: UIBarButtonItem) {
        
        let alertController = UIAlertController(title: LocalizedString.uiAlertScreenOverrideTitle.localized, message: LocalizedString.uiAlertScreenOverrideMessage.localized, preferredStyle: .actionSheet)
        
        let cancelAction = UIAlertAction(title: LocalizedString.generalCancelLabel.localized, style: .cancel) { (action) in
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
        
        let yesAction = UIAlertAction(title: "\(yesString)\(LocalizedString.generalYesLabel.localized)", style: .default) { (action) -> Void in
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
        
        let noAction = UIAlertAction(title: "\(noString)\(LocalizedString.generalNoLabel.localized)", style: .destructive) { (action) -> Void in
            self.updateScreenOverride(false)
            #if DEBUG
                print("No action: \(action)")
            #endif
        }
        alertController.addAction(noAction)
        
        alertController.view.tintColor = NSAssetKit.darkNavColor
        
        self.view.window?.tintColor = nil
        
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

extension SiteDetailViewController {
    
    func configureView(withSite site: Site) {
        
        UIApplication.shared.isIdleTimerDisabled = site.overrideScreenLock
        
        let dataSource = site.summaryViewModel
        
        siteLastReadingLabel?.text = dataSource.lastReadingDate.timeAgoSinceNow
        siteLastReadingLabel?.textColor = dataSource.lastReadingColor
        
        siteBatteryHeader?.isHidden = dataSource.batteryHidden
        siteBatteryLabel?.isHidden = dataSource.batteryHidden
        siteBatteryLabel?.text = dataSource.batteryLabel
        siteBatteryLabel?.textColor = dataSource.batteryColor
        
        siteRawLabel?.isHidden = dataSource.rawHidden
        siteRawHeader?.isHidden = dataSource.rawHidden
        
        siteRawLabel?.text = dataSource.rawFormatedLabel
        siteRawLabel?.textColor = dataSource.rawColor
        
        siteNameLabel?.text = dataSource.nameLabel
        siteCompassControl?.configure(withDataSource: dataSource, delegate: dataSource)
        
        self.updateTitles(dataSource.nameLabel)
        
        data = site.sgvs.map{ $0.jsonForChart as AnyObject }
        
        snoozeAlarmButton.isEnabled = false
        if let alarmObject = alarmObject {
            
            if alarmObject.warning == true || alarmObject.isSnoozed {
                let activeColor = alarmObject.urgent ? NSAssetKit.predefinedAlertColor : NSAssetKit.predefinedWarningColor
                
                self.snoozeAlarmButton.isEnabled = true
                self.snoozeAlarmButton.tintColor = activeColor
                if alarmObject.isSnoozed {
                    self.snoozeAlarmButton.image = #imageLiteral(resourceName: "alarmSliencedIcon")
                }
                
                if let headerView = self.headerView {
                    headerView.isHidden = false
                    headerView.tintColor = activeColor
                    headerView.message = AlarmRule.isSnoozed ? alarmObject.snoozeText : LocalizedString.generalAlarmMessage.localized
                }
                
            } else if alarmObject.warning == false && !alarmObject.isSnoozed {
                self.snoozeAlarmButton.isEnabled = false
                self.snoozeAlarmButton.tintColor = nil
                
            } else {
                self.snoozeAlarmButton.image = #imageLiteral(resourceName: "alarmIcon")
            }
        }
        
        self.siteWebView?.reload()
    }
    
    func updateTitles(_ title: String) {
        self.navigationItem.title = title
        self.navigationController?.navigationItem.title = title
        self.siteNameLabel?.text = title
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
        self.site?.overrideScreenLock = shouldOverride
        SitesDataSource.sharedInstance.updateSite(self.site!)
        UIApplication.shared.isIdleTimerDisabled = site?.overrideScreenLock ?? false
    }
}
