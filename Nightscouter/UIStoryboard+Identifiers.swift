//
//  UIStoryboard+Identifiers.swift
//  Nightscouter
//
//  Created by Peter Ina on 6/22/15.
//  Copyright © 2015 Peter Ina. All rights reserved.
//

import UIKit

extension UIStoryboard {
    enum StoryboardName: String {
        case LaunchScreen = "LaunchScreen"
        case Main = "Main"
        case Labs = "Labs"
    }
    
    enum StoryboardViewControllerIdentifier: String {
        case SiteListTableNavigationController = "SiteListTableNavigationController"
        case SiteListTableViewController = "SiteListTableViewController"
        case SiteListPageViewController = "SiteListPageViewController"
        case SiteDetailViewController = "SiteDetailViewController"
        case SiteFormViewNavigationController = "SiteFormViewNavigationController"
        case SiteFormViewController = "SiteFormViewController"
    }
}