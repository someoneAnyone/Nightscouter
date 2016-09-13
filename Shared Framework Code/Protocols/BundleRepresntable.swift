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
    
    var bundleIdentifier: URL? { get }
}

extension BundleRepresentable {
     public var sharedGroupIdentifier: String {
        let group = URL(string: "group")
        
        return (group?.appendingPathExtension((bundleIdentifier?.absoluteString)!).absoluteString)!
    }
    
    public var infoDictionary: [String: AnyObject]? {
        return Bundle.main.infoDictionary as [String : AnyObject]? // Grab the info.plist dictionary from the main bundle.
    }
    
    public var bundleIdentifier: URL? {
        return URL(string: Bundle.main.bundleIdentifier!)
    }
}
