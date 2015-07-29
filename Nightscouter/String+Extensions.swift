//
//  String+Extensions.swift
//  Nightscouter
//
//  Created by Peter Ina on 7/28/15.
//  Copyright (c) 2015 Peter Ina. All rights reserved.
//

import Foundation

extension String {
    var localized: String {
        return NSLocalizedString(self, tableName: nil, bundle: NSBundle.mainBundle(), value: "", comment: "")
    }
    func localizedWithComment(comment:String) -> String {
        return NSLocalizedString(self, tableName: nil, bundle: NSBundle.mainBundle(), value: "", comment: comment)
    }
    
    var versions: [String] {
        return self.componentsSeparatedByString(".")
    }
    
    var majorVersion: Int {
        return versions.first!.toInt()!
    }
    var minorVersion: Int {
        return versions[1].toInt()!
    }
    var buildVersion: Int {
        return versions.last!.toInt()!
    }
}