//
//  SensorGlucoseValues.swift
//  Nightscouter
//
//  Created by Peter Ina on 10/6/15.
//  Copyright © 2015 Peter Ina. All rights reserved.
//

import Foundation

public enum Direction : String, CustomStringConvertible {
    case None = "None", DoubleUp = "DoubleUp", SingleUp = "SingleUp", FortyFiveUp = "FortyFiveUp", Flat = "Flat", FortyFiveDown = "FortyFiveDown", SingleDown = "SingleDown", DoubleDown = "DoubleDown", NotComputable = "NOT COMPUTABLE", RateOutOfRange = "RateOutOfRange", Not_Computable = "NOT_COMPUTABLE"
    
    public static let allValues = [None, DoubleUp, SingleUp, FortyFiveUp, Flat, FortyFiveDown, SingleDown, DoubleDown, NotComputable, RateOutOfRange]
    
    public var description : String {
        switch(self) {
        case .None: return NSLocalizedString("directionNone", tableName: nil, bundle:  NSBundle.mainBundle(), value: "None", comment: "Label used to indicate a direction.")
        case .DoubleUp: return NSLocalizedString("directionDoubleUp", tableName: nil, bundle:  NSBundle.mainBundle(), value: "Double Up", comment: "Label used to indicate a direction.")
        case .SingleUp: return NSLocalizedString("directionSingleUp", tableName: nil, bundle:  NSBundle.mainBundle(), value: "Single Up", comment: "Label used to indicate a direction.")
        case .FortyFiveUp: return NSLocalizedString("directionFortyFiveUp", tableName: nil, bundle:  NSBundle.mainBundle(), value: "Forty Five Up", comment: "Label used to indicate a direction.")
        case .Flat: return NSLocalizedString("directionFlat", tableName: nil, bundle:  NSBundle.mainBundle(), value: "Flat", comment: "Label used to indicate a direction.")
        case .FortyFiveDown: return NSLocalizedString("directionFortyFiveDown", tableName: nil, bundle:  NSBundle.mainBundle(), value: "Forty Five Down", comment: "Label used to indicate a direction.")
        case .SingleDown: return NSLocalizedString("directionSingleDown", tableName: nil, bundle:  NSBundle.mainBundle(), value: "Single Down", comment: "Label used to indicate a direction.")
        case .DoubleDown: return NSLocalizedString("directionFortyDoubleDown", tableName: nil, bundle:  NSBundle.mainBundle(), value: "Double Down", comment: "Label used to indicate a direction.")
        case .NotComputable, .Not_Computable: return NSLocalizedString("directionNotComputable", tableName: nil, bundle:  NSBundle.mainBundle(), value: "N/C", comment: "Label used to indicate a direction.")
        case .RateOutOfRange: return NSLocalizedString("directionRateOutOfRange", tableName: nil, bundle:  NSBundle.mainBundle(), value: "Rate Out Of Range", comment: "Label used to indicate a direction.")

        }
    }
    
    public var emojiForDirection: String {
        get {
            switch (self) {
            case .None: return ""
            case .DoubleUp: return  "⇈"
            case .SingleUp: return "↑"
            case .FortyFiveUp: return  "➚"
            case .Flat: return "→"
            case .FortyFiveDown: return "➘"
            case .SingleDown: return "↓"
            case .DoubleDown: return  "⇊"
            case .NotComputable, .Not_Computable: return "-"
            case .RateOutOfRange: return "✕"
            }
        }
    }
    
   static public func directionForString(directionString: String) -> Direction {
        switch directionString {
        case "None": return .None
        case "DoubleUp": return .DoubleUp
        case "SingleUp": return .SingleUp
        case "FortyFiveUp": return .FortyFiveUp
        case "Flat": return .Flat
        case "FortyFiveDown": return .FortyFiveDown
        case "SingleDown": return .SingleDown
        case "DoubleDown": return .DoubleDown
        case "NOT COMPUTABLE", "NOT_COMPUTABLE": return .NotComputable
        case "RateOutOfRange": return .RateOutOfRange
        default: return .None
        }
    }
    
    public init() {
        self = .None
    }
}

public enum Noise : Int, CustomStringConvertible {
    case None = 0, Clean = 1, Light = 2, Medium = 3, Heavy = 4
    
