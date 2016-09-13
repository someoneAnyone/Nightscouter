//
//  Calibration.swift
//  Nightscouter
//
//  Created by Peter Ina on 10/6/15.
//  Copyright © 2015 Peter Ina. All rights reserved.
//

import Foundation

// type = Cal
public struct Calibration: DictionaryConvertible {
    public let slope: Double
    public let scale: Double
    public let intercept: Double
    public let date: Date
}

extension Calibration {
    public init?(fromDictionary d:[String : AnyObject]){
        
        guard let slope = d["slope"] as? Double,
        let scale = d["scale"] as? Double,
        let intercept = d["intercept"] as? Double,
            let date = d["date"] as? Date else {
                return nil
        }
        
        self.slope = slope
        self.scale = scale
        self.intercept = intercept
        self.date = date
    }
}
