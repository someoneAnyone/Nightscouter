//
//  File.swift
//  Nightscouter
//
//  Created by Peter Ina on 11/10/15.
//  Copyright © 2015 Peter Ina. All rights reserved.
//

import UIKit

public enum WatchAction: String {
    case Create, Read, Update, Delete, AppContext, UserInfo, UpdateComplication
}

public func ==(lhs: WatchModel, rhs: WatchModel) -> Bool {
    // return lhs.urlString == rhs.urlString && lhs.displayName == rhs.displayName && lhs.lastReadingDate == rhs.lastReadingDate //lhs.uuid == rhs.uuid //
    return lhs.uuid == rhs.uuid
}

// TODO: Locallize these strings and move them to centeral location so all view can have consistent placeholder text.
public struct PlaceHolderStrings {
    public static let displayName: String = "----"
    public static let sgv: String = "---"
    public static let date: String = "-- --- --"
    public static let delta: String = "- --/--"
    public static let deltaShort: String = "-"
    public static let raw: String = "--- : ---"
    public static let rawShort: String = "--- : -"
    public static let battery: String = "--%"
    public static let units: String = "--"
    public static let defaultColor: String = "#d9d9d9"
}

public struct WatchModel: DictionaryConvertible, Equatable {
    
    public struct PropertyKey {
        public static let contextKey = "context"
        public static let actionKey = "action"
        public static let modelKey = "siteModel"
        public static let modelsKey = "siteModels"
        public static let delegateKey = "delegate"
        public static let currentIndexKey = "currentIndex"
    }
    
    public let uuid: String
    
    public let urlString: String
    public let displayUrlString: String
    
    // Holds the friendly site name.
    public let displayName: String
    
    // 3 mins ago... if things get stale then the color will change. Stale timer is based by the server's configuratiojn.
    public let lastReadingDate: NSDate
    public let lastReadingColor: String
    
    // Battery in precentage, for example 1% - 100%. Will change color once below 20%.
    public let batteryString: String
    public let batteryColor: String
    
    // Flag for displaying RAW data section of the UI. Visibility is determined by server confirguration and availbilty of RAW data.
    public let rawVisible: Bool
    public let rawString: String
    public let rawColor: String
    
    // Main glucouse reading. Color coded based on server provided thresholds.
    public let sgvString: String
    public let sgvEmoji: String
    public let sgvStringWithEmoji: String
    public let sgvColor: String
    
    // Delta between readings. Provided by the server. Color coded based on server provided thresholds.
    public let deltaString: String
    public let deltaStringShort: String
    public let delta: Double
    public let units: String
    
    public let deltaColor: String
    
    // Used for configuring the Compass image.
    public let isArrowVisible : Bool
    public let isDoubleUp : Bool
    public let angle: CGFloat
    public private(set) var direction: String
    
    // Is data stale? Find out with this flags.
    public let urgent: Bool
    public let warn: Bool
    
    public init?(fromDictionary: [String : AnyObject]) {
        
        let d = fromDictionary
        self.urlString = d["urlString"] as! String
        self.displayUrlString = d["displayUrlString"] as! String
        
        self.urgent = d["urgent"] as! Bool
        self.warn = d["warn"] as! Bool
        
        self.displayName = d["displayName"] as! String
        
        self.lastReadingDate = d["lastReadingDate"] as! NSDate
        
        self.lastReadingColor = d["lastReadingColor"] as! String
        
        self.batteryColor = d["batteryColor"] as! String
        self.batteryString = d["batteryString"] as! String
        
        self.rawVisible =  d["rawVisible"] as! Bool
        self.rawString = d["rawString"] as! String
        self.rawColor =  d["rawColor"] as! String
        
        self.sgvString = d["sgvString"] as! String
        self.sgvEmoji = d["sgvEmoji"] as! String
        self.sgvStringWithEmoji = d["sgvStringWithEmoji"] as! String
        self.sgvColor = d["sgvColor"] as! String
        
        self.deltaString = d["deltaString"] as! String
        self.deltaStringShort = d["deltaStringShort"] as! String
        self.delta = d["delta"] as! Double
        self.units = d["units"] as! String
        
        self.deltaColor = d["deltaColor"] as! String
        
        self.isArrowVisible =  d["isArrowVisible"] as! Bool
        self.isDoubleUp = d["isDoubleUp"] as! Bool
        self.angle = d["angle"] as! CGFloat
        self.direction = d["direction"] as! String
        
        self.uuid = d["uuid"] as! String
        
    }
    
