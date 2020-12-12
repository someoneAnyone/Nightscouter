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
    
//    override init() {
//        super.init()
////        NotificationCenter.default.addObserver(forName: .NightscoutDataUpdatedNotification, object: nil, queue: OperationQueue.main) { (notif) in
//            // ComplicationController.reloadComplications()
//       // }
//    }
    
    open func getSupportedTimeTravelDirections(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimeTravelDirections) -> Void) {
        handler([.backward])
    }
    
    open func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        getTimelineEntries(for: complication, before: Date(), limit: 1) { (timelineEntries) in
            handler(timelineEntries?.first)
        }
    }
    
    func getTimelineStartDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        var date: Date?
        let model = SitesDataSource.sharedInstance.primarySite?.oldestComplicationData
        date = model?.date
        
        handler(date)
    }
    
    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        var date: Date?
        let model = SitesDataSource.sharedInstance.primarySite?.latestComplicationData
        date = model?.date
        
        handler(date)
    }
    
    func getNextRequestedUpdateDate(handler: @escaping (Date?) -> Void) {
        // Call the handler with the date when you would next like to be given the opportunity to update your complication content
        let nextUpdate = SitesDataSource.sharedInstance.primarySite?.nextRequestedComplicationUpdateDate
        
        #if DEBUG
            print("Next Requested Update Date is:\(String(describing: nextUpdate))")
        #endif
        
        handler(nextUpdate)
    }
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.showOnLockScreen)
    }
    
    func getTimelineEntries(for complication: CLKComplication, before date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        var timelineEntries = [CLKComplicationTimelineEntry]()

        let entries = SitesDataSource.sharedInstance.primarySite?.complicationTimeline ?? []
        
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
    
    func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        var timelineEntries = [CLKComplicationTimelineEntry]()
        
        let entries = SitesDataSource.sharedInstance.primarySite?.complicationTimeline ?? []
        
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
    
    
    // MARK: - Placeholder Templates

    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {

        getPlaceholderTemplate(for: complication, withHandler: handler)
    }

    func getPlaceholderTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        
        // This method will be called once per supported complication, and the results will be cached
        
        var template: CLKComplicationTemplate? = nil
        
        let utilLargeSting = PlaceHolderStrings.sgv + " " + PlaceHolderStrings.delta + " " + PlaceHolderStrings.raw
        
        switch complication.family {    
        case .modularSmall:
            let modularSmall = CLKComplicationTemplateModularSmallStackText()
            modularSmall.line1TextProvider = CLKSimpleTextProvider(text: PlaceHolderStrings.sgv)
            modularSmall.line2TextProvider = CLKSimpleTextProvider(text: PlaceHolderStrings.delta)
            
            template = modularSmall
        case .modularLarge:
            let modularLarge = CLKComplicationTemplateModularLargeTable()
            
            modularLarge.headerTextProvider = CLKSimpleTextProvider(text: PlaceHolderStrings.appName)
            modularLarge.row1Column1TextProvider = CLKSimpleTextProvider(text: PlaceHolderStrings.delta)
            modularLarge.row1Column2TextProvider = CLKSimpleTextProvider(text: PlaceHolderStrings.date)//CLKRelativeDateTextProvider(date: NSDate(), style: .Offset, units: [.Minute, .Hour, .Day])
            modularLarge.row2Column1TextProvider = CLKSimpleTextProvider(text: PlaceHolderStrings.raw)
            modularLarge.row2Column2TextProvider = CLKSimpleTextProvider(text: "")
            
            template = modularLarge
            
        case .extraLarge:
            let extraLarge = CLKComplicationTemplateExtraLargeStackText()
            
            extraLarge.line1TextProvider = CLKSimpleTextProvider(text: PlaceHolderStrings.sgv)
            extraLarge.line2TextProvider = CLKSimpleTextProvider(text: PlaceHolderStrings.delta)//CLKRelativeDateTextProvider(date: NSDate(), style: .Offset, units: [.Minute, .Hour, .Day])
            template = extraLarge
            
        case .utilitarianSmall, .utilitarianSmallFlat:
            let utilitarianSmall = CLKComplicationTemplateUtilitarianSmallFlat()
            utilitarianSmall.textProvider = CLKSimpleTextProvider(text: PlaceHolderStrings.sgv)
            
            template = utilitarianSmall
        case .utilitarianLarge:
            let utilitarianLarge = CLKComplicationTemplateUtilitarianLargeFlat()
            utilitarianLarge.textProvider = CLKSimpleTextProvider(text: utilLargeSting)
            
            template = utilitarianLarge
        case .circularSmall:
            let circularSmall = CLKComplicationTemplateCircularSmallStackText()
            circularSmall.line1TextProvider = CLKSimpleTextProvider(text: PlaceHolderStrings.sgv)
            circularSmall.line2TextProvider = CLKSimpleTextProvider(text: PlaceHolderStrings.delta)
            
            template = circularSmall
        
        default:
            template = nil
        }
        
        handler(template)
    }
}

