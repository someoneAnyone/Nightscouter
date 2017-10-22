//
//  Calibration.swift
//  Nightscouter
//
//  Created by Peter Ina on 1/11/16.
//  Copyright © 2016 Nothingonline. All rights reserved.
//

import Foundation

/// A record type provided by the Nightscout API, contains information required to calculate raw blood glucose level.
public struct Calibration: CustomStringConvertible, Dateable, Codable {
    public let slope: Double, intercept: Double, scale: Double, milliseconds: Mills?
    
    public init() {
        slope = 856.59
        intercept = 32179
        scale = 1.0
        milliseconds = 1268197200000 // AppConfiguration.Constant.knownMilliseconds
    }
    
    enum CodingKeys: String, CodingKey {
        case slope, intercept, scale
        case milliseconds = "date"
    }
    
    public init(slope: Double, intercept: Double, scale: Double, milliseconds: Mills) {
        self.slope = slope
        self.intercept = intercept
        self.scale = scale
        self.milliseconds = milliseconds
    }
    
    public var description: String {
        return "{ Calibration: { slope: \(slope), intercept: \(intercept), scale: \(scale), date: \(date) } }"
    }
}
