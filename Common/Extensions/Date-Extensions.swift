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
    public static let OneMinute: TimeInterval = 60.0
    public static let TwoAndHalfMinutes: TimeInterval = OneMinute * 2.5
    public static let FourMinutes: TimeInterval = OneMinute * 4
    public static let TenMinutes: TimeInterval = OneMinute * 10
    public static let ThirtyMinutes: TimeInterval = OneMinute * 30
    public static let OneHour: TimeInterval = OneMinute * 60
    public static let TwoHours: TimeInterval = OneMinute * 120
}
