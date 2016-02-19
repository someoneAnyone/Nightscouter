
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
    
    // MARK: - Timeline Configuration
    
    func getSupportedTimeTravelDirectionsForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationTimeTravelDirections) -> Void) {
        handler([.Backward, .Forward])
    }
    
    func getTimelineStartDateForComplication(complication: CLKComplication, withHandler handler: (NSDate?) -> Void) {
        #if DEBUG
            print(">>> Entering \(__FUNCTION__) <<<")
        #endif
        var date: NSDate?
        let model = WatchSessionManager.sharedManager.complicationData.last
        date = model?.date
        
        #if DEBUG
            print("getTimelineStartDateForComplication:\(date)")
        #endif
        
        handler(date)
    }
    
    func getTimelineEndDateForComplication(complication: CLKComplication, withHandler handler: (NSDate?) -> Void) {
        #if DEBUG
            print(">>> Entering \(__FUNCTION__) <<<")
        #endif
        var date: NSDate?
        
        let model = WatchSessionManager.sharedManager.complicationData.first
//        let staleDate = model?.date.dateByAddingTimeInterval(60.0 * 15)
//        if staleDate?.compare(NSDate()) == .OrderedDescending {
//            date = staleDate
//        }
        date = model?.date
        
        #if DEBUG
            print("getTimelineEndDateForComplication:\(date)")
        #endif
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
        #endif
        
        getTimelineEntriesForComplication(complication, beforeDate: NSDate(), limit: 1) { (timelineEntries) -> Void in
            handler(timelineEntries?.first)
        }
    }
    
    func getTimelineEntriesForComplication(complication: CLKComplication, beforeDate date: NSDate, limit: Int, withHandler handler: ([CLKComplicationTimelineEntry]?) -> Void) {
        // Call the handler with the timeline entries prior to the given date
        #if DEBUG
            // print(">>> Entering \(__FUNCTION__) <<<")
            // print("complication: \(complication.family)")
        #endif
        
        var timelineEntries = [CLKComplicationTimelineEntry]()
        
        let entries = WatchSessionManager.sharedManager.complicationData
        
        for entry in entries {
            let entryDate = entry.date
            if date.compare(entryDate) == .OrderedDescending {
                if let template = templateForComplication(complication, model: entry) {
                    let entry = CLKComplicationTimelineEntry(date: entryDate, complicationTemplate: template)
                    timelineEntries.append(entry)
                    if timelineEntries.count == limit {
                        break
                    }
                }
            }
        }
        
        handler(timelineEntries)
    }
    
    func getTimelineEntriesForComplication(complication: CLKComplication, afterDate date: NSDate, limit: Int, withHandler handler: (([CLKComplicationTimelineEntry]?) -> Void)) {
        // Call the handler with the timeline entries after to the given date
        #if DEBUG
            // print(">>> Entering \(__FUNCTION__) <<<")
        #endif
        
        var timelineEntries = [CLKComplicationTimelineEntry]()
        
        let entries = WatchSessionManager.sharedManager.complicationData
        
        for entry in entries {
            let entryDate = entry.date
            if date.compare(entryDate) == .OrderedAscending {
                if let template = templateForComplication(complication, model: entry) {
                    let entry = CLKComplicationTimelineEntry(date: entryDate, complicationTemplate: template)
                    timelineEntries.append(entry)
                    
                    if timelineEntries.count == limit {
                        break
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
        
        let nextUpdate = WatchSessionManager.sharedManager.nextRequestedComplicationUpdateDate
        
        #if DEBUG
            print("Next Requested Update Date is:\(nextUpdate)")
        #endif
        
        handler(nextUpdate)
    }
    
    static func reloadComplications() {
        #if DEBUG
            print(">>> Entering \(__FUNCTION__) <<<")
        #endif
        
        let complicationServer = CLKComplicationServer.sharedInstance()
        if let activeComplications = complicationServer.activeComplications {
            for complication in activeComplications {
                complicationServer.reloadTimelineForComplication(complication)
            }
        }
    }
    
    static func extendComplications() {
        #if DEBUG
            print(">>> Entering \(__FUNCTION__) <<<")
        #endif
        
        let complicationServer = CLKComplicationServer.sharedInstance()
        if let activeComplications = complicationServer.activeComplications {
            for complication in activeComplications {
                complicationServer.extendTimelineForComplication(complication)
            }
        }
    }
    
    func requestedUpdateDidBegin() {
        #if DEBUG
            print(">>> Entering \(__FUNCTION__) <<<")
        #endif
        
        WatchSessionManager.sharedManager.updateComplication()
        
    }
    
    func requestedUpdateBudgetExhausted() {
        #if DEBUG
            print(">>> Entering \(__FUNCTION__) <<<")
        #endif
        
        WatchSessionManager.sharedManager.complicationRequestedUpdateBudgetExhausted()
    }
    
    // MARK: - Placeholder Templates
    
    func getPlaceholderTemplateForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationTemplate?) -> Void) {
        // This method will be called once per supported complication, and the results will be cached
        #if DEBUG
            // print(">>> Entering \(__FUNCTION__) <<<")
            // print("complication family: \(complication.family)")
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
    
    // MARK: Create Complication Templates
    
    private func templateForComplication(complication: CLKComplication, model: ComplicationModel) -> CLKComplicationTemplate? {
        #if DEBUG
            // print(">>> Entering \(__FUNCTION__) <<<")
        #endif
        
        var template: CLKComplicationTemplate
        
        let displayName = model.displayName
        let sgv = model.sgv
        let tintString = model.tintString
        let delta = model.delta
        let deltaShort = model.deltaShort
        var raw = PlaceHolderStrings.rawShort
        var rawShort = PlaceHolderStrings.rawShort
        
        if let rawLong = model.raw, rawShor = model.rawShort {
            raw = rawLong // only if available.
            rawShort = rawShor
        }
        
        let utilLargeSting = sgv + " (" + delta + ") " + raw
        let utilLargeStingShort = sgv + " (" + deltaShort + ") " + rawShort
        
        switch complication.family {
        case .ModularSmall:
            let modularSmall = CLKComplicationTemplateModularSmallStackText()
            modularSmall.line1TextProvider = CLKSimpleTextProvider(text: sgv)
            modularSmall.line2TextProvider = CLKSimpleTextProvider(text: delta, shortText: deltaShort)
            modularSmall.tintColor = UIColor(hexString: tintString)
            
            // Set the template
            template = modularSmall
        case .ModularLarge:
            let modularLarge = CLKComplicationTemplateModularLargeTable()
            modularLarge.headerTextProvider = CLKSimpleTextProvider(text: sgv + " (" + delta + ")", shortText: sgv + " (" + deltaShort + ")")
            modularLarge.row1Column1TextProvider = CLKSimpleTextProvider(text: displayName)
            modularLarge.row1Column2TextProvider = CLKRelativeDateTextProvider(date: model.date, style: .Natural, units: [.Minute, .Hour, .Day])
            modularLarge.row2Column1TextProvider = CLKSimpleTextProvider(text:  raw, shortText: rawShort)
            modularLarge.row2Column2TextProvider = CLKSimpleTextProvider(text: "")
            
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
            utilitarianLarge.tintColor = UIColor(hexString: tintString)
            
            // Set the template
            template = utilitarianLarge
        case .CircularSmall:
            let circularSmall = CLKComplicationTemplateCircularSmallStackText()
            circularSmall.line1TextProvider = CLKSimpleTextProvider(text: sgv)
            circularSmall.line2TextProvider = CLKSimpleTextProvider(text: delta, shortText: deltaShort)
            circularSmall.tintColor = UIColor(hexString: tintString)
            
            // Set the template
            template = circularSmall
        }
        
        return template
    }
}
