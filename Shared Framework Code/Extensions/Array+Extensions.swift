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

extension Array where Element: Equatable {
    public mutating func insertOrUpdate(_ object: Element) -> Bool {
        if let index = self.index(of: object) {
            self[index] = object
        } else {
            self.append(object)
        }
        
        return self.contains(object)
    }
    
    public mutating func appendUniqueObject(_ object: Element) {
        if contains(object) == false {
            append(object)
        }
    }
    
    public mutating func remove(object: Element) -> Bool {
        if let index = self.index(of: object) {
            self.remove(at: index)
        }
        
        return self.contains(object)
    }
}
