//
//  ApplicationExtensions.swift
//  Nightscout
//
//  Created by Peter Ina on 5/18/15.
//  Copyright (c) 2015 Peter Ina. All rights reserved.
//

import Foundation
import UIKit
extension Double {
    func millisecondsToSecondsTimeInterval() -> NSTimeInterval {
        return round(self/1000)
    }
    
    var inThePast: NSTimeInterval {
        return -self
    }
    
    func toDateUsingSeconds() -> NSDate {
        let date = NSDate(timeIntervalSince1970:millisecondsToSecondsTimeInterval())
        
//        let dateFormatter = NSDateFormatter()
//        //To prevent displaying either date or time, set the desired style to NoStyle.
//        dateFormatter.timeStyle = NSDateFormatterStyle.LongStyle //Set time style
//        dateFormatter.dateStyle = NSDateFormatterStyle.LongStyle //Set date style
//        dateFormatter.timeZone = NSTimeZone()
//        let localDate = dateFormatter.stringFromDate(date)
//        
//        let newDate = dateFormatter.dateFromString(localDate)
        
        return date
    }
    

}

