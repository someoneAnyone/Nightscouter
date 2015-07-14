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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        urlTextField.delegate = self
        
        // Set up views if editing an existing Meal.
        if let site = site {
            navigationItem.title = site.url.host
            urlTextField.text   = site.url.absoluteString
        }
        
        // Or you can do it the old way
        let offset = 2.0
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(offset * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), {
            // Do something
            self.urlTextField.becomeFirstResponder()
        })
        checkValidSiteName()
        
        observeKeyboard()
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
    
    // MARK: UITextFieldDelegate
    func textFieldShouldReturn(textField: UITextField) -> Bool {

        // Hide the keyboard
        textField.resignFirstResponder()
        
        return true // validateUrl(textField.text!)
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        // Disable the Save button while editing.
        checkValidSiteName()
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        checkValidSiteName()
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        
        checkValidSiteName()
        return true
    }
    
    func checkValidSiteName() {
        // Disable the Save button if the text field is empty.
        let text = urlTextField.text ?? ""
        let valid = validateUrl(text)
        
        nextButton.enabled = valid
        //        print("Evaluating text \(text), which is currently \(valid).")
        if valid {
//            navigationItem.title = NSURL(string: text)?.host
        }
    }
    
    // MARK: Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if nextButton === sender {
            // Set the site to be passed to SiteListTableViewController after the unwind segue.
            let urlString = urlTextField.text ?? ""
            
            if let url = NSURL(string: urlString) {
                site = Site(url: url, apiSecret: "")
                
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
    
    func validateUrl (stringURL : NSString) -> Bool {
        let urlRegEx = "(http|https)://((\\w)*|([0-9]*)|([-|_])*)+([\\.|/]((\\w)*|([0-9]*)|([-|_])*))+"
        let predicate = NSPredicate(format:"SELF MATCHES %@", argumentArray:[urlRegEx])
        //        var urlTest = NSPredicate.predicateWithSubstitutionVariables(predicate)
        return predicate.evaluateWithObject(stringURL)
    }
    
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

        print("The keyboard height is: \(height)")
        
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
//        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        let animationDuration: NSTimeInterval = (info[UIKeyboardAnimationDurationUserInfoKey])!.doubleValue
        
        self.middleLayoutContraint.constant = 0
        UIView.animateWithDuration(animationDuration, animations: { () -> Void in
            self.view.layoutIfNeeded()
        })

    
    }
    

}

