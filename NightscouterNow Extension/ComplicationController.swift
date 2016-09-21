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
    public func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        
    }

    public func getSupportedTimeTravelDirections(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimeTravelDirections) -> Void) {
    }
    
//, DataSourceChangedDelegate {
    /*
    override init() {
        super.init()

        WatchSessionManager.sharedManager.addDataSourceChangedDelegate(self)
        
        NotificationCenter.default.addObserver(self, selector: #selector(dataDidChange(_:)), name: NSNotification.Name(rawValue: AppDataManagerDidChangeNotification), object: nil)
    }
    
    func dataSourceCouldNotConnectToPhone(_ error: Error) {
        print(error)
    }

    func dataSourceDidUpdateAppContext(_ models: [WatchModel]) {
        ComplicationController.reloadComplications()
    }
    
    func dataDidChange(_ notif:Notification) {
        print(#function)
        print(notif)
        ComplicationController.reloadComplications()
    }
    
    // MARK: - Timeline Configuration
    
    func getSupportedTimeTravelDirections(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimeTravelDirections) -> Void) {
        handler([.backward])
    }
    
    func getTimelineStartDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        #if DEBUG
            // print(">>> Entering \(#function) <<<")
        #endif
        var date: Date?
        let model = WatchSessionManager.sharedManager.complicationData.last
        date = model?.date
        
        #if DEBUG
            // print("getTimelineStartDateForComplication:\(date)")
        #endif
        
        handler(date)
    }
    
    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        #if DEBUG
            // print(">>> Entering \(#function) <<<")
        #endif
        var date: Date?
        
        let model = WatchSessionManager.sharedManager.complicationData.first
        date = model?.date
        
        #if DEBUG
            // print("getTimelineEndDateForComplication:\(date)")
        #endif
        handler(date)
    }
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.showOnLockScreen)
    }
    
    // MARK: - Timeline Population
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: (@escaping (CLKComplicationTimelineEntry?) -> Void)) {
        // Call the handler with the current timeline entry
        #if DEBUG
            // print(">>> Entering \(#function) <<<")
        #endif
        
        getTimelineEntries(for: complication, before: Date(), limit: 1) { (timelineEntries) -> Void in
            handler(timelineEntries?.first)
        }
    }
    
    func getTimelineEntries(for complication: CLKComplication, before date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        // Call the handler with the timeline entries prior to the given date
        #if DEBUG
            // print(">>> Entering \(#function) <<<")
            // print("complication: \(complication.family)")
        #endif
        
        var timelineEntries = [CLKComplicationTimelineEntry]()
        
        let entries = WatchSessionManager.sharedManager.complicationData
        
        for entry in entries {
            let entryDate = entry.date
            if date.compare(entryDate) == .orderedDescending {
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
    
    func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int, withHandler handler: (@escaping ([CLKComplicationTimelineEntry]?) -> Void)) {
        // Call the handler with the timeline entries after to the given date
        #if DEBUG
            // print(">>> Entering \(#function) <<<")
        #endif
        
        var timelineEntries = [CLKComplicationTimelineEntry]()
        
        let entries = WatchSessionManager.sharedManager.complicationData
        
        for entry in entries {
            let entryDate = entry.date
            if date.compare(entryDate) == .orderedAscending {
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
    
    func getNextRequestedUpdateDate(handler: @escaping (Date?) -> Void) {
        // Call the handler with the date when you would next like to be given the opportunity to update your complication content
        #if DEBUG
            print(">>> Entering \(#function) <<<")
        #endif
        
        let nextUpdate = WatchSessionManager.sharedManager.nextRequestedComplicationUpdateDate
        
        #if DEBUG
            print("Next Requested Update Date is:\(nextUpdate)")
        #endif
        
        handler(nextUpdate as Date)
    }
    
    static func reloadComplications() {
        #if DEBUG
            print(">>> Entering \(#function) <<<")
        #endif
             
        let lastReloadDate = WatchSessionManager.sharedManager.lastReloadDate
        
        // Get the date of last complication timeline entry.
        let lastModelUpdate = WatchSessionManager.sharedManager.complicationData.first?.date ?? Date(timeIntervalSince1970: 0)
        // Get the date of the last reload of the complication timeline.
        
        if lastReloadDate.compare(lastModelUpdate) != .orderedSame {
            print(">>> Actually Updating \(#function) <<<")
            let complicationServer = CLKComplicationServer.sharedInstance()
            // Possible iOS Bug. Sometimes the CLKComplicationServer.sharedInstance() returns a nil object.
            if let activeComplications = complicationServer.activeComplications {
                for complication in activeComplications {
                    // Reload the timeline.
                    complicationServer.reloadTimeline(for: complication)
                    // Set the complication model's date to defaults.
                    WatchSessionManager.sharedManager.lastReloadDate = lastModelUpdate
                }
                
            }
        } else {
            print(">>> Not Updating \(#function) <<< because it was too soon. No new entries were found.")
        }
    }
    
    
    static func extendComplications() {
        #if DEBUG
            print(">>> Entering \(#function) <<<")
        #endif
        
        let complicationServer = CLKComplicationServer.sharedInstance()
        if let activeComplications = complicationServer.activeComplications {
            for complication in activeComplications {
                complicationServer.extendTimeline(for: complication)
            }
        }
    }
    func requestedUpdateDidBegin() {
        #if DEBUG
            print(">>> Entering \(#function) <<<")
        #endif
        WatchSessionManager.sharedManager.updateComplication { (timline) in
            //ComplicationController.reloadComplications()
        }
    }
    
    func requestedUpdateBudgetExhausted() {
        #if DEBUG
            print(">>> Entering \(#function) <<<")
        #endif
        
        WatchSessionManager.sharedManager.complicationRequestedUpdateBudgetExhausted()
    }
    
    // MARK: - Placeholder Templates
    
    func getPlaceholderTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        // This method will be called once per supported complication, and the results will be cached
        #if DEBUG
            // print(">>> Entering \(#function) <<<")
            // print("complication family: \(complication.family)")
        #endif
        
        var template: CLKComplicationTemplate
        
        let tintString = NSAssetKitWatchOS.appLogoTintColor.toHexString()
        
        let utilLargeSting = PlaceHolderStrings.sgv + " " + PlaceHolderStrings.delta + " " + PlaceHolderStrings.raw
        
        switch complication.family {
        case .modularSmall:
            let modularSmall = CLKComplicationTemplateModularSmallStackText()
            modularSmall.line1TextProvider = CLKSimpleTextProvider(text: PlaceHolderStrings.sgv)
            modularSmall.line2TextProvider = CLKSimpleTextProvider(text: PlaceHolderStrings.delta)
            modularSmall.tintColor = UIColor(hexString: tintString)
            
            // Set the template
            template = modularSmall
            
        case .modularLarge, .extraLarge: //, .ExtraLarge:
            let modularLarge = CLKComplicationTemplateModularLargeStandardBody()
            modularLarge.headerTextProvider = CLKSimpleTextProvider(text: "Nightscouter")
            modularLarge.body1TextProvider = CLKSimpleTextProvider(text: PlaceHolderStrings.delta)
            modularLarge.body2TextProvider = CLKSimpleTextProvider(text: PlaceHolderStrings.raw)
            modularLarge.tintColor = UIColor(hexString: tintString)
            
            // Set the template
            template = modularLarge

        case .utilitarianSmall, .utilitarianSmallFlat: //, .UtilitarianSmallFlat:
            let utilitarianSmall = CLKComplicationTemplateUtilitarianSmallFlat()
            utilitarianSmall.textProvider = CLKSimpleTextProvider(text: PlaceHolderStrings.sgv)
            
            // Set the template
            template = utilitarianSmall
        case .utilitarianLarge:
            let utilitarianLarge = CLKComplicationTemplateUtilitarianLargeFlat()
            utilitarianLarge.textProvider = CLKSimpleTextProvider(text: utilLargeSting)
            
            // Set the template
            template = utilitarianLarge
        case .circularSmall:
            let circularSmall = CLKComplicationTemplateCircularSmallStackText()
            circularSmall.line1TextProvider = CLKSimpleTextProvider(text: PlaceHolderStrings.sgv)
            circularSmall.line2TextProvider = CLKSimpleTextProvider(text: PlaceHolderStrings.delta)
            
            // Set the template
            template = circularSmall
        }
        
        handler(template)
    }
    
    // MARK: Create Complication Templates
    
    fileprivate func templateForComplication(_ complication: CLKComplication, model: ComplicationModel) -> CLKComplicationTemplate? {
        #if DEBUG
            // print(">>> Entering \(#function) <<<")
        #endif
        
        var template: CLKComplicationTemplate
        
        let displayName = model.displayName
        let sgv = model.sgv
        let tintString = model.tintString
        let delta = model.delta
        let deltaShort = model.deltaShort
        var raw = PlaceHolderStrings.rawShort
        var rawShort = PlaceHolderStrings.rawShort
        
        if let rawLong = model.raw, let rawShor = model.rawShort {
            raw = rawLong // only if available.
            rawShort = rawShor
        }
        
        let utilLargeSting = sgv + " " + delta + " " + raw
        let utilLargeStingShort = sgv + " " + deltaShort + " " + rawShort
        
        switch complication.family {
        case .modularSmall:
            let modularSmall = CLKComplicationTemplateModularSmallStackText()
            modularSmall.line1TextProvider = CLKSimpleTextProvider(text: sgv)
            modularSmall.line2TextProvider = CLKSimpleTextProvider(text: delta, shortText: deltaShort)
            modularSmall.tintColor = UIColor(hexString: tintString)
            
            // Set the template
            template = modularSmall
        case .modularLarge, .extraLarge: //, .ExtraLarge:
            let modularLarge = CLKComplicationTemplateModularLargeTable()
            modularLarge.headerTextProvider = CLKSimpleTextProvider(text: sgv + " " + delta, shortText: sgv + " " + deltaShort)
            modularLarge.row1Column1TextProvider = CLKSimpleTextProvider(text: displayName)
            modularLarge.row1Column2TextProvider = CLKRelativeDateTextProvider(date: model.date, style: .natural, units: [.minute, .hour, .day])
            modularLarge.row2Column1TextProvider = CLKSimpleTextProvider(text:  raw, shortText: rawShort)
            modularLarge.row2Column2TextProvider = CLKSimpleTextProvider(text: "")
            
            modularLarge.tintColor = UIColor(hexString: tintString)
            // Set the template
            template = modularLarge
            
        case .utilitarianSmall, .utilitarianSmallFlat: //, .UtilitarianSmallFlat:
            let utilitarianSmall = CLKComplicationTemplateUtilitarianSmallFlat()
            utilitarianSmall.textProvider = CLKSimpleTextProvider(text: sgv)
            
            // Set the template
            template = utilitarianSmall
        case .utilitarianLarge:
            let utilitarianLarge = CLKComplicationTemplateUtilitarianLargeFlat()
            utilitarianLarge.textProvider = CLKSimpleTextProvider(text: utilLargeSting, shortText: utilLargeStingShort)
            utilitarianLarge.tintColor = UIColor(hexString: tintString)
            
            // Set the template
            template = utilitarianLarge
        case .circularSmall:
            let circularSmall = CLKComplicationTemplateCircularSmallStackText()
            circularSmall.line1TextProvider = CLKSimpleTextProvider(text: sgv)
            circularSmall.line2TextProvider = CLKSimpleTextProvider(text: delta, shortText: deltaShort)
            circularSmall.tintColor = UIColor(hexString: tintString)
            
            // Set the template
            template = circularSmall

        }
        
        return template
    }
*/
}
