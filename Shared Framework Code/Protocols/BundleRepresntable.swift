//
//  BundleRepresntable.swift
//  Nightscouter
//
//  Created by Peter Ina on 12/13/15.
//  Copyright © 2015 Peter Ina. All rights reserved.
//

import Foundation


public protocol BundleRepresentable {
    
    var sharedGroupIdentifier: String { get }
    
    var infoDictionary: [String : AnyObject]? { get }
    
    var bundleIdentifier: NSURL? { get }
}

extension BundleRepresentable {
     public var sharedGroupIdentifier: String {
        let group = NSURL(string: "group")
        
        return (group?.URLByAppendingPathExtension((bundleIdentifier?.absoluteString)!).absoluteString)!
    }
    
    public var infoDictionary: [String: AnyObject]? {
        return NSBundle.mainBundle().infoDictionary as [String : AnyObject]? // Grab the info.plist dictionary from the main bundle.
    }
    
    public var bundleIdentifier: NSURL? {
        return NSURL(string: NSBundle.mainBundle().bundleIdentifier!)
    }
}