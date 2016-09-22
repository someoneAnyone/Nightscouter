//
//  SiteViewController.swift
//  Nightscouter
//
//  Created by Peter Ina on 6/13/15.
//  Copyright © 2015 Peter Ina. All rights reserved.
//

import UIKit
import NightscouterKit

class SiteFormViewController: UIViewController, UITextFieldDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var formLabel: UILabel!
    @IBOutlet weak var formDescription: UILabel!
    @IBOutlet weak var urlTextField: UITextField!
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var middleLayoutContraint: NSLayoutConstraint!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    /*
     This value is either passed by `SiteListTableViewController` in `prepareForSegue(_:sender:)`
     or constructed as part of adding a new site.
     */
    var site: Site?
    
    var currentOrientation: UIDeviceOrientation?
    var validatedUrlString: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        formLabel.text = LocalizedString.nightscoutTitleString.localized
        formDescription.text = LocalizedString.newSiteFormLabel.localized
        nextButton.setTitle(LocalizedString.generalNextLabel.localized, for: .normal)
        cancelButton.title = LocalizedString.generalCancelLabel.localized
        urlTextField.placeholder = LocalizedString.genericURLLabel.localized
        
        // Add notification observer for text field updates
        urlTextField.addTarget(self, action: #selector(SiteFormViewController.textFieldDidUpdate(_:)), for: UIControlEvents.editingChanged)
        
        urlTextField.delegate = self
        
        // Set up views if editing an existing Meal.
        if let site = site {
            navigationItem.title = site.url.host
            urlTextField.text   = site.url.absoluteString
            
            checkValidSiteName()
        }
        
        nextButton.isEnabled = (site != nil)
        
        // Or you can do it the old way
        let offset = 2.0
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(offset * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: {
            // Do something
            self.urlTextField.becomeFirstResponder()
        })
        
        nextButton.tintColor = NSAssetKit.darkNavColor
        
        observeKeyboard()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        currentOrientation = UIDevice.current.orientation
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self);
    }
    
    func textFieldDidUpdate(_ textField: UITextField)
    {
        checkValidSiteName()
    }
    
    func checkValidSiteName() {
        // Remove Spaces
        urlTextField.text = urlTextField.text!.replacingOccurrences(of: " ", with: "", options: [], range: nil)
        

        let offset = 1.0
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(offset * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: {
            self.activityIndicator.startAnimating()

            // Validate URL
            URL.validateUrl(self.urlTextField.text, completion: { (success, urlString, error) -> Void in
                print("validateURL Error: \(error)")
                DispatchQueue.main.async(execute: { () -> Void in
                    
                    if (success)
                    {
                        URL.ValidationQueue.queue.cancelAllOperations()
                        self.validatedUrlString = urlString!
                    }
                    else
                    {
                        self.validatedUrlString = nil
                    }
                    self.nextButton.isEnabled = success
                    self.activityIndicator.stopAnimating()
                })
            })
        })
        
    }
    
    // MARK: UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if self.nextButton.isEnabled {
            // Hide the keyboard
            textField.resignFirstResponder()
            self.view.endEditing(true)
            performSegue(withIdentifier: SiteListTableViewController.SegueIdentifier.unwindToSiteList.rawValue, sender: nextButton)
        }
        
        return self.nextButton.isEnabled // validateUrl(textField.text!)
    }
    
    // MARK: Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if nextButton === sender as! UIButton {
            // Set the site to be passed to SiteListTableViewController after the unwind segue.
            let urlString = validatedUrlString ?? ""
            
            if let url = URL(string: urlString) {
                
                if var siteOptional = site {
                    siteOptional.url = url
                    site = siteOptional
                } else {
                    site = Site(url: url, apiSecret: "")
                }
                // Hide the keyboard
                urlTextField.resignFirstResponder()
            }
        }
    }
    
    // MARK: Actions
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        // Depending on style of presentation (modal or push presentation), this view controller needs to be dismissed in two different ways.
        let isPresentingInAddMealMode = presentingViewController is UINavigationController
        
        urlTextField.resignFirstResponder()
        if isPresentingInAddMealMode {
            dismiss(animated: true, completion: nil)
        }
        else {
            navigationController!.popViewController(animated: true)
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
        NotificationCenter.default.addObserver(self, selector: #selector(SiteFormViewController.keyboardWillShow(_:)), name:NSNotification.Name.UIKeyboardWillShow, object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(SiteFormViewController.keyboardWillHide(_:)), name:NSNotification.Name.UIKeyboardWillHide, object: nil);
    }
    
    func keyboardWillShow(_ notification: Notification) {
        let info = (notification as NSNotification).userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let animationDuration: TimeInterval = ((info[UIKeyboardAnimationDurationUserInfoKey])! as AnyObject).doubleValue
        
        let orientation = UIDevice.current.orientation
        let isPortrait = UIDeviceOrientationIsPortrait(orientation)
        let height = isPortrait ? keyboardFrame.size.height : keyboardFrame.size.width
        
        self.middleLayoutContraint.constant = -(height * 0.1)
        
        if (self.currentOrientation != orientation) {
            self.view.layoutIfNeeded()
        }
        
        UIView.animate(withDuration: animationDuration, animations: { () -> Void in
            self.view.layoutIfNeeded()
        })
    }
    
    func keyboardWillHide(_ notification: Notification) {
        
        let info = (notification as NSNotification).userInfo!
        // let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        let animationDuration: TimeInterval = ((info[UIKeyboardAnimationDurationUserInfoKey])! as AnyObject).doubleValue
        
        self.middleLayoutContraint.constant = 0
        UIView.animate(withDuration: animationDuration, animations: { () -> Void in
            self.view.layoutIfNeeded()
        })
    }
}

