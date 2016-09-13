//
//  ApplicationExtensions.swift
//  Nightscout
//
//  Created by Peter Ina on 5/18/15.
//  Copyright (c) 2015 Peter Ina. All rights reserved.
//

import Foundation

public extension Range
{
    public var randomInt: Int
        {
        get
        {
            var offset = 0
            
            if (lowerBound as! Int) < 0   // allow negative ranges
            {
                offset = abs(lowerBound as! Int)
            }
            
            let mini = UInt32(lowerBound as! Int + offset)
            let maxi = UInt32(upperBound as! Int + offset)
            
            return Int(mini + arc4random_uniform(maxi - mini)) - offset
        }
    }
}


public extension Double {
    public mutating func millisecondsToSecondsTimeInterval() -> TimeInterval {
        let milliseconds = self/1000
        let rounded = milliseconds.rounded(.toNearestOrAwayFromZero)
        return rounded
    }
    
    public var inThePast: TimeInterval {
        return -self
    }
    
    public mutating func toDateUsingSeconds() -> Date {
        let date = Date(timeIntervalSince1970:millisecondsToSecondsTimeInterval())
        return date
    }
    
}

public extension Double {
    public var toMmol: Double {
        get{
            return (self / 18)
        }
    }
    
    public var toMgdl: Double {
        get{
            return floor(self * 18)
        }
    }
    
    internal var mgdlFormatter: NumberFormatter {
        let numberFormat = NumberFormatter()
        numberFormat.numberStyle = .none
        
        return numberFormat
    }
    
    public var formattedForMgdl: String {
        return self.mgdlFormatter.string(from: NSNumber(value: self))!
    }

    internal var mmolFormatter: NumberFormatter {
        let numberFormat = NumberFormatter()
        numberFormat.numberStyle = .decimal
        numberFormat.minimumFractionDigits = 1
        numberFormat.maximumFractionDigits = 1
        numberFormat.secondaryGroupingSize = 1

        return numberFormat
    }
    
    public var formattedForMmol: String {
        return self.mmolFormatter.string(from: NSNumber(value: self.toMmol))!
    }
}

public extension Double {
    internal var bgDeltaFormatter: NumberFormatter {
        let numberFormat =  NumberFormatter()
        numberFormat.numberStyle = .decimal
        numberFormat.positivePrefix = numberFormat.plusSign
        numberFormat.negativePrefix = numberFormat.minusSign
        
        return numberFormat
    }
    
    public func formattedBGDelta(forUnits units: Units, appendString: String? = nil) -> String {
        var formattedNumber: String = ""
        switch units {
        case .Mmol:
            let numberFormat = bgDeltaFormatter
            numberFormat.minimumFractionDigits = 1
            numberFormat.maximumFractionDigits = 1
            numberFormat.secondaryGroupingSize = 1
            formattedNumber = numberFormat.string(from: NSNumber(value: self)) ?? "?"
            
        case .Mgdl:
            formattedNumber = self.bgDeltaFormatter.string(from: NSNumber(value: self)) ?? "?"
        }
        
        var unitMarker: String = units.description
        if let appendString = appendString {
            unitMarker = appendString
        }
        return formattedNumber + " " + unitMarker
    }
    
//    public var formattedForBGDelta: String {
//        return self.bgDeltaFormatter.stringFromNumber(self)!
//    }
}

public extension Double {
    var isInteger: Bool {
        return rint(self) == self
    }
}
