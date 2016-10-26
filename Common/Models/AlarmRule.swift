//
//  AlarmRule.swift
//  scoutwatch / nightscouter
//
//  Created by Dirk Hermanns on 25.01.16.
//  Modified by Peter Ina on 05.01.2016
//  Copyright © 2016. All rights reserved.
//

import Foundation

/**
 * This class implements the Rules for which an alarm should be played.
 *
 * This is right now the case if
 * - the blood glucose is above outside of the configuration's provided thresholds.
 * - or the last value is older than 15 Minutes
 *
 * Further more an Alarm can be snoozed temporarily.
 * Therefore this class remembers whether an alarm has been snoozed
 * and how long the snooze should last.
 */
open class AlarmRule {
    
    fileprivate static var snoozedUntilTimestamp: TimeInterval = TimeInterval()
    
    /*
     * Snoozes all alarms for the next x minutes.
     */
    open static func snooze(_ minutes : Int) {
        snoozedUntilTimestamp = Date().timeIntervalSince1970 + Double(60 * minutes)
    }
    
    /*
     * This is used to snooze just a few seconds on startup in order to retrieve
     * new values. Otherwise the alarm would play at once which makes no sense on startup.
     */
    open static func snooze(seconds : Int) {
        snoozedUntilTimestamp = Date().timeIntervalSince1970 + Double(seconds)
    }
    
    /*
     * An eventually activated snooze will be disabled again.
     */
    open static func disableSnooze() {
        snoozedUntilTimestamp = TimeInterval()
    }
    
    /*
     * Returns true if the alarms are currently snoozed.
     */
    open static var isSnoozed: Bool {
        let currentTimestamp = Date().timeIntervalSince1970
        return currentTimestamp < snoozedUntilTimestamp
    }
    
    /*
     * Return the number of remaing minutes till the snooze state ends.
     * The value will always be rounded up.
     */
    open static var remainingSnoozeMinutes: Int {
        let currentTimestamp = Date().timeIntervalSince1970
        
        if (snoozedUntilTimestamp - currentTimestamp) <= 0 {
            return 0
        }
        
        return Int(ceil((snoozedUntilTimestamp - currentTimestamp) / 60.0))
    }
}
