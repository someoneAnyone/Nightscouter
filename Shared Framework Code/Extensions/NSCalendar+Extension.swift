//
//  RelativeDateCalculations.swift
//  Nightscout
//
//  Created by Peter Ina on 5/14/15.
//  Copyright (c) 2015 Peter Ina. All rights reserved.
//

import Foundation

// MARK: Comparable instance for NSDate
public func <(a: NSDate, b: NSDate) -> Bool {
    return a.compare(b) == .OrderedAscending
}

public func ==(a: NSDate, b: NSDate) -> Bool {
    return a.compare(b) == .OrderedSame
}

public extension NSCalendar {
        
    public func stringRepresentationOfElapsedTimeFromDate(startDate: NSDate, endDate: NSDate) -> String {
        
        if (!startDate.timeIntervalSince1970.isSignMinus && !endDate.timeIntervalSince1970.isSignMinus){

//            let hourMinuteComponents: NSCalendarUnit = [.Month, .Weekday, .Hour, .Minute, .Day]
//            let componentsVar: NSDateComponents = self.components(hourMinuteComponents, fromDate: startDate, toDate: endDate, options: [])
            
            let hourMinuteComponents: NSCalendarUnit = [.Month, .Weekday, .Hour, .Minute, .Day]
            let componentsVar: NSDateComponents = self.components(hourMinuteComponents, fromDate: startDate, toDate: endDate, options: [])

            
            var months: Int = componentsVar.month
            var weeks: Int = componentsVar.weekday
            var days: Int = componentsVar.day
            var hours: Int = componentsVar.hour
            let minutes: Int = componentsVar.minute
            
            if (months > 1) {
                // Simple date/time
                if (weeks > 3) {
                    // Almost another month - fuzzy
                    months++;
                }
                return "\(months) months ago"
            }
            else if (months == 1) {
                if (weeks > 3) {
                    months++;
                    // Almost 2 months
                    return "\(months) months ago"
                }
                // approx 1 month
                return "1 month ago"
            } else if (weeks > 1) {
                if (days > 6) {
                    // Weeks
                    
                    // Almost another month - fuzzy
                    weeks++;
                }
                return "\(weeks) weeks ago"
            }
            else if (weeks == 1 || days > 6) {
                if (days > 6) {
                    weeks++;
                    // Almost 2 weeks
                    return "\(weeks) weeks ago"
                }
                return "1 week ago"
            }
                // Days
            else if (days > 1) {
                if (hours > 20) {
                    days++;
                }
                return "\(days) days ago"
            }
            else if (days == 1) {
                if (hours > 20) {
                    days++;
                    return "\(days) days ago"
                }
                return "1 day ago"
            }
                // Hours
            else if (hours > 1) {
                if (minutes > 50) {
                    hours++;
                }
                return "\(hours) hours ago"
            }
            else if (hours == 1) {
                if (minutes > 50) {
                    hours++;
                    return "\(hours) hours ago"
                }
                return "1 hour ago"
            }
                // Minutes
            else if (minutes > 1) {
                return "\(minutes) mins ago"
            }
            else if (minutes == 1) {
                return "1 min ago"
            }
            else if (minutes < 1) {
                return "Just now"
            }
        }
        return "Nothing"
    }
    
    public func stringRepresentationOfElapsedTimeSinceNow(date:NSDate) -> String {
        return self.stringRepresentationOfElapsedTimeFromDate(date, endDate: NSDate())
    }
}