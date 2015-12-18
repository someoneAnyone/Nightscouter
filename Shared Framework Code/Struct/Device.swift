//
//  File.swift
//  Nightscouter
//
//  Created by Peter Ina on 10/6/15.
//  Copyright © 2015 Peter Ina. All rights reserved.
//

import Foundation

public enum Device: String, DictionaryConvertible, CustomStringConvertible {
    case Unknown = "unknown", Dexcom = "dexcom", xDripDexcomShare = "xDrip-DexcomShare", WatchFace = "watchFace", Share2 = "share2"
    
    public var description: String {
        return self.rawValue
    }
    
    public init() {
        self = .Unknown
    }
}