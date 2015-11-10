//
//  String+Extensions.swift
//  Nightscouter
//
//  Created by Peter Ina on 7/28/15.
//  Copyright (c) 2015 Peter Ina. All rights reserved.
//

import Foundation

public extension String {
    public var localized: String {
        return NSLocalizedString(self, tableName: nil, bundle: NSBundle.mainBundle(), value: "", comment: "")
    }
    public func localizedWithComment(comment:String) -> String {
        return NSLocalizedString(self, tableName: nil, bundle: NSBundle.mainBundle(), value: "", comment: comment)
    }
}

public extension String {
    public var versions: [String] {
        return self.componentsSeparatedByString(".")
    }
    public var majorVersion: Int {
        return Int(versions.first!)!
    }
    public var minorVersion: Int {
        return Int(versions[1])!
    }
    public var buildVersion: Int {
        return Int(versions.last!)!
    }
}

public extension String {
    public var floatValue: Float? {
        return NSNumberFormatter().numberFromString(self)?.floatValue //(self as NSString).floatValue
    }
    public var toDouble: Double? {
        return NSNumberFormatter().numberFromString(self)?.doubleValue
    }
}