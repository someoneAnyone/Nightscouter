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
    
    @IBOutlet fileprivate weak var snoozeAlarmButton: UIBarButtonItem!
    @IBOutlet fileprivate weak var headerView: BannerMessage?
    
    // MARK: Properties
    var site: Site? {
        didSet {
            guard let site = site else { return }
            self.configureView(withSite: site)
        }
    }

    var data: [String] = [] {
        didSet{
            loadWebView()
        }
    }
    
    // MARK: View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // remove any uneeded decorations from this view if contained within a UI page view controller
        if let _ = parent as? UIPageViewController {
            // println("contained in UIPageViewController")
            self.view.backgroundColor = UIColor.clear
            self.siteNameLabel?.removeFromSuperview()
        }
        
        configureView(withSite: site ?? Site())
    }
   
    deinit {
        NotificationCenter.default.removeObserver(self)
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        data.removeAll()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        self.siteWebView?.reload()
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
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
        siteActivityView?.stopAnimating()
    }
}

extension SiteDetailViewController {
    
    func configureView() {
        self.siteCompassControl?.color = NSAssetKit.predefinedNeutralColor
        self.loadWebView()


        NotificationCenter.default.addObserver(self, selector: #selector(updateSite(_:)), name: .NightscoutDataStaleNotification, object: nil)
        if let siteOptional = site {
            // nsApi = NightscoutAPIClient(url:siteOptional.url)
            UIApplication.shared.isIdleTimerDisabled = siteOptional.overrideScreenLock
            
        } else {
            site = SitesDataSource.sharedInstance.sites[SitesDataSource.sharedInstance.lastViewedSiteIndex]
        }
        
        updateData()
    }
    
    func updateSite(_ notification: Notification?) {
        print(">>> Entering \(#function) <<<")
        self.updateData()
    }
 
    
    func updateData(forceUpdate force: Bool = false) {
        guard let site = self.site else { return }
        
        if (site.updateNow || site.sgvs.isEmpty || site.configuration == nil || force == true) {
            
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            self.siteActivityView?.startAnimating()
            
//            fetchSiteData(site, handler: { (returnedSite, error) -> Void in
//                SitesDataSource.sharedInstance.updateSite(returnedSite)
//                self.updateUI()
//            })
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
        self.updateTitles(site.summaryViewModel.nameLabel)
        
        data = site.sgvs.map{ $0.jsonForChart }

        
        DispatchQueue.main.async(execute: { () -> Void in
            let model = site.summaryViewModel
            
            // Configure the Compass
//            self.siteCompassControl?.configureWith(model)
            
            // Battery label
            self.siteBatteryHeader?.isHidden = model.batteryHidden
            self.siteBatteryLabel?.isHidden =  model.batteryHidden
            self.siteBatteryLabel?.text = model.batteryLabel
            self.siteBatteryLabel?.textColor = model.batteryColor
            
            // Get date object as string.
            let dateString = Calendar.autoupdatingCurrent.stringRepresentationOfElapsedTimeSinceNow(model.lastReadingDate)
            
            // Last reading label
            self.siteLastReadingLabel?.text = dateString
            self.siteLastReadingLabel?.textColor = model.lastReadingColor
            
            self.siteRawLabel?.isHidden = model.rawHidden
            self.siteRawHeader?.isHidden = model.rawHidden
            
            self.siteRawLabel?.text = model.rawLabel
            self.siteRawLabel?.textColor = model.rawColor
            
            //self.updateTitles(model.displayName)
            
            // Reload the webview.
            self.siteWebView?.reload()
        })
        
    }
   
    @IBAction func manageAlarm(_ sender: AnyObject?) {
//        AlarmManager.sharedManager.presentSnoozePopup(forViewController: self)
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
            
            data = site.sgvs.map{ $0.jsonForChart }
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
            
            #if DEBUG
//                print("{site.overrideScreenLock:\(site?.overrideScreenLock), AppDataManageriOS.shouldDisableIdleTimer:\(Sites.sharedInstance.shouldDisableIdleTimer), UIApplication.idleTimerDisabled:\(UIApplication.sharedApplication().idleTimerDisabled)}")
            #endif
        }
        
//        func presentSettings(_ sender: UIBarButtonItem) {
//            
//            guard let alertController = self.storyboard?.instantiateViewController(withIdentifier: StoryboardIdentifier.siteSettingsNavigationViewController.rawValue) as? UINavigationController else {
//                return
//            }
//            
//            if let vc = alertController.viewControllers.first as? SiteSettingsTableViewController {
//                vc.delegate = self
//            }
//            
//            if let popoverController = alertController.popoverPresentationController {
//                popoverController.barButtonItem = sender
//            }
//            
//            self.presentViewController(alertController, animated: true) {
//                #if DEBUG
//                    print("presentViewController: \(alertController.debugDescription)")
//                #endif
//            }
//        
//    }

}

/*
extension SiteDetailViewController: UpdatableUserInterfaceType {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startUpdateUITimer()
    }
    @objc
    func updateUI(_ notif: Timer) {
        
        print("updating ui for: \(notif)")
        self.updateData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        updateUITimer.invalidate()
    }
}
*/
