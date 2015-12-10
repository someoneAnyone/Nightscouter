//
//  ComplicationController.swift
//  NightscouterNow Extension
//
//  Created by Peter Ina on 10/4/15.
//  Copyright © 2015 Peter Ina. All rights reserved.
//

import ClockKit
import NightscouterWatchOSKit

class ComplicationController: NSObject, CLKComplicationDataSource, DataSourceChangedDelegate {
    
    var watchData : WatchModel?
    
    let requestedUpdateDate: NSDate = NSDate(timeIntervalSinceNow: 30)
    
    // TODO: Locallize these strings and move them to centeral location so all view can have consistent placeholder text.
    struct PlaceHolderStrings {
        static let displayName: String = "Nightscouter"
        static let sgv: String = "---"
        static let delta: String = "- --/--"
        static let raw: String = "--- : ---"
        static let rawShort: String = "--- : -"
    }
    
    override init() {
        super.init()
        
        WatchSessionManager.sharedManager.addDataSourceChangedDelegate(self)
        WatchSessionManager.sharedManager.requestLatestAppContext()
    }
    
    // MARK: - Timeline Configuration
    func getSupportedTimeTravelDirectionsForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationTimeTravelDirections) -> Void) {
        handler(.None)
    }
    
    func getTimelineStartDateForComplication(complication: CLKComplication, withHandler handler: (NSDate?) -> Void) {
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
        let today = NSDate()
        
        handler(today)
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
        
        if let model = watchData {
            var template: CLKComplicationTemplate
            
            let displayName = model.displayName
            let sgv = model.sgvStringWithEmoji
            let tintString = model.sgvColor
            
            let delta = model.deltaString
            let deltaShort = model.deltaStringShort
            var raw =  ""
            var rawShort = ""
            
            if model.rawVisible {
                raw = model.rawString // only if available.
                rawShort = model.rawString
            }
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
            
            let entry = CLKComplicationTimelineEntry(date: NSDate(), complicationTemplate: template)
            handler(entry)
        } else {
            handler(nil)
        }
    }
    
    
    func getTimelineEntriesForComplication(complication: CLKComplication, beforeDate date: NSDate, limit: Int, withHandler handler: (([CLKComplicationTimelineEntry]?) -> Void)) {
        // Call the handler with the timeline entries prior to the given date
        handler(nil)
    }
    
    func getTimelineEntriesForComplication(complication: CLKComplication, afterDate date: NSDate, limit: Int, withHandler handler: (([CLKComplicationTimelineEntry]?) -> Void)) {
        // Call the handler with the timeline entries after to the given date
        handler([])
    }
    
    // MARK: - Update Scheduling
    
    func getNextRequestedUpdateDateWithHandler(handler: (NSDate?) -> Void) {
        // Call the handler with the date when you would next like to be given the opportunity to update your complication content
        handler(requestedUpdateDate);
    }
    
    func requestedUpdateDidBegin() {
        #if DEBUG
            print(">>> Entering \(__FUNCTION__) <<<")
        #endif
        
        let complicationServer = CLKComplicationServer.sharedInstance()
        for complication in complicationServer.activeComplications {
            complicationServer.reloadTimelineForComplication(complication)
        }
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
    
    
    //
    // MARK: - DataSourceChangedDelegate
    
    func dataSourceDidUpdateAppContext(models: [WatchModel]) {
        #if DEBUG
            print(">>> Entering \(__FUNCTION__) <<<")
        #endif
    }
    
    
    
    func dataSourceDidUpdateSiteModel(model: WatchModel, atIndex index: Int) {
        #if DEBUG
            print(">>> Entering \(__FUNCTION__) <<<")
        #endif
        
        if (index == 0) {
            watchData = model
        }
        
        let complicationServer = CLKComplicationServer.sharedInstance()
        for complication in complicationServer.activeComplications {
            complicationServer.reloadTimelineForComplication(complication)
        }
    }
    
    func dataSourceDidAddSiteModel(model: WatchModel, atIndex index: Int) {
        
        #if DEBUG
            print(">>> Entering \(__FUNCTION__) <<<")
        #endif
        
    }
    
    func dataSourceDidDeleteSiteModel(model: WatchModel, atIndex index: Int) {
        #if DEBUG
            print(">>> Entering \(__FUNCTION__) <<<")
        #endif
    }
    
    
}
