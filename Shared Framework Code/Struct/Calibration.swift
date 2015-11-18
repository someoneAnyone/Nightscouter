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
}