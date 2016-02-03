//
//  ComplicationModel.swift
//  Nightscouter
//
//  Created by Peter Ina on 1/30/16.
//  Copyright © 2016 Peter Ina. All rights reserved.
//

import Foundation

public struct ComplicationModel: DictionaryConvertible {
    
    public let displayName: String
    public let date: NSDate
    public let sgv: String// = "000 >"// model.sgvStringWithEmoji
    public let sgvEmoji: String
    public let tintString: String//  = UIColor.redColor().toHexString() //model.sgvColor
    
    public let delta: String//  = "DEL" // model.deltaString
    public let deltaShort: String//  = "DE" // model.deltaStringShort
    public var raw: String?//  =  ""
    public var rawShort: String?//  = ""
    public var rawVisible: Bool {
        return (raw != nil)
    }
    
    public init(displayName: String, date: NSDate, sgv: String, sgvEmoji: String, tintString: String, delta: String, deltaShort: String, raw: String, rawShort: String) {
        self.displayName = displayName
        self.date = date
        self.sgv = sgv
        self.sgvEmoji = sgvEmoji
        self.tintString = tintString
        self.delta = delta
        self.deltaShort = deltaShort
        self.raw = raw
        self.rawShort = rawShort
    }
}