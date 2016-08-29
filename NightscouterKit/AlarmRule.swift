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
public class AlarmRule {
    
    private static var snoozedUntilTimestamp: NSTimeInterval = NSTimeInterval()
    
    public static var alarmingSites = [Site]()
    
    /*
     * Returns true if the alarm should be played.
     * Snooze is true if the Alarm has been manually deactivated.
     * Suspended is true if the Alarm has been technically deactivated for a short period of time.
     */
    public static func isAlarmActivated(forSites sites:[Site]) -> (activated: Bool, urgent: Bool, snooze: Bool) {
        
        var urgent: Bool = false
        
        alarmingSites = sites.filter { site in
            let viewModel = site.viewModel
            if viewModel.warn || viewModel.urgent || viewModel.alarmForSGV {
                urgent = viewModel.urgent
                return true
            } else {
                return false
            }
        }

        if alarmingSites.isEmpty {
            disableSnooze()
            
            return (false, false, false)
        }
        
        return (!alarmingSites.isEmpty, urgent, isSnoozed)
    }
    
    /*
     * Snoozes all alarms for the next x minutes.
     */
    public static func snooze(minutes : Int) {
        snoozedUntilTimestamp = NSDate().timeIntervalSince1970 + Double(60 * minutes)
    }
    
    /*
     * This is used to snooze just a few seconds on startup in order to retrieve
     * new values. Otherwise the alarm would play at once which makes no sense on startup.
     */
    public static func snooze(seconds seconds : Int) {
        snoozedUntilTimestamp = NSDate().timeIntervalSince1970 + Double(seconds)
    }
    
    /*
     * An eventually activated snooze will be disabled again.
     */
    public static func disableSnooze() {
        snoozedUntilTimestamp = NSTimeInterval()
    }
    
    /*
     * Returns true if the alarms are currently snoozed.
     */
    public static var isSnoozed: Bool {
        let currentTimestamp = NSDate().timeIntervalSince1970
        return currentTimestamp < snoozedUntilTimestamp
    }
    
    /*
     * Return the number of remaing minutes till the snooze state ends.
     * The value will always be rounded up.
     */
    public static var remainingSnoozeMinutes: Int {
        let currentTimestamp = NSDate().timeIntervalSince1970
        
        if (snoozedUntilTimestamp - currentTimestamp) <= 0 {
            return 0
        }
        
        return Int(ceil((snoozedUntilTimestamp - currentTimestamp) / 60.0))
    }
}