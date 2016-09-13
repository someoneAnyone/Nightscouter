//
//  SensorGlucoseValues.swift
//  Nightscouter
//
//  Created by Peter Ina on 10/6/15.
//  Copyright © 2015 Peter Ina. All rights reserved.
//

import Foundation

public enum Direction : String, CustomStringConvertible {
    case None = "NONE", DoubleUp = "DoubleUp", SingleUp = "SingleUp", FortyFiveUp = "FortyFiveUp", Flat = "Flat", FortyFiveDown = "FortyFiveDown", SingleDown = "SingleDown", DoubleDown = "DoubleDown", NotComputable = "NOT COMPUTABLE", RateOutOfRange = "RateOutOfRange", Not_Computable = "NOT_COMPUTABLE"
    
    public static let allValues = [None, DoubleUp, SingleUp, FortyFiveUp, Flat, FortyFiveDown, SingleDown, DoubleDown, NotComputable, RateOutOfRange]
    
    public var description : String {
        switch(self) {
        case .None: return NSLocalizedString("directionNone", tableName: nil, bundle:  Bundle.main, value: "None", comment: "Label used to indicate a direction.")
        case .DoubleUp: return NSLocalizedString("directionDoubleUp", tableName: nil, bundle:  Bundle.main, value: "Double Up", comment: "Label used to indicate a direction.")
        case .SingleUp: return NSLocalizedString("directionSingleUp", tableName: nil, bundle:  Bundle.main, value: "Single Up", comment: "Label used to indicate a direction.")
        case .FortyFiveUp: return NSLocalizedString("directionFortyFiveUp", tableName: nil, bundle:  Bundle.main, value: "Forty Five Up", comment: "Label used to indicate a direction.")
        case .Flat: return NSLocalizedString("directionFlat", tableName: nil, bundle:  Bundle.main, value: "Flat", comment: "Label used to indicate a direction.")
        case .FortyFiveDown: return NSLocalizedString("directionFortyFiveDown", tableName: nil, bundle:  Bundle.main, value: "Forty Five Down", comment: "Label used to indicate a direction.")
        case .SingleDown: return NSLocalizedString("directionSingleDown", tableName: nil, bundle:  Bundle.main, value: "Single Down", comment: "Label used to indicate a direction.")
        case .DoubleDown: return NSLocalizedString("directionFortyDoubleDown", tableName: nil, bundle:  Bundle.main, value: "Double Down", comment: "Label used to indicate a direction.")
        case .NotComputable, .Not_Computable: return NSLocalizedString("directionNotComputable", tableName: nil, bundle:  Bundle.main, value: "N/C", comment: "Label used to indicate a direction.")
        case .RateOutOfRange: return NSLocalizedString("directionRateOutOfRange", tableName: nil, bundle:  Bundle.main, value: "Rate Out Of Range", comment: "Label used to indicate a direction.")

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
    
   static public func directionForString(_ directionString: String) -> Direction {
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
    case none = 0, clean = 1, light = 2, medium = 3, heavy = 4
    
    public var description: String {
        switch (self) {
        case .none: return NSLocalizedString("noiseNone", tableName: nil, bundle:  Bundle.main, value: "None", comment: "Label used to indicate a direction.")
        case .clean: return NSLocalizedString("noiseClean", tableName: nil, bundle:  Bundle.main, value: "Clean", comment: "Label used to indicate a direction.")
        case .light: return NSLocalizedString("noiseLight", tableName: nil, bundle:  Bundle.main, value: "Light", comment: "Label used to indicate a direction.")
        case .medium: return NSLocalizedString("noiseMedium", tableName: nil, bundle:  Bundle.main, value: "Medium", comment: "Label used to indicate a direction.")
        case .heavy: return NSLocalizedString("noiseHeavy", tableName: nil, bundle:  Bundle.main, value: "Heavy", comment: "Label used to indicate a direction.")
        }
    }
    
    public init() {
        self = .none
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
    
    public func isReservedValue(forUnits units: Units) -> Bool {
        let mgdlSgvValue: Double = (units == .Mgdl) ? sgv : sgv.toMgdl // If the units are set to mgd/L do nothing let it pass... if its mmol/L then convert it back to mgd/L to get its proper string.

        return (ReservedValues(rawValue: mgdlSgvValue) != nil) ? true : false
    }
    
    enum ReservedValues: Double {
        case noGlucose=0, sensoreNotActive=1, minimalDeviation=2, noAntenna=3, sensorNotCalibrated=5, countsDeviation=6, absoluteDeviation=9, powerDeviation=10, badRF=12, hupHolland=17
    }
    
    
    public func sgvString(forUnits units: Units) -> String {
        
        let mgdlSgvValue: Double = (units == .Mgdl) ? sgv : sgv.toMgdl // If the units are set to mgd/L do nothing let it pass... if its mmol/L then convert it back to mgd/L to get its proper string.
        
        if let special:ReservedValues = ReservedValues(rawValue: mgdlSgvValue) {
            switch (special) {
            case .noGlucose:
                return "?NC"
            case .sensoreNotActive:
                return "?NA"
            case .minimalDeviation:
                return "?MD"
            case .noAntenna:
                return "?NA"
            case .sensorNotCalibrated:
                return "?NC"
            case .countsDeviation:
                return "?CD"
            case .absoluteDeviation:
                return "?AD"
            case .powerDeviation:
                return "???"
            case .badRF:
                return "?RF✖"
            case .hupHolland:
                return "MH"
            }
        }
        if sgv >= 30 && sgv < 40 {
            return  NSLocalizedString("sgvLowString", tableName: nil, bundle:  Bundle.main, value: "Low", comment: "Label used to indicate a very low blood sugar.")
        }
        if units == Units.Mgdl  {
            return sgv.formattedForMgdl
        }
        
        return sgv.isInteger ? sgv.formattedForMmol : sgv.toMgdl.formattedForMmol//NSNumberFormatter.localizedStringFromNumber(sgv, numberStyle: NSNumberFormatterStyle.DecimalStyle)
    }
    
    @available(*, deprecated: 1.0, message: "Please use func func sgvString(forUnits units: Units) -> String")
    public var sgvString: String {
        get {
            return sgvString(forUnits: .Mgdl)
        }
    } // Returns string based on mg/dL. Not good don't use.
    
}

/// Raw data support. Requires a calibration.
public extension SensorGlucoseValue {
    public func rawIsigToRawBg(_ calValue: Calibration) -> Double {
        return rawIsigToRawBg(self, calValue: calValue)
    }
    
    internal func rawIsigToRawBg(_ sgValue: SensorGlucoseValue, calValue: Calibration) -> Double {
        
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

