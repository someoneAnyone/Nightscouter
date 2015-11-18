//
//  DictionaryRepresentable.swift
//  Nightscouter
//
//  Created by Peter Ina on 11/13/15.
//  Copyright © 2015 Peter Ina. All rights reserved.
//

import Foundation


public protocol DictionaryConvertible {
    var dictionary: [String: AnyObject] { get }
}

extension DictionaryConvertible {
     public var dictionary: [String: AnyObject] {
        var dict = [String :AnyObject] ()
        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            guard let key = child.label else {
                continue
            }
            let value = child.value
            
            guard let result = self.unwrap(value) else {
                continue
            }
            
            // print("\(key): \(result)")
            dict[key] = result as? AnyObject
        }
        
        return dict
    }
    
    
    private func unwrap(subject: Any) -> Any? {
        var value: Any?
        let mirrored = Mirror(reflecting:subject)
        if mirrored.displayStyle != .Optional {
            value = subject
        } else if let firstChild = mirrored.children.first {
            value = firstChild.value
        }
        return value
    }

}