    public var description: String {
        switch (self) {
        case .None: return NSLocalizedString("noiseNone", tableName: nil, bundle:  NSBundle.mainBundle(), value: "None", comment: "Label used to indicate a direction.")
        case .Clean: return NSLocalizedString("noiseClean", tableName: nil, bundle:  NSBundle.mainBundle(), value: "Clean", comment: "Label used to indicate a direction.")
        case .Light: return NSLocalizedString("noiseLight", tableName: nil, bundle:  NSBundle.mainBundle(), value: "Light", comment: "Label used to indicate a direction.")
        case .Medium: return NSLocalizedString("noiseMedium", tableName: nil, bundle:  NSBundle.mainBundle(), value: "Medium", comment: "Label used to indicate a direction.")
        case .Heavy: return NSLocalizedString("noiseHeavy", tableName: nil, bundle:  NSBundle.mainBundle(), value: "Heavy", comment: "Label used to indicate a direction.")
        }
    }
    
    public init() {
        self = .None
    }
}

public protocol GlucoseValueHolder {
    var sgv: Double { get set }
    var isSGVOk: Bool { get }
}

public extension GlucoseValueHolder {
    var isSGVOk: Bool {
        return sgv >= 13
    }
}

// type = Sgv
public struct SensorGlucoseValue: DictionaryConvertible, GlucoseValueHolder {
    public var sgv: Double
    public let direction: Direction
    public let filtered: Int
    public let unfiltered: Int
    public let rssi: Int
    public let noise: Noise
    
    enum ReservedValues: Double {
        case NoGlucose=0, SensoreNotActive=1, MinimalDeviation=2, NoAntenna=3, SensorNotCalibrated=5, CountsDeviation=6, AbsoluteDeviation=9, PowerDeviation=10, BadRF=12, HupHolland=17
    }
    
    
    public func sgvString(forUnits units: Units) -> String {
        
        let mgdlSgvValue: Double = (units == .Mgdl) ? sgv : sgv.toMgdl // If the units are set to mgd/L do nothing let it pass... if its mmol/L then convert it back to mgd/L to get its proper string.
        
        if let special:ReservedValues = ReservedValues(rawValue: mgdlSgvValue) {
            switch (special) {
            case .NoGlucose:
                return "?NC"
            case .SensoreNotActive:
                return "?NA"
            case .MinimalDeviation:
                return "?MD"
            case .NoAntenna:
                return "?NA"
            case .SensorNotCalibrated:
                return "?NC"
            case .CountsDeviation:
                return "?CD"
            case .AbsoluteDeviation:
                return "?AD"
            case .PowerDeviation:
                return "?PD"
            case .BadRF:
                return "?RF✖"
            case .HupHolland:
                return "MH"
            }
        }
        if sgv >= 30 && sgv < 40 {
            return  NSLocalizedString("sgvLowString", tableName: nil, bundle:  NSBundle.mainBundle(), value: "Low", comment: "Label used to indicate a very low blood sugar.")
        }
        return NSNumberFormatter.localizedStringFromNumber(sgv, numberStyle: NSNumberFormatterStyle.DecimalStyle)
    }
    
    @available(*, deprecated=1.0, message="Please use func func sgvString(forUnits units: Units) -> String")
    public var sgvString: String {
        get {
            return sgvString(forUnits: .Mgdl)
        }
    } // Returns string based on mg/dL. Not good don't use.
    
}

/// Raw data support. Requires a calibration.
public extension SensorGlucoseValue {
    public func rawIsigToRawBg(calValue: Calibration) -> Double {
        return rawIsigToRawBg(self, calValue: calValue)
    }
    
    internal func rawIsigToRawBg(sgValue: SensorGlucoseValue, calValue: Calibration) -> Double {
        
        var raw: Double = 0
        
        let unfiltered = Double(sgValue.unfiltered)
        let filtered = Double(sgValue.filtered)
        let sgv: Double = sgValue.sgv.isInteger ? sgValue.sgv : sgValue.sgv.toMgdl
        let slope = calValue.slope
        let scale = calValue.scale
        let intercept = calValue.intercept
        
        if (slope == 0 || unfiltered == 0 || scale == 0) {
            raw = 0;
        } else if (filtered == 0 || sgv < 40) {
            raw = scale * (unfiltered - intercept) / slope
        } else {
            let ratioCalc = scale * (filtered - intercept) / slope
            let ratio = ratioCalc / sgv
            
            let rawCalc = scale * (unfiltered - intercept) / slope
            raw = rawCalc / ratio
        }
        
        return sgValue.sgv.isInteger ? round(raw) : raw
    }
}

