//
//  ComplicationController.swift
//  NightscouterNow Extension
//
//  Created by Peter Ina on 10/4/15.
//  Copyright © 2015 Peter Ina. All rights reserved.
//

import ClockKit
import NightscouterWatchOSKit

class ComplicationController: NSObject, CLKComplicationDataSource {
    
    override init() {
        //WatchSessionManager.sharedManager.generateTimelineData()
    }
    
    // MARK: - Timeline Configuration
    func getSupportedTimeTravelDirectionsForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationTimeTravelDirections) -> Void) {
        handler([.Backward])//[.Forward, .Backward])
    }
    
    func getTimelineStartDateForComplication(complication: CLKComplication, withHandler handler: (NSDate?) -> Void) {
        #if DEBUG
            print(">>> Entering \(__FUNCTION__) <<<")
        #endif
        
        let today: NSDate = NSDate()
        let hoursToAdd:Int = -2
        
        // Set up date components
        let dateComponents: NSDateComponents = NSDateComponents()
        dateComponents.hour = hoursToAdd
        
        // Create a calendar
        let gregorianCalendar: NSCalendar = NSCalendar(identifier: NSCalendarIdentifierGregorian)!
        let eightHoursAgo: NSDate = gregorianCalendar.dateByAddingComponents(dateComponents, toDate: today, options:NSCalendarOptions(rawValue: 0))!
        
        handler(eightHoursAgo)
    }
    
    func getTimelineEndDateForComplication(complication: CLKComplication, withHandler handler: (NSDate?) -> Void) {
        
        #if DEBUG
            print(">>> Entering \(__FUNCTION__) <<<")
        #endif
        
        var date: NSDate? = nil
        let entries = WatchSessionManager.sharedManager.timelineDataForComplication()
        
        if let entries = entries {
            date = entries.last?.date
        }
        
        
        print("returning date: \(date)")
        handler(date)
        
    }
    
    func getPrivacyBehaviorForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.ShowOnLockScreen)
    }
    
    // MARK: - Timeline Population
    
    func getCurrentTimelineEntryForComplication(complication: CLKComplication, withHandler handler: ((CLKComplicationTimelineEntry?) -> Void)) {
        // Call the handler with the current timeline entry
        #if DEBUG
            print(">>> Entering \(__FUNCTION__) <<<")
            print("complication family: \(complication.family)")
        #endif
        
        var timelineEntry : CLKComplicationTimelineEntry?
        
        let entries = WatchSessionManager.sharedManager.timelineDataForComplication()
        
        
        
        let today: NSDate = NSDate()
        let minutesToAdd = -Constants.NotableTime.StaleDataTimeFrame
        
        // Set up date components
        let dateComponents: NSDateComponents = NSDateComponents()
        dateComponents.minute = Int(minutesToAdd)
        
        // Create a calendar
        let gregorianCalendar: NSCalendar = NSCalendar(identifier: NSCalendarIdentifierGregorian)!
        let alittleWhileAgo: NSDate = gregorianCalendar.dateByAddingComponents(dateComponents, toDate: today, options:NSCalendarOptions(rawValue: 0))!
        
        if let entry = entries?.first {
            let entryDate = entry.date
            print("model \(entry.date.timeIntervalSinceNow) + date \(alittleWhileAgo.timeIntervalSinceNow)")
            if let template = templateForComplication(complication, model: entry) {
                timelineEntry = CLKComplicationTimelineEntry(date: entryDate, complicationTemplate: template)
            }
        }
        
        print("timelineEntry: \(timelineEntry)")
        
        
        handler(timelineEntry)
        
    }
    
    
    func getTimelineEntriesForComplication(complication: CLKComplication, beforeDate date: NSDate, limit: Int, withHandler handler: ([CLKComplicationTimelineEntry]?) -> Void) {
        // Call the handler with the timeline entries prior to the given date
        #if DEBUG
            print(">>> Entering \(__FUNCTION__) <<<")
            
        #endif
        
        var timelineEntries = [CLKComplicationTimelineEntry]()
        
        let entries = WatchSessionManager.sharedManager.timelineDataForComplication()
        
        if let entries = entries {
            for entry in entries {
                let entryDate = entry.date
                if entryDate.timeIntervalSinceNow < date.timeIntervalSinceNow {
                    if let template = templateForComplication(complication, model: entry) {
                        let entry = CLKComplicationTimelineEntry(date: entryDate, complicationTemplate: template)
                        timelineEntries.append(entry)
                        
                        if entries.count == limit {
                            break
                        }
                    }
                }
                
            }
        }
        
        
        handler(timelineEntries)
    }
    
    func getTimelineEntriesForComplication(complication: CLKComplication, afterDate date: NSDate, limit: Int, withHandler handler: (([CLKComplicationTimelineEntry]?) -> Void)) {
        // Call the handler with the timeline entries after to the given date
        #if DEBUG
            print(">>> Entering \(__FUNCTION__) <<<")
        #endif
        
        var timelineEntries = [CLKComplicationTimelineEntry]()
        
        let entries = WatchSessionManager.sharedManager.timelineDataForComplication()
        
        if let entries = entries {
            for entry in entries {
                let entryDate = entry.date
                if entryDate.timeIntervalSinceNow > date.timeIntervalSinceNow {
                    if let template = templateForComplication(complication, model: entry) {
                        let entry = CLKComplicationTimelineEntry(date: entryDate, complicationTemplate: template)
                        timelineEntries.append(entry)
                        
                        if entries.count == limit {
                            break
                        }
                    }
                }
                
            }
        }
        
        
        handler(timelineEntries)
    }
    
    // MARK: - Update Scheduling
    
    func getNextRequestedUpdateDateWithHandler(handler: (NSDate?) -> Void) {
        // Call the handler with the date when you would next like to be given the opportunity to update your complication content
        #if DEBUG
            print(">>> Entering \(__FUNCTION__) <<<")
        #endif
        
        handler(NSDate(timeIntervalSinceNow: Constants.NotableTime.StandardRefreshTime));
    }
    
    static func reloadComplications() {
        #if DEBUG
            print(">>> Entering \(__FUNCTION__) <<<")
        #endif
        
        if let complicationServer = CLKComplicationServer.sharedInstance() {
            for complication in complicationServer.activeComplications {
                // complicationServer.reloadTimelineForComplication(complication)
                complicationServer.extendTimelineForComplication(complication)
            }
        }
    }
    
    func requestedUpdateDidBegin() {
        #if DEBUG
            print(">>> Entering \(__FUNCTION__) <<<")
        #endif
        
    }
    
    func requestedUpdateBudgetExhausted() {
        #if DEBUG
            print(">>> Entering \(__FUNCTION__) <<<")
        #endif
    }
    
    // MARK: - Placeholder Templates
    
    func getPlaceholderTemplateForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationTemplate?) -> Void) {
        // This method will be called once per supported complication, and the results will be cached
        #if DEBUG
            print(">>> Entering \(__FUNCTION__) <<<")
            print("complication family: \(complication.family)")
        #endif
        
        var template: CLKComplicationTemplate
        
        let tintString = NSAssetKitWatchOS.predefinedNeutralColor.toHexString()
        
        let utilLargeSting = PlaceHolderStrings.sgv + " " + PlaceHolderStrings.delta + " " + PlaceHolderStrings.raw
        
        switch complication.family {
        case .ModularSmall:
            let modularSmall = CLKComplicationTemplateModularSmallStackText()
            modularSmall.line1TextProvider = CLKSimpleTextProvider(text: PlaceHolderStrings.sgv)
            modularSmall.line2TextProvider = CLKSimpleTextProvider(text: PlaceHolderStrings.delta)
            modularSmall.tintColor = UIColor(hexString: tintString)
            
            // Set the template
            template = modularSmall
        case .ModularLarge:
            let modularLarge = CLKComplicationTemplateModularLargeStandardBody()
            modularLarge.headerTextProvider = CLKSimpleTextProvider(text: PlaceHolderStrings.displayName)
            modularLarge.body1TextProvider = CLKSimpleTextProvider(text: PlaceHolderStrings.delta)
            modularLarge.body2TextProvider = CLKSimpleTextProvider(text: PlaceHolderStrings.raw)
            modularLarge.tintColor = UIColor(hexString: tintString)
            
            // Set the template
            template = modularLarge
        case .UtilitarianSmall:
            let utilitarianSmall = CLKComplicationTemplateUtilitarianSmallFlat()
            utilitarianSmall.textProvider = CLKSimpleTextProvider(text: PlaceHolderStrings.sgv)
            
            // Set the template
            template = utilitarianSmall
        case .UtilitarianLarge:
            let utilitarianLarge = CLKComplicationTemplateUtilitarianLargeFlat()
            utilitarianLarge.textProvider = CLKSimpleTextProvider(text: utilLargeSting)
            
            // Set the template
            template = utilitarianLarge
        case .CircularSmall:
            let circularSmall = CLKComplicationTemplateCircularSmallStackText()
            circularSmall.line1TextProvider = CLKSimpleTextProvider(text: PlaceHolderStrings.sgv)
            circularSmall.line2TextProvider = CLKSimpleTextProvider(text: PlaceHolderStrings.delta)
            
            // Set the template
            template = circularSmall
        }
        
        handler(template)
    }
    
    private func templateForComplication(complication: CLKComplication, model: ComplicationModel) -> CLKComplicationTemplate? {
        #if DEBUG
            print(">>> Entering \(__FUNCTION__) <<<")
        #endif
        
        var template: CLKComplicationTemplate
        let dateString = NSCalendar.autoupdatingCurrentCalendar().stringRepresentationOfElapsedTimeSinceNow(model.date)
        
        
        let displayName = model.displayName
        let sgv = model.sgv
        let tintString = model.tintString
        
        
        var shortDate = dateString.characters.split{ $0 == " " }.map(String.init)

        let delta = model.delta  + "(" + shortDate[0] + " " + shortDate[1] + ")"
        let deltaShort = model.deltaShort
        
        var raw = PlaceHolderStrings.rawShort
        var rawShort = PlaceHolderStrings.rawShort
        
        if let rawLong = model.raw, rawShor = model.rawShort {
            raw = rawLong // only if available.
            rawShort = rawShor
        }
        
        let utilLargeSting = sgv + " [" + delta + "] " + raw
        let utilLargeStingShort = sgv + " [" + deltaShort + "] " + rawShort
        
        switch complication.family {
        case .ModularSmall:
            let modularSmall = CLKComplicationTemplateModularSmallStackText()
            modularSmall.line1TextProvider = CLKSimpleTextProvider(text: sgv)
            modularSmall.line2TextProvider = CLKSimpleTextProvider(text: delta, shortText: deltaShort)
            modularSmall.tintColor = UIColor(hexString: tintString)
            
            // Set the template
            template = modularSmall
        case .ModularLarge:
            let modularLarge = CLKComplicationTemplateModularLargeStandardBody()
            modularLarge.headerTextProvider = CLKSimpleTextProvider(text: displayName + " " + sgv)
            modularLarge.body1TextProvider = CLKSimpleTextProvider(text: delta, shortText: deltaShort)
            modularLarge.body2TextProvider = CLKSimpleTextProvider(text: raw, shortText: rawShort)
            modularLarge.tintColor = UIColor(hexString: tintString)
            // Set the template
            template = modularLarge
        case .UtilitarianSmall:
            let utilitarianSmall = CLKComplicationTemplateUtilitarianSmallFlat()
            utilitarianSmall.textProvider = CLKSimpleTextProvider(text: sgv)
            
            // Set the template
            template = utilitarianSmall
        case .UtilitarianLarge:
            let utilitarianLarge = CLKComplicationTemplateUtilitarianLargeFlat()
            utilitarianLarge.textProvider = CLKSimpleTextProvider(text: utilLargeSting, shortText: utilLargeStingShort)
            
            // Set the template
            template = utilitarianLarge
        case .CircularSmall:
            let circularSmall = CLKComplicationTemplateCircularSmallStackText()
            circularSmall.line1TextProvider = CLKSimpleTextProvider(text: sgv)
            circularSmall.line2TextProvider = CLKSimpleTextProvider(text: delta, shortText: deltaShort)
            
            // Set the template
            template = circularSmall
        }
        
        return template
        
    }
    
}
