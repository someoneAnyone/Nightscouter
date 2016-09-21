//
//  RelativeDateCalculations.swift
//  Nightscouter
//
//  Created by Peter Ina on 5/14/15.
//  Copyright (c) 2015 Peter Ina. All rights reserved.
//

import Foundation

public extension Calendar {
        
    public func stringRepresentationOfElapsedTimeFromDate(_ startDate: Date, endDate: Date) -> String {
    
        // TODO:// Fix
        if (!(startDate.timeIntervalSince1970 < 0) && !(endDate.timeIntervalSince1970 < 0)){
      
            let hourMinuteComponents: Set<Calendar.Component> = [.month, .weekday, .hour, .minute, .day]
            let componentsVar: DateComponents = self.dateComponents(hourMinuteComponents, from: startDate, to: endDate)
                
                
                
                //self.components(hourMinuteComponents, from: startDate, to: endDate, options: [])

            
            var months: Int = componentsVar.month!
            var weeks: Int = componentsVar.weekday!
            var days: Int = componentsVar.day!
            var hours: Int = componentsVar.hour!
            let minutes: Int = componentsVar.minute!
            
            if (months > 1) {
                // Simple date/time
                if (weeks > 3) {
                    // Almost another month - fuzzy
                    months += 1;
                }
                return "\(months) months ago"
            }
            else if (months == 1) {
                if (weeks > 3) {
                    months += 1;
                    // Almost 2 months
                    return "\(months) months ago"
                }
                // approx 1 month
                return "1 month ago"
            } else if (weeks > 1) {
                if (days > 6) {
                    // Weeks
                    
                    // Almost another month - fuzzy
                    weeks += 1;
                }
                return "\(weeks) weeks ago"
            }
            else if (weeks == 1 || days > 6) {
                if (days > 6) {
                    weeks += 1;
                    // Almost 2 weeks
                    return "\(weeks) weeks ago"
                }
                return "1 week ago"
            }
                // Days
            else if (days > 1) {
                if (hours > 20) {
                    days += 1;
                }
                return "\(days) days ago"
            }
            else if (days == 1) {
                if (hours > 20) {
                    days += 1;
                    return "\(days) days ago"
                }
                return "1 day ago"
            }
                // Hours
            else if (hours > 1) {
                if (minutes > 50) {
                    hours += 1;
                }
                return "\(hours) hours ago"
            }
            else if (hours == 1) {
                if (minutes > 50) {
                    hours += 1;
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
    
    public func stringRepresentationOfElapsedTimeSinceNow(_ date:Date) -> String {
        return self.stringRepresentationOfElapsedTimeFromDate(date, endDate: Date())
    }
}
