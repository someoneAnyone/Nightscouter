//
//  NSUbiquitousKeyValueStore+Extensions.swift
//  Nightscouter
//
//  Created by Peter Ina on 3/1/16.
//  Copyright © 2016 Peter Ina. All rights reserved.
//

import Foundation

extension NSUbiquitousKeyValueStore {
    public func resetStorage() -> Bool {
        for key in self.dictionaryRepresentation.keys
        {
            self.removeObjectForKey(key)
        }
        
        // Sync back to iCloud
        return self.synchronize()
    }
}