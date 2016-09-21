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
        return NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "", comment: "")
    }
    public func localizedWithComment(_ comment:String) -> String {
        return NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "", comment: comment)
    }
}

public extension String {
    public var versions: [String] {
        return self.components(separatedBy: ".")
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
    var formatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = Locale.autoupdatingCurrent
        return formatter
    }
    
    public var floatValue: Float? {
        return formatter.number(from: self)?.floatValue
    }
    public var toDouble: Double? {
        return formatter.number(from: self)?.doubleValue
    }
}
