//
//  ServerConfigurationViewController.swift
//  Nightscouter
//
//  Created by Peter Ina on 7/13/15.
//  Copyright (c) 2015 Peter Ina. All rights reserved.
//

import UIKit

class TestHarnessServerConfigurationViewController: UIViewController {

    @IBOutlet var configurationLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        let url: NSURL = NSUserDefaults.standardUserDefaults().URLForKey("url")!// NSURL(string:  ")!
        let nsAPI = NightscoutAPIClient(url:url)
        nsAPI.fetchServerConfigurationData { (configuration, errorCode) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.configurationLabel.text = "\(configuration)"
            })
        }
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
