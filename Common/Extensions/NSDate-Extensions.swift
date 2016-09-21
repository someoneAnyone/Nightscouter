//
//  NSDate-Extensions.swift
//  Nightscouter
//
//  Created by Peter Ina on 2/2/16.
//  Copyright © 2016 Nothingonline. All rights reserved.
//

import Foundation


public extension Date {
    var timeAgoSinceNow: String {
        return Calendar.autoupdatingCurrent.stringRepresentationOfElapsedTimeSinceNow(self)
    }
}

//MARK: OPERATIONS WITH DATES (==,!=,<,>,<=,>=)
/*
extension Date : Comparable {}

public func == (left: Date, right: Date) -> Bool {
    return (left.compare(right) == ComparisonResult.orderedSame)
}

public func != (left: Date, right: Date) -> Bool {
    return !(left == right)
}

public func < (left: Date, right: Date) -> Bool {
    return (left.compare(right) == ComparisonResult.orderedAscending)
}

public func > (left: Date, right: Date) -> Bool {
    return (left.compare(right) == ComparisonResult.orderedDescending)
}

public func <= (left: Date, right: Date) -> Bool {
    return !(left > right)
}

public func >= (left: Date, right: Date) -> Bool {
    return !(left < right)
}
*/

//MARK: ARITHMETIC OPERATIONS WITH DATES (-,-=,+,+=)

public func - (left : Date, right: TimeInterval) -> Date {
    return left.addingTimeInterval(-right)
}

public func -= (left: inout Date, right: TimeInterval) {
    left = left.addingTimeInterval(-right)
}

public func + (left: Date, right: TimeInterval) -> Date {
    return left.addingTimeInterval(right)
}

public func += (left: inout Date, right: TimeInterval) {
    left = left.addingTimeInterval(right)
}


extension TimeInterval {
    public static let OneMinuteInSeconds: TimeInterval = 60.0
    public static let TwoAndHalfMinutesInSeconds: TimeInterval = OneMinuteInSeconds * 2.5
    public static let FourMinutesInSeconds: TimeInterval = OneMinuteInSeconds * 4
    public static let TenMinutesInSeconds: TimeInterval = OneMinuteInSeconds * 10
    public static let ThirtyMinutesInSeconds: TimeInterval = OneMinuteInSeconds * 30
    public static let OneHourInSeconds: TimeInterval = OneMinuteInSeconds * 60
    public static let TwoHoursInSeconds: TimeInterval = OneMinuteInSeconds * 120
}
