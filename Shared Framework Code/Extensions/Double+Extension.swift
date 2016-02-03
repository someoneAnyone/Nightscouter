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
            
            if (startIndex as! Int) < 0   // allow negative ranges
            {
                offset = abs(startIndex as! Int)
            }
            
            let mini = UInt32(startIndex as! Int + offset)
            let maxi = UInt32(endIndex as! Int + offset)
            
            return Int(mini + arc4random_uniform(maxi - mini)) - offset
        }
    }
}


public extension Double {
    public func millisecondsToSecondsTimeInterval() -> NSTimeInterval {
        return round(self/1000)
    }
    
    public var inThePast: NSTimeInterval {
        return -self
    }
    
    public func toDateUsingSeconds() -> NSDate {
        let date = NSDate(timeIntervalSince1970:millisecondsToSecondsTimeInterval())
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
    
    internal var mgdlFormatter: NSNumberFormatter {
        let numberFormat = NSNumberFormatter()
        numberFormat.numberStyle = .NoStyle
        
        return numberFormat
    }
    
    public var formattedForMgdl: String {
        return self.mgdlFormatter.stringFromNumber(self)!
    }

    internal var mmolFormatter: NSNumberFormatter {
        let numberFormat = NSNumberFormatter()
        numberFormat.numberStyle = .DecimalStyle
        numberFormat.minimumFractionDigits = 1
        numberFormat.maximumFractionDigits = 1
        numberFormat.secondaryGroupingSize = 1

        return numberFormat
    }
    
    public var formattedForMmol: String {
        return self.mmolFormatter.stringFromNumber(self.toMmol)!
    }
}

public extension Double {
    internal var bgDeltaFormatter: NSNumberFormatter {
        let numberFormat =  NSNumberFormatter()
        numberFormat.numberStyle = .DecimalStyle
        numberFormat.positivePrefix = numberFormat.plusSign
        numberFormat.negativePrefix = numberFormat.minusSign
        numberFormat.minimumFractionDigits = 1
        numberFormat.maximumFractionDigits = 1
        numberFormat.secondaryGroupingSize = 1
        
        return numberFormat
    }
    
    public var formattedForBGDelta: String {
        return self.bgDeltaFormatter.stringFromNumber(self)!
    }
}

public extension Double {
    var isInteger: Bool {
        return rint(self) == self
    }
}