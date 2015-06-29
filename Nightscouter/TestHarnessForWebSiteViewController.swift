//
//  TestHarnessForWebSiteViewController.swift
//  Nightscout
//
//  Created by Peter Ina on 6/3/15.
//  Copyright (c) 2015 Peter Ina. All rights reserved.
//

import UIKit

class TestHarnessForWebSiteViewController: UIViewController {

    @IBOutlet weak var webView: UIWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let url: NSURL = NSUserDefaults.standardUserDefaults().URLForKey("url")!// NSURL(string:  ")!
        self.webView.loadRequest(NSURLRequest(URL: url))


        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