extension ComplicationController {
    
    // MARK: Create Complication Templates
    
    func templateForComplication(_ complication: CLKComplication, model: ComplicationTimelineEntry) -> CLKComplicationTemplate? {
        #if DEBUG
            print(">>> Entering \(#function) <<<")
        #endif
        
        var template: CLKComplicationTemplate? = nil
        
        let displayName = model.nameLabel
        let sgv = model.sgvLabel + " " + model.direction.emojiForDirection
        var sgvShort = sgv
        
        let tintColor = model.sgvColor
        let delta = model.deltaLabel
        let deltaShort = model.deltaShort
        let raw = !model.rawHidden ? model.rawFormatedLabel : ""
        let rawShort = !model.rawHidden ? model.rawFormatedLabelShort : ""
        
        let utilLargeSting = sgv + " " + delta + " " + raw
        let utilLargeStingShort = sgv + " " + deltaShort + " " + raw
        
        switch sgv {
        case "Warning":
            sgvShort = "!!"
        case "Urgent":
            sgvShort = "!!!"
        default:
            break
        }
        
        switch complication.family {
        case .modularSmall:
            let modularSmall = CLKComplicationTemplateModularSmallStackText()
            modularSmall.line1TextProvider = CLKSimpleTextProvider(text: sgv)
            modularSmall.line2TextProvider = CLKSimpleTextProvider(text: delta, shortText: deltaShort)
            modularSmall.tintColor = tintColor
            
            // Set the template
            template = modularSmall
        case .modularLarge:
            let modularLarge = CLKComplicationTemplateModularLargeTable()
            modularLarge.headerTextProvider = CLKSimpleTextProvider(text: sgv + " " + delta , shortText: sgv + " " + deltaShort)
            modularLarge.row1Column1TextProvider = CLKSimpleTextProvider(text: displayName)
            modularLarge.row1Column2TextProvider = CLKRelativeDateTextProvider(date: model.date, style: .natural, units: [.minute, .hour, .day])
            modularLarge.row2Column1TextProvider = CLKSimpleTextProvider(text: raw, shortText: rawShort)
            modularLarge.row2Column2TextProvider = CLKSimpleTextProvider(text: "")
            modularLarge.tintColor = tintColor
            
            template = modularLarge
            
        case .extraLarge:
            let extraLarge = CLKComplicationTemplateExtraLargeStackText()
            
            extraLarge.line1TextProvider =  CLKSimpleTextProvider(text: sgv, shortText: sgvShort)
            extraLarge.line2TextProvider = CLKSimpleTextProvider(text: delta, shortText: deltaShort)
            
            template = extraLarge
            
            
        case .utilitarianSmall, .utilitarianSmallFlat:
            let utilitarianSmall = CLKComplicationTemplateUtilitarianSmallFlat()
            utilitarianSmall.textProvider = CLKSimpleTextProvider(text: sgv, shortText: sgvShort)
            
            template = utilitarianSmall
        case .utilitarianLarge:
            let utilitarianLarge = CLKComplicationTemplateUtilitarianLargeFlat()
            utilitarianLarge.textProvider = CLKSimpleTextProvider(text: utilLargeSting, shortText: utilLargeStingShort)
            utilitarianLarge.tintColor = tintColor
            
            template = utilitarianLarge
            
        case .circularSmall:
            let circularSmall = CLKComplicationTemplateCircularSmallStackText()
            circularSmall.line1TextProvider = CLKSimpleTextProvider(text: sgv, shortText: sgvShort)
            circularSmall.line2TextProvider = CLKSimpleTextProvider(text: delta, shortText: deltaShort)
            circularSmall.tintColor = tintColor
            
            template = circularSmall
        default:
            template = nil
        }
        
        return template
    }
    
}

extension ComplicationController {
    
    
    func requestedUpdateDidBegin() {
        #if DEBUG
            print(">>> Entering \(#function) <<<")
        #endif
        
        // TODO: Start up connecitivty session ask for data from data source. and update.
        // Ask data store for new data..
        SitesDataSource.sharedInstance.primarySite?.generateComplicationData()
        ComplicationController.reloadComplications()
    }
    
    func requestedUpdateBudgetExhausted() {
        #if DEBUG
            print(">>> Entering \(#function) <<<")
        #endif
        // TODO: Start up connecitivty session ask for data from data source. and update. Also bookmark when this happened. Maybe add a new timeline entry informing the user.
        // Ask data store for new data.. log when this happened.
    }
    
    static func reloadComplications() {
        #if DEBUG
            print(">>> Entering \(#function) <<<")
        #endif
        
        let complicationServer = CLKComplicationServer.sharedInstance()
        if let activeComplications = complicationServer.activeComplications {
            for complication in activeComplications {
                complicationServer.reloadTimeline(for: complication)
            }
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
}