    public init(fromSite site: Site) {
        #if DEBUG
            print(">>> Entering \(__FUNCTION__) <<<")
        #endif
        
        // Make sure we've got data in the site before proceeding otherwise fail the init.
        if let configuration = site.configuration, watchEntry = site.watchEntry, sgvValue = watchEntry.sgv {
            
            // Get prefered Units. mmol/L or mg/dL
            let units: Units = configuration.displayUnits
            
            // Custom name or Nightscout
            let displayName: String = configuration.displayName
            let displayUrlString = site.url.host ?? site.url.absoluteString
            
            // Calculate if the lastest watch entry we got from the server is stale.
            let timeAgo = watchEntry.date.timeIntervalSinceNow
            let isStaleData = configuration.isDataStaleWith(interval: timeAgo)
            
            // Get theme color for normal text should look like.
            let defaultTextColor = colorForDesiredColorState(.Neutral)
            
            var sgvString: String = ""
            var sgvEmoji: String = ""
            var sgvStringWithEmoji : String = ""
            var sgvColor: UIColor = defaultTextColor
            
            var deltaString: String = ""
            var deltaStringShort: String = ""
            
            var isRawDataAvailable: Bool = false
            var rawString: String = ""
            var rawColor: UIColor = defaultTextColor
            
            var batteryString: String = watchEntry.batteryString
            var batteryColor: UIColor = colorForDesiredColorState(watchEntry.batteryColorState)
            var lastUpdatedColor: UIColor = defaultTextColor
            
            // Convert units.
            var boundedColor = configuration.boundedColorForGlucoseValue(sgvValue.sgv)
            if units == .Mmol {
                boundedColor = configuration.boundedColorForGlucoseValue(sgvValue.sgv.toMgdl)
            }
            
            sgvString =  "\(sgvValue.sgvString(forUnits: units))"
            sgvEmoji = "\(sgvValue.direction.emojiForDirection)"
            sgvStringWithEmoji = "\(sgvString) \(sgvValue.direction.emojiForDirection)"
            
            deltaString = watchEntry.bgdelta.formattedBGDelta(forUnits: units) //"\(watchEntry.bgdelta.formattedForBGDelta) \(units.description)"
            deltaStringShort = "\(watchEntry.bgdelta.formattedBGDelta(forUnits: units, appendString: "∆"))"
            
            sgvColor = colorForDesiredColorState(boundedColor)
            
            isRawDataAvailable = configuration.displayRawData
            
            var isArrowVisible = true
            var isDoubleUp = false
            var angle: CGFloat = 0
            
            self.direction = sgvValue.direction.description
            
            switch sgvValue.direction {
            case .None:
                isArrowVisible = false
            case .DoubleUp:
                isDoubleUp = true
            case .SingleUp:
                break
            case .FortyFiveUp:
                angle = -45
            case .Flat:
                angle = -90
            case .FortyFiveDown:
                angle = -120
            case .SingleDown:
                angle = -180
            case .DoubleDown:
                isDoubleUp = true
                angle = -180
            case .NotComputable, .Not_Computable:
                isArrowVisible = false
            case .RateOutOfRange:
                isArrowVisible = false
            }
            
            if isRawDataAvailable {
                if let rawValue = watchEntry.raw {
                    rawColor = colorForDesiredColorState(configuration.boundedColorForGlucoseValue(rawValue))
                    
                    var raw = "\(rawValue.formattedForMgdl)"
                    if configuration.displayUnits == .Mmol {
                        raw = rawValue.formattedForMmol
                    }
                    
                    rawString = "\(raw) : \(sgvValue.noise.description)"
                }
            }
            
            if isStaleData.warn {
                batteryString = PlaceHolderStrings.battery
                batteryColor = defaultTextColor
                
                rawString = PlaceHolderStrings.raw
                rawColor = defaultTextColor
                
                deltaString = PlaceHolderStrings.delta
                deltaStringShort = PlaceHolderStrings.delta
                
                sgvString = PlaceHolderStrings.sgv
                sgvStringWithEmoji = sgvString
                sgvEmoji = sgvString
                
                sgvColor = colorForDesiredColorState(.Neutral)
                
                isArrowVisible = false
                
                lastUpdatedColor = colorForDesiredColorState(.Warning)
            }
            
            if isStaleData.urgent{
                lastUpdatedColor = colorForDesiredColorState(.Alert)
            }
            
            self.urlString = site.url.absoluteString
            self.displayUrlString = displayUrlString
            self.uuid = site.uuid.UUIDString
            
            self.urgent = isStaleData.urgent
            self.warn = isStaleData.warn
            
            self.displayName = displayName
            
            self.lastReadingDate = watchEntry.date
            
            self.lastReadingColor = lastUpdatedColor.toHexString()
            
            self.batteryColor = batteryColor.toHexString()
            self.batteryString = batteryString
            
            self.rawVisible = isRawDataAvailable
            self.rawString = rawString
            self.rawColor = rawColor.toHexString()
            
            self.sgvString = sgvString
            self.sgvEmoji = sgvEmoji
            self.sgvStringWithEmoji = sgvStringWithEmoji
            self.sgvColor = sgvColor.toHexString()
            
            self.deltaString = deltaString
            self.deltaStringShort = deltaStringShort
            self.deltaColor = sgvColor.toHexString()
            
            self.delta = watchEntry.bgdelta
            self.units = configuration.displayUnits.description
            
            self.isArrowVisible = isArrowVisible
            self.isDoubleUp = isDoubleUp
            self.angle = angle
            
        } else {
            
            self.urlString = site.url.absoluteString
            self.displayUrlString = site.url.host ?? site.url.absoluteString
            self.uuid = site.uuid.UUIDString
            
            self.displayName = PlaceHolderStrings.displayName
            
            self.urgent = false
            self.warn = false
            
            self.lastReadingDate = NSDate()
            
            self.lastReadingColor = PlaceHolderStrings.defaultColor
            
            self.batteryColor = PlaceHolderStrings.defaultColor
            self.batteryString = PlaceHolderStrings.battery
            
            self.rawVisible = true
            self.rawString = PlaceHolderStrings.raw
            self.rawColor = PlaceHolderStrings.defaultColor
            
            self.sgvString = PlaceHolderStrings.sgv
            self.sgvEmoji = PlaceHolderStrings.sgv
            self.sgvStringWithEmoji = PlaceHolderStrings.sgv
            self.sgvColor = PlaceHolderStrings.defaultColor
            
            self.deltaString = PlaceHolderStrings.delta
            self.deltaStringShort = PlaceHolderStrings.delta
            self.deltaColor = PlaceHolderStrings.defaultColor
            
            self.delta = Double.infinity
            self.units = PlaceHolderStrings.units
            
            self.isArrowVisible = false
            self.isDoubleUp = false
            self.angle = 0
            
            self.direction = Direction.None.description
        }
    }
    
    func generateSite() -> Site {
        let url = NSURL(string: urlString)!
        return Site(url: url, apiSecret: nil, uuid: NSUUID(UUIDString: self.uuid)!)!
    }
}
