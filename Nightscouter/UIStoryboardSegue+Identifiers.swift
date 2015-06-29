//
//  File.swift
//  Nightscouter
//
//  Created by Peter Ina on 6/18/15.
//  Copyright © 2015 Peter Ina. All rights reserved.
//
import UIKit
extension UIStoryboardSegue {
    enum SegueIdentifier: String {
        case EditSite = "EditSite"
        case ShowDetail = "ShowDetail"
        case AddNew = "AddNew"
        case AddNewWhenEmpty = "AddNewWhenEmpty"
        case LaunchLabs = "LaunchLabs"
        case ShowPageView = "ShowPageView"
    }
}