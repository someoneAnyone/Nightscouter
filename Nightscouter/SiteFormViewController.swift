//
//  SiteViewController.swift
//  Nightscouter
//
//  Created by Peter Ina on 6/13/15.
//  Copyright © 2015 Peter Ina. All rights reserved.
//

import UIKit

class SiteFormViewController: UIViewController, UITextFieldDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var formLabel: UILabel!
    @IBOutlet weak var formDescription: UILabel!
    @IBOutlet weak var urlTextField: UITextField!
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var middleLayoutContraint: NSLayoutConstraint!
    
    /*
    This value is either passed by `SiteListTableViewController` in `prepareForSegue(_:sender:)`
    or constructed as part of adding a new site.
    */
    var site = Site?()
    
    var currentOrientation: UIDeviceOrientation?
    var validatedUrlString: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Add notification observer for text field updates
        urlTextField.addTarget(self, action: "textFieldDidUpdate:", forControlEvents: UIControlEvents.EditingChanged)
        
        urlTextField.delegate = self
        
        // Set up views if editing an existing Meal.
        if let site = site {
            navigationItem.title = site.url.host
            urlTextField.text   = site.url.absoluteString
            
            checkValidSiteName()
        }
        
        // Or you can do it the old way
        let offset = 2.0
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(offset * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), {
            // Do something
            self.urlTextField.becomeFirstResponder()
        })
        
        nextButton.tintColor = NSAssetKit.darkNavColor
        
        observeKeyboard()
        
        AppDataManager.sharedInstance.shouldDisableIdleTimer = false
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        currentOrientation = UIDevice.currentDevice().orientation
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self);
    }
    
    func textFieldDidUpdate(textField: UITextField)
    {
        checkValidSiteName()
    }
    
    func checkValidSiteName() {
        // Remove Spaces
        urlTextField.text = urlTextField.text.stringByReplacingOccurrencesOfString(" ", withString: "", options: nil, range: nil)

        // Or you can do it the old way
        let offset = 0.5
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(offset * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), {
            // Validate URL
            NSURL.validateUrl(self.urlTextField.text, completion: { (success, urlString, error) -> Void in
                println("validateURL Error: \(error)")
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    if (success)
                    {
                        NSURL.ValidationQueue.queue.cancelAllOperations()
                        self.validatedUrlString = urlString!
                    }
                    else
                    {
                        self.validatedUrlString = nil
                    }
                    self.nextButton.enabled = success
                })
            })
        })

    }
    
    // MARK: UITextFieldDelegate
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        // Hide the keyboard
        textField.resignFirstResponder()
        
        if nextButton.enabled{
            self.view.endEditing(true)
            performSegueWithIdentifier(UIStoryboardSegue.SegueIdentifier.UnwindToSiteList.rawValue, sender: nextButton)
        }
        
        return true // validateUrl(textField.text!)
    }
    
    // MARK: Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if nextButton === sender {
            // Set the site to be passed to SiteListTableViewController after the unwind segue.
            //            let urlString = urlTextField.text ?? ""
            let urlString = validatedUrlString ?? ""
            
            if let url = NSURL(string: urlString) {
                
                if let siteOptional = site {
                    siteOptional.url = url
                    site = siteOptional
                } else {
                    site = Site(url: url, apiSecret: nil)
                }
                // Hide the keyboard
                urlTextField.resignFirstResponder()
            }
        }
    }
    
    // MARK: Actions
    @IBAction func cancel(sender: UIBarButtonItem) {
        // Depending on style of presentation (modal or push presentation), this view controller needs to be dismissed in two different ways.
        let isPresentingInAddMealMode = presentingViewController is UINavigationController
        
        urlTextField.resignFirstResponder()
        if isPresentingInAddMealMode {
            dismissViewControllerAnimated(true, completion: nil)
        }
        else {
            navigationController!.popViewControllerAnimated(true)
        }
    }
    
    /*
    func validateUrl (stringURL : NSString) -> Bool {
        let urlRegEx = "(http|https)://((\\w)*|([0-9]*)|([-|_])*)+([\\.|/]((\\w)*|([0-9]*)|([-|_])*))+"
        let predicate = NSPredicate(format:"SELF MATCHES %@", argumentArray:[urlRegEx])
        //        var urlTest = NSPredicate.predicateWithSubstitutionVariables(predicate)
        return predicate.evaluateWithObject(stringURL)
    }
    */
    
    // MARK: Keyboard Notifications
    
    func observeKeyboard() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow:"), name:UIKeyboardWillShowNotification, object: nil);
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillHide:"), name:UIKeyboardWillHideNotification, object: nil);
    }
    
    func keyboardWillShow(notification: NSNotification) {
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        let animationDuration: NSTimeInterval = (info[UIKeyboardAnimationDurationUserInfoKey])!.doubleValue
        
        let orientation = UIDevice.currentDevice().orientation
        let isPortrait = UIDeviceOrientationIsPortrait(orientation)
        let height = isPortrait ? keyboardFrame.size.height : keyboardFrame.size.width
        
        self.middleLayoutContraint.constant = -(height * 0.1)
        
        if (self.currentOrientation != orientation) {
            self.view.layoutIfNeeded()
        }
        
        UIView.animateWithDuration(animationDuration, animations: { () -> Void in
            self.view.layoutIfNeeded()
        })
    }
    
    func keyboardWillHide(notification: NSNotification) {
        
        let info = notification.userInfo!
        // let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        let animationDuration: NSTimeInterval = (info[UIKeyboardAnimationDurationUserInfoKey])!.doubleValue
        
        self.middleLayoutContraint.constant = 0
        UIView.animateWithDuration(animationDuration, animations: { () -> Void in
            self.view.layoutIfNeeded()
        })
    }
}

