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
    
    let requestedUpdateDate: NSDate = NSDate(timeIntervalSinceNow: 30)
    
    // TODO: Locallize these strings and move them to centeral location so all view can have consistent placeholder text.
    struct PlaceHolderStrings {
        static let displayName: String = "Nightscouter"
        static let sgv: String = "---"
        static let delta: String = "- --/--"
        static let raw: String = "--- : ---"
        static let rawShort: String = "--- : -"
    }
    
    
    // MARK: - Timeline Configuration
    func getSupportedTimeTravelDirectionsForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationTimeTravelDirections) -> Void) {
        handler([.Forward, .Backward])
    }
    
    func getTimelineStartDateForComplication(complication: CLKComplication, withHandler handler: (NSDate?) -> Void) {
        #if DEBUG
            print(">>> Entering \(__FUNCTION__) <<<")
        #endif
        
        let today: NSDate = NSDate()
        let daysToAdd:Int = -1
        
        // Set up date components
        let dateComponents: NSDateComponents = NSDateComponents()
        dateComponents.day = daysToAdd
        
        // Create a calendar
        let gregorianCalendar: NSCalendar = NSCalendar(identifier: NSCalendarIdentifierGregorian)!
        let yesterday: NSDate = gregorianCalendar.dateByAddingComponents(dateComponents, toDate: today, options:NSCalendarOptions(rawValue: 0))!
        
        handler(yesterday)
    }
    
    func getTimelineEndDateForComplication(complication: CLKComplication, withHandler handler: (NSDate?) -> Void) {

        #if DEBUG
            print(">>> Entering \(__FUNCTION__) <<<")
        #endif

        var date: NSDate? = nil
        let site = WatchSessionManager.sharedManager.timelineDataForComplication()
        
        if let site = site, entries = site.entries {
            date = entries.last?.date
        }
        
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
        
        let site = WatchSessionManager.sharedManager.timelineDataForComplication()
        
        if let site = site, entries = site.entries {
            for entry in entries {
                let entryDate = entry.date
                if entryDate.timeIntervalSinceNow == NSDate().timeIntervalSinceNow {
                    if let template = templateForComplication(complication, site: site) {
                        timelineEntry = CLKComplicationTimelineEntry(date: entryDate, complicationTemplate: template)
                    }
                }
                
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
        
        let site = WatchSessionManager.sharedManager.timelineDataForComplication()
        
        if let site = site, entries = site.entries {
            for entry in entries {
                let entryDate = entry.date
                if entryDate.timeIntervalSinceNow < date.timeIntervalSinceNow {
                    if let template = templateForComplication(complication, site: site) {
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
        
        let site = WatchSessionManager.sharedManager.timelineDataForComplication()
        
        if let site = site, entries = site.entries {
            for entry in entries {
                let entryDate = entry.date
                if entryDate.timeIntervalSinceNow > date.timeIntervalSinceNow {
                    if let template = templateForComplication(complication, site: site) {
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

        handler(requestedUpdateDate);
    }
  
   static func reloadComplications() {
        #if DEBUG
            print(">>> Entering \(__FUNCTION__) <<<")
        #endif
        
        if let complicationServer = CLKComplicationServer.sharedInstance() {
            for complication in complicationServer.activeComplications {
                complicationServer.reloadTimelineForComplication(complication)
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
    
    private func templateForComplication(complication: CLKComplication, site: Site) -> CLKComplicationTemplate? {
        #if DEBUG
            print(">>> Entering \(__FUNCTION__) <<<")
        #endif
        
            var template: CLKComplicationTemplate
            
            let displayName = "DISPLAY" //model.displayName
            let sgv = "000 >"// model.sgvStringWithEmoji
            let tintString = UIColor.redColor().toHexString() //model.sgvColor
            
            let delta = "DEL" // model.deltaString
            let deltaShort = "DE" // model.deltaStringShort
            var raw =  ""
            var rawShort = ""
            
//            if model.rawVisible {
//                raw = model.rawString // only if available.
//                rawShort = model.rawString
//            }
            let utilLargeSting = sgv + " [" + delta + " " + raw
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
            
            //            let entry = CLKComplicationTimelineEntry(date: NSDate(), complicationTemplate: template)
            //            handler(entry)
            
            return template
            
    
        
    }
    
    
}
