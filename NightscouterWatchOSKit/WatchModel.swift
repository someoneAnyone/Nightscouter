//
//  File.swift
//  Nightscouter
//
//  Created by Peter Ina on 11/10/15.
//  Copyright © 2015 Peter Ina. All rights reserved.
//

import Foundation


public struct WatchModel {
   public let displayName: String
    
   public let lastReadingString: String
      public let lastReadingColor: UIColor
    
       public let batteryString: String
       public let batteryColor: UIColor
    
       public let rawVisible: Bool
       public let rawString: String
       public let rawColor: UIColor
    
       public let sgvString: String
       public let sgvColor: UIColor
    
       public let deltaString: String
       public let deltaColor: UIColor
    
       public let isArrowVisible : Bool
       public let isDoubleUp : Bool
       public let angle: CGFloat
       public let urgent: Bool
       public let warn: Bool
    
       public init?(fromSite site: Site) {
        
        print(">>> Entering \(__FUNCTION__) <<<")
        
        
        guard let configuration = site.configuration, watchEntry = site.watchEntry else {
            #if DEBUG
                print("No configuration was found bailing out...")
            #endif
            return nil
        }
        
        let units: Units = configuration.displayUnits
        
        let displayName: String = configuration.displayName
        
        let timeAgo = watchEntry.date.timeIntervalSinceNow
        let isStaleData = configuration.isDataStaleWith(interval: timeAgo)
        
        guard let sgvValue = watchEntry.sgv  else {
            #if DEBUG
                println("No SGV was found in the watch")
            #endif
            
            self.displayName = displayName
            
            return nil
        }
        
        let defaultTextColor = NSAssetKitWatchOS.predefinedNeutralColor
        
        var sgvString: String = ""
        var sgvColor: UIColor = defaultTextColor
        
        var deltaString: String = ""
        
        var isRawDataAvailable: Bool = false
        var rawString: String = ""
        var rawColor: UIColor = defaultTextColor
        
        var batteryString: String = watchEntry.batteryString
        var batteryColor: UIColor = colorForDesiredColorState(watchEntry.batteryColorState)
        var lastUpdatedColor: UIColor = defaultTextColor
        
        var boundedColor = configuration.boundedColorForGlucoseValue(sgvValue.sgv)
        if units == .Mmol {
            boundedColor = configuration.boundedColorForGlucoseValue(sgvValue.sgv.toMgdl)
        }
        
        sgvString =  "\(sgvValue.sgvString) \(sgvValue.direction.emojiForDirection)"
        deltaString = "\(watchEntry.bgdelta.formattedForBGDelta) \(units.descriptionShort)"
        sgvColor = colorForDesiredColorState(boundedColor)
        
        isRawDataAvailable = configuration.displayRawData
        
        var isArrowVisible = true
        var isDoubleUp = false
        var angle: CGFloat = 0
        
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
        case .NotComputable:
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
                
                rawString = "\(raw) : \(sgvValue.noise.descriptionShort)"
            }
        }
        
        
        
        
        if isStaleData.warn {
            batteryString = ("---%")
            batteryColor = defaultTextColor
            
            rawString = "--- : ---"
            rawColor = defaultTextColor
            
            deltaString = "- --/--"
            
            sgvString = "---"
            sgvColor = colorForDesiredColorState(.Neutral)
            
            isArrowVisible = false
            
        }
        
        if isStaleData.urgent{
            lastUpdatedColor = NSAssetKitWatchOS.predefinedAlertColor
            
        }
        
        
        
        self.urgent = isStaleData.urgent
        self.warn = isStaleData.warn
        
        self.displayName = displayName
        
        self.lastReadingString = watchEntry.dateTimeAgoStringShort
        self.lastReadingColor = lastUpdatedColor
        
        self.batteryColor = batteryColor
        self.batteryString = batteryString
        
        self.rawVisible = !isRawDataAvailable
        self.rawString = rawString
        self.rawColor = rawColor
        
        self.sgvString = sgvString
        self.sgvColor = sgvColor
        
        self.deltaString = deltaString
        self.deltaColor = sgvColor
        
        self.isArrowVisible = isArrowVisible
        self.isDoubleUp = isDoubleUp
        self.angle = angle
    }
}


public func colorForDesiredColorState(desiredState: DesiredColorState) -> UIColor {
    switch (desiredState) {
    case .Neutral:
        return NSAssetKitWatchOS.predefinedNeutralColor
    case .Alert:
        return NSAssetKitWatchOS.predefinedAlertColor
    case .Positive:
        return NSAssetKitWatchOS.predefinedPostiveColor
    case .Warning:
        return NSAssetKitWatchOS.predefinedWarningColor
    }
}
