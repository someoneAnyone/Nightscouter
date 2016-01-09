//
//  Array+Extensions.swift
//  Nightscouter
//
//  Created by Peter Ina on 1/8/16.
//  Copyright © 2016 Peter Ina. All rights reserved.
//

import Foundation

// Thanks Mike Ash
public extension Array {
    public subscript (safe index: UInt) -> Element? {
        return Int(index) < count ? self[Int(index)] : nil
    }
}