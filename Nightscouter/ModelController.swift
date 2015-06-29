//
//  ModelController.swift
//  TestPageBase
//
//  Created by Peter Ina on 6/22/15.
//  Copyright © 2015 Peter Ina. All rights reserved.
//

import UIKit

/*
 A controller object that manages a simple model -- a collection of sites.
 
 The controller serves as the data source for the page view controller; it therefore implements pageViewController:viewControllerBeforeViewController: and pageViewController:viewControllerAfterViewController:.
 It also implements a custom method, viewControllerAtIndex: which is useful in the implementation of the data source methods, and in the initial configuration of the application.
 
 There is no need to actually create view controllers for each page in advance -- indeed doing so incurs unnecessary overhead. Given the data model, these methods create, configure, and return a new view controller on demand.
 */


class ModelController: NSObject, UIPageViewControllerDataSource {

    var sites: [Site]
    var currentIndex: Int
    
    init(sites: [Site], currentIndex: Int) {
        self.sites = sites
        self.currentIndex = currentIndex
        super.init()
    }

    func viewControllerAtIndex(index: Int, storyboard: UIStoryboard) -> SiteDetailViewController? {
        // Return the data view controller for the given index.
        if (self.sites.count == 0) || (index >= self.sites.count) {
            return nil
        }

        // Create a new view controller and pass suitable data.
        let dataViewController = storyboard.instantiateViewControllerWithIdentifier(UIStoryboard.StoryboardViewControllerIdentifier.SiteDetailViewController.rawValue) as! SiteDetailViewController
        dataViewController.site = self.sites[index]
        return dataViewController
    }

    func indexOfViewController(viewController: SiteDetailViewController) -> Int {
        // Return the index of the given data view controller.
        // For simplicity, this implementation uses a static array of model objects and the view controller stores the model object; you can therefore use the model object to identify the index.
//        currentIndex = sites.indexOf(viewController.site!) ?? NSNotFound
        
        currentIndex = find(sites, viewController.site!) ?? NSNotFound
        return currentIndex
    }

    // MARK: - Page View Controller Data Source

    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        var index = self.indexOfViewController(viewController as! SiteDetailViewController)
        if (index == 0) || (index == NSNotFound) {
            return nil
        }
        
        index--
        return self.viewControllerAtIndex(index, storyboard: viewController.storyboard!)
    }

    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        var index = self.indexOfViewController(viewController as! SiteDetailViewController)
        if index == NSNotFound {
            return nil
        }
        
        index++
        if index == self.sites.count {
            return nil
        }
        return self.viewControllerAtIndex(index, storyboard: viewController.storyboard!)
    }
    
    func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int {
        return self.sites.count
    }
    
    func presentationIndexForPageViewController(pageViewController: UIPageViewController) -> Int {
        return currentIndex
    }

}

