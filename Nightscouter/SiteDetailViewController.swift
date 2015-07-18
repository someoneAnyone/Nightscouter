//
//  ViewController.swift
//  Nightscout
//
//  Created by Peter Ina on 5/14/15.
//  Copyright (c) 2015 Peter Ina. All rights reserved.
//

import UIKit

class SiteDetailViewController: UIViewController, UIWebViewDelegate {
    
    @IBOutlet weak var compassControl: CompassControl?
    @IBOutlet weak var lastReadingLabel: UILabel?
    @IBOutlet weak var rawReadingLabel: UILabel?
    @IBOutlet weak var uploaderBatteryLabel: UILabel?
    
    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var webView: UIWebView?
    @IBOutlet weak var activityView: UIActivityIndicatorView?
    
    var site: Site? {
        didSet {
            if (site != nil){
                lebeoufIt()
            }
        }
    }
    
    var nsApi: NightscoutAPIClient?
    var data = [AnyObject]()
    
    override func viewDidLoad() {
        
        println("viewDidLoad")
        
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        // navigationController?.hidesBarsOnTap = true
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateSite:", name: Constants.Notification.DataIsStaleUpdateNow, object: nil)
        
        lebeoufIt()
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
        print(">>> Entering \(__FUNCTION__) <<<")
        print("\(segue)")
    }
}

// Mark: WebKit WebView Delegates
extension SiteDetailViewController {
    func webViewDidFinishLoad(webView: UIWebView) {
        print(">>> Entering \(__FUNCTION__) <<<")
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
    
    func lebeoufIt () { // Just do it!
        self.compassControl?.color = NSAssetKit.predefinedNeutralColor
        self.loadWebView()

        if let siteOptional = site {
            nsApi = NightscoutAPIClient(url:siteOptional.url)
            updateSite(nil)
        }
    }

    func updateSite(notification: NSNotification?) {
        nsApi!.fetchServerConfiguration { (result) -> Void in
            switch (result) {
            case let .Error(error):
                // display error message
                println("error: \(error)")
                
            case let .Value(boxedConfiguration):
                let configuration:ServerConfiguration = boxedConfiguration.value
                // Get back on the main queue to update the user interface
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    if let defaults = configuration.defaults {
                        self.navigationItem.title = defaults.customTitle
                        self.titleLabel?.text = defaults.customTitle
                        self.updateData()
                        self.view.setNeedsDisplay()
                    }
                    
                })
            }
        }
    }
    
    func updateData() {
        print(">>> Entering \(__FUNCTION__) <<<")
        self.activityView?.startAnimating()

        if let site = self.site {
            nsApi!.fetchDataForWatchEntry{ (watchEntry, errorCode) -> Void in
                if let watchEntry = watchEntry {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        
                        self.compassControl?.configureWith(site)
                        self.uploaderBatteryLabel?.text = watchEntry.batteryString
                        self.lastReadingLabel?.text = watchEntry.dateTimeAgoString
                        
                        if let rawValue = watchEntry.raw {
                            self.rawReadingLabel?.text = "\(NSNumberFormatter.localizedStringFromNumber(rawValue, numberStyle: NSNumberFormatterStyle.DecimalStyle)) : \(watchEntry.sgv!.noise)"
                        }
                        
                        let timeAgo = watchEntry.date.timeIntervalSinceNow
                        if timeAgo < -Constants.NotableTime.StaleDataTimeFrame {
                            self.compassControl?.alpha = 0.5
                            self.compassControl?.color = NSAssetKit.predefinedNeutralColor
                            self.compassControl?.sgvText = "---"
                            self.compassControl?.delta = "--"
                            self.uploaderBatteryLabel?.text = "---"
                            self.rawReadingLabel?.text = "--- : ---"
                            self.compassControl?.direction = .None
                        }
                        
                        self.nsApi!.fetchDataForEntries(count: Constants.EntryCount.NumberForChart) { (entries, errorCode) -> Void in
                            if let entries = entries {
                                for entry in entries {
                                    if (entry.sgv?.sgv > Constants.EntryCount.LowerLimitForValidSGV) {
                                        let jsonError: NSError?
                                        let jsObj =  NSJSONSerialization.dataWithJSONObject(entry.dictionaryRep, options:nil, error:nil)
                                        let str = NSString(data: jsObj!, encoding: NSUTF8StringEncoding)
                                        self.data.append(str!)
                                    }
                                }
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                    self.activityView?.stopAnimating()
                                    self.webView?.reload()
                                })
                            }
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
        
        NSFileManager.defaultManager().copyItemAtPath(defaultDBPath!, toPath: filePath!, error: nil)
        let request = NSURLRequest(URL: NSURL.fileURLWithPath(filePath!)!)
        self.webView?.loadRequest(request)
    }
    
    @IBAction func gotoLabs(sender: UITapGestureRecognizer) {
        let storyboard = UIStoryboard(name: UIStoryboard.StoryboardName.Labs.rawValue, bundle: NSBundle.mainBundle())
        NSUserDefaults.standardUserDefaults().setURL(site!.url, forKey: "url")
        presentViewController(storyboard.instantiateInitialViewController() as! UIViewController, animated: true) { () -> Void in
            println("labs!")
        }
    }
}