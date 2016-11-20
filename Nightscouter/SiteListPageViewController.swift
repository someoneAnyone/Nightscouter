//
//  RootViewController.swift
//  TestPageBase
//
//  Created by Peter Ina on 6/22/15.
//  Copyright © 2015 Peter Ina. All rights reserved.
//

import UIKit
import NightscouterKit

class SiteListPageViewController: UIViewController, UIPageViewControllerDelegate {
    
    var pageViewController: UIPageViewController?
    
    var sites: [Site] {
        return SitesDataSource.sharedInstance.sites
    }
    
    var currentIndex: Int {
        set {
            SitesDataSource.sharedInstance.lastViewedSiteIndex = currentIndex
        }
        get {
            return SitesDataSource.sharedInstance.lastViewedSiteIndex
        }
    }
    
    @IBOutlet weak var goToListButton: UIButton!
    @IBOutlet weak var pageControl: UIPageControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        // Configure the page view controller and add it as a child view controller.
        pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        pageViewController!.delegate = self
        
        let startingViewController: SiteDetailViewController = self.modelController.viewControllerAtIndex(currentIndex, storyboard: self.storyboard!)!
        let viewControllers = [startingViewController]
        pageViewController!.setViewControllers(viewControllers, direction: .forward, animated: false, completion: {done in })
        pageViewController!.dataSource = self.modelController
        
        addChildViewController(self.pageViewController!)
        view.addSubview(self.pageViewController!.view)
        
        // Set the page view controller's bounds using an inset rect so that self's view is visible around the edges of the pages.
        var pageViewRect = self.view.bounds
        if UIDevice.current.userInterfaceIdiom == .pad {
            pageViewRect = pageViewRect.insetBy(dx: 40.0, dy: 40.0)
        }
        
        pageViewController!.view.frame = pageViewRect
        pageViewController!.didMove(toParentViewController: self)
        
        // Add the page view controller's gesture recognizers to the book view controller's view so that the gestures are started more easily.
        view.gestureRecognizers = pageViewController!.gestureRecognizers
        
        // view.bringSubviewToFront(self.goToListButton)
        goToListButton.isHidden = true
        
        setupNotifications()
        updateNavigationController()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        // Remove this class from the observer list. Was listening for a global update timer.
        NotificationCenter.default.removeObserver(self)
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    var modelController: ModelController {
        // Return the model controller object, creating it if necessary.
        // In more complex implementations, the model controller may be passed to the view controller.
        if _modelController == nil {
            _modelController = ModelController(sites: sites,currentIndex: currentIndex)
        }
        return _modelController!
    }
    
    var _modelController: ModelController? = nil
    
    // MARK: - UIPageViewController delegate methods
    
    func pageViewController(_ pageViewController: UIPageViewController, spineLocationFor orientation: UIInterfaceOrientation) -> UIPageViewControllerSpineLocation {
        if (orientation == .portrait) || (orientation == .portraitUpsideDown) || (UIDevice.current.userInterfaceIdiom == .phone) {
            // In portrait orientation or on iPhone: Set the spine position to "min" and the page view controller's view controllers array to contain just one view controller. Setting the spine position to 'UIPageViewControllerSpineLocationMid' in landscape orientation sets the doubleSided property to YES, so set it to NO here.
            let currentViewController: UIViewController = self.pageViewController!.viewControllers![0]
            let viewControllers: [UIViewController] = [currentViewController]
            self.pageViewController!.setViewControllers(viewControllers, direction: .forward, animated: true, completion: {done in })
            self.pageViewController!.isDoubleSided = false
            return .min
        }
        
        // In landscape orientation: Set set the spine location to "mid" and the page view controller's view controllers array to contain two view controllers. If the current page is even, set it to contain the current and next view controllers; if it is odd, set the array to contain the previous and current view controllers.
        let currentViewController = self.pageViewController!.viewControllers![0] as! SiteDetailViewController
        var viewControllers: [UIViewController]
        
        let indexOfCurrentViewController = self.modelController.indexOfViewController(currentViewController)
        if (indexOfCurrentViewController == 0) || (indexOfCurrentViewController % 2 == 0) {
            let nextViewController = self.modelController.pageViewController(self.pageViewController!, viewControllerAfter: currentViewController)
            viewControllers = [currentViewController, nextViewController!]
        } else {
            let previousViewController = self.modelController.pageViewController(self.pageViewController!, viewControllerBefore: currentViewController)
            viewControllers = [previousViewController!, currentViewController]
        }
        self.pageViewController!.setViewControllers(viewControllers, direction: .forward, animated: true, completion: {done in })
        
        return .mid
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if finished && completed {
            updateNavigationController()
        }
    }
    
    func setupNotifications() {
        // Listen for global update timer.
        NotificationCenter.default.addObserver(self, selector: #selector(SiteListPageViewController.updateNavigationController), name: .NightscoutDataUpdatedNotification, object: nil)
    }
    
    func updateNavigationController() {
        navigationItem.title = pageViewController?.viewControllers!.first?.navigationItem.title
        navigationItem.rightBarButtonItems = pageViewController?.viewControllers!.first?.navigationItem.rightBarButtonItems
    }
}
