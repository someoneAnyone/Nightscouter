//
//  ViewController.swift
//  Nightscout
//
//  Created by Peter Ina on 5/14/15.
//  Copyright (c) 2015 Peter Ina. All rights reserved.
//

import UIKit

class SiteDetailViewController: UIViewController, UIWebViewDelegate {
    
    @IBOutlet weak var viewForWebContent: UIView!
    @IBOutlet weak var compassControl: CompassControl!
    @IBOutlet weak var lastReadingLabel: UILabel!
    @IBOutlet weak var rawReadingLabel: UILabel!
    @IBOutlet weak var uploaderBatteryLabel: UILabel!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var activityView: UIActivityIndicatorView!
    
    var timer: NSTimer = NSTimer()
    
    var site = Site?()
    
    var nsAPI: NightscoutAPIClient?
    var data = [AnyObject]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        navigationController?.hidesBarsOnTap = true
        
        if (site != nil) {
            nsAPI = NightscoutAPIClient(url: (site?.url)!)
            
            lebeoufIt()
            
            self.view.alpha = 0.5
            self.compassControl.color = NSAssetKit.predefinedNeutralColor
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        data.removeAll()
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        //        if UIDevice.currentDevice().orientation.isLandscape.boolValue {
        //            print("isLandscape")
        //        } else {
        //            print("isPortrait")
        //        }
        
        self.webView.reload()
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
}


extension SiteDetailViewController{
    @IBAction func unwindToSiteDetail(segue:UIStoryboardSegue) {
        print("unwundToSiteDetail")
        return
    }
}

// Mark: WebKit WebView Delegates
extension SiteDetailViewController {
    
    func lebeoufIt () { // Just do it!
        updateSettings()
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        print(">>> Entering \(__FUNCTION__) <<<")
        let updateData = "updateData(\(self.data))"
        let updateUnits = "updateUnits(\(self.site!.configuration!.units.rawValue))"
        
        self.webView!.stringByEvaluatingJavaScriptFromString(updateData)
        self.webView!.stringByEvaluatingJavaScriptFromString(updateUnits)
        
        self.activityView.stopAnimating()
        self.webView!.hidden = false
    }
}

extension SiteDetailViewController {
    func updateSettings(){
        nsAPI!.fetchServerConfigurationData({ (configuration: ServerConfiguration) -> Void in
            

            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.navigationItem.title = configuration.customTitle
                
                self.titleLabel.text = configuration.customTitle
                self.compassControl.units = configuration.units.rawValue
                
                self.compassControl.bg_high = CGFloat(configuration.thresholds.bg_high) //CGFloat((settings.thresholds["bg_high"])!)
                self.compassControl.bg_low = CGFloat(configuration.thresholds.bg_low) //CGFloat((settings.thresholds["bg_low"])!)
                self.compassControl.bg_target_bottom = CGFloat(configuration.thresholds.bg_target_bottom) //CGFloat((settings.thresholds["bg_target_bottom"])!)
                self.compassControl.bg_target_top = CGFloat(configuration.thresholds.bg_target_top)//CGFloat((settings.thresholds["bg_target_top"])!)
                
                self.updateData()
                self.createWKWebView()
                self.loadWebView()
                
                self.view.alpha = 1.0
            })
        })
    }
    
    func updateData() {
        print(">>> Entering \(__FUNCTION__) <<<")
        
        timer.invalidate()
        
        nsAPI!.fetchDataForWatchEntry{ (watchEntry) -> Void in
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                self.compassControl.sgv = CGFloat(watchEntry.sgv!.sgv)
                self.compassControl.direction = watchEntry.sgv!.direction
                self.uploaderBatteryLabel.text = "\(watchEntry.battery)"
                let temp = NSCalendar.autoupdatingCurrentCalendar().stringRepresentationOfElapsedTimeSinceNow(watchEntry.date)
                
                let timeAgo = watchEntry.date.timeIntervalSinceNow
                
                self.lastReadingLabel.text = temp
                if let rawValue = watchEntry.raw {
                self.rawReadingLabel.text = "\(NSNumberFormatter.localizedStringFromNumber(rawValue, numberStyle: NSNumberFormatterStyle.DecimalStyle)) : \(watchEntry.sgv!.noise)"
                }
                let numberFormat = NSNumberFormatter.localizedStringFromNumber(watchEntry.bgdelta, numberStyle: .NoStyle)
                
                self.compassControl.delta = "\(numberFormat) \(self.compassControl.units!)"
                self.timer = NSTimer.scheduledTimerWithTimeInterval(240.0, target: self, selector: Selector("updateData"), userInfo: nil, repeats: true)
                
                if timeAgo < -(60*10) {
                    self.compassControl.alpha = 0.5
                    self.compassControl.color = NSAssetKit.predefinedNeutralColor
                }
            })
        }
    }
    
    func createWKWebView (){
        
        self.webView?.delegate = self
        self.webView?.scrollView.bounces = false
        self.webView?.scrollView.scrollEnabled = false
    }
    
    func loadWebView () {
        let filePath = NSBundle.mainBundle().pathForResource("index", ofType: "html", inDirectory: "html")
        let defaultDBPath =  NSBundle.mainBundle().resourcePath?.stringByAppendingPathComponent("html")
        //FIXME:// Need better error handling.
        
        NSFileManager.defaultManager().copyItemAtPath(defaultDBPath!, toPath: filePath!, error: nil)
        
        let request = NSURLRequest(URL: NSURL.fileURLWithPath(filePath!)!)
        
        nsAPI!.fetchDataForEntries(count: 100) { (entries) -> Void in
            for entry in entries {
                if (entry.sgv?.sgv > 25) {
                    let jsonError: NSError?
                    let jsObj =  NSJSONSerialization.dataWithJSONObject(entry.dictionaryRep, options:nil, error:nil)
                    let str = NSString(data: jsObj!, encoding: NSUTF8StringEncoding)
                    self.data.append(str!)
                }
            }
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.webView!.loadRequest(request)
            })
        }
   
    }
    
    @IBAction func gotoLabs(sender: UITapGestureRecognizer) {
        let storyBoard = UIStoryboard(name: UIStoryboard.StoryboardName.Labs.rawValue, bundle: NSBundle.mainBundle())
        NSUserDefaults.standardUserDefaults().setURL(site!.url, forKey: "url")
        presentViewController(storyBoard.instantiateInitialViewController() as! UIViewController, animated: true) { () -> Void in
            println("labs!")
        }
    }

}