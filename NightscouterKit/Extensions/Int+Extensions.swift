//
//  Int+Extensions.swift
//  Nightscouter
//
//  Created by Peter Ina on 7/15/15.
//  Copyright (c) 2015 Peter Ina. All rights reserved.
//

import Foundation

public extension Int {
    internal var bgDeltaFormatter: NSNumberFormatter {
        let numberFormat =  NSNumberFormatter()
            numberFormat.numberStyle = .NoStyle
            numberFormat.positivePrefix = numberFormat.plusSign
            numberFormat.negativePrefix = numberFormat.minusSign
            
            return numberFormat
    }
    
    public var formattedForBGDelta: String {
        return self.bgDeltaFormatter.stringFromNumber(self)!
    }
}