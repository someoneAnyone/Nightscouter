//
//  SensorGlucoseValue.swift
//  Nightscouter
//
//  Created by Peter Ina on 1/11/16.
//  Copyright © 2016 Nothingonline. All rights reserved.
//

import Foundation

public struct SensorGlucoseValue: CustomStringConvertible, Dateable, GlucoseValueHolder, DeviceOwnable {
    public let device: Device, direction: Direction
    public let rssi: Int, unfiltered: Double, filtered: Double, mgdl: MgdlValue
    public let noise: Noise
    public let milliseconds: Double
    
    public var description: String {
        return "{ SensorGlucoseValue: { device: \(device), mgdl: \(mgdl), date: \(date), direction: \(direction) } }"
    }
    
    public init() {
        device = Device.testDevice
        direction = Direction.Flat
        rssi = 188
        unfiltered = 186624
        filtered = 180800
        mgdl = MgdlValue(arc4random_uniform(400) + 60) // AppConfiguration.Constant.knownMgdl
        noise = Noise.clean
        milliseconds = Date().timeIntervalSince1970.millisecond//AppConfiguration.Constant.knownMilliseconds
    }
       
    public init(direction: Direction, device: Device, rssi: Int, unfiltered: Double, filtered: Double, mgdl: MgdlValue, noise: Noise, milliseconds: Double) {
        self.direction = direction
        self.filtered = filtered
        self.unfiltered = unfiltered
        self.rssi = rssi
        self.milliseconds = milliseconds
        self.mgdl = mgdl
        self.device = device
        self.noise = noise
    }
}

public enum ReservedValues: MgdlValue, CustomStringConvertible {
    case noGlucose=0, sensoreNotActive=1, minimalDeviation=2, noAntenna=3, sensorNotCalibrated=5, countsDeviation=6, absoluteDeviation=9, powerDeviation=10, badRF=12, hupHolland=17, low=30
    
    public var description: String {
        switch (self) {
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
            return "?PD"
        case .badRF:
            return "?RF✖"
        case .hupHolland:
            return "MH"
        case .low:
            return LocalizedString.sgvLowString.localized
        }
    }
}

extension ReservedValues {
    init?(mgdl: MgdlValue) {
        if mgdl >= 30 && mgdl < 40 {
            self.init(rawValue: 30)
        } else {
            
            self.init(rawValue: mgdl)
        }
    }
}

public enum Direction : String, CustomStringConvertible, RawRepresentable {
    case none = "None", DoubleUp = "DoubleUp", SingleUp = "SingleUp", FortyFiveUp = "FortyFiveUp", Flat = "Flat", FortyFiveDown = "FortyFiveDown", SingleDown = "SingleDown", DoubleDown = "DoubleDown", NotComputable = "NOT COMPUTABLE", RateOutOfRange = "RateOutOfRange", Not_Computable = "NOT_COMPUTABLE"
    
    public var description : String {
        switch(self) {
        case .none: return NSLocalizedString("directionNone", tableName: nil, bundle:  Bundle.main, value: "None", comment: "Label used to indicate a direction.")
        case .DoubleUp: return NSLocalizedString("directionDoubleUp", tableName: nil, bundle:  Bundle.main, value: "Double Up", comment: "Label used to indicate a direction.")
        case .SingleUp: return NSLocalizedString("directionSingleUp", tableName: nil, bundle:  Bundle.main, value: "Single Up", comment: "Label used to indicate a direction.")
        case .FortyFiveUp: return NSLocalizedString("directionFortyFiveUp", tableName: nil, bundle:  Bundle.main, value: "Forty Five Up", comment: "Label used to indicate a direction.")
        case .Flat: return NSLocalizedString("directionFlat", tableName: nil, bundle:  Bundle.main, value: "Flat", comment: "Label used to indicate a direction.")
        case .FortyFiveDown: return NSLocalizedString("directionFortyFiveDown", tableName: nil, bundle:  Bundle.main, value: "Forty Five Down", comment: "Label used to indicate a direction.")
        case .SingleDown: return NSLocalizedString("directionSingleDown", tableName: nil, bundle:  Bundle.main, value: "Single Down", comment: "Label used to indicate a direction.")
        case .DoubleDown: return NSLocalizedString("directionDoubleDown", tableName: nil, bundle:  Bundle.main, value: "Double Down", comment: "Label used to indicate a direction.")
        case .NotComputable, .Not_Computable: return NSLocalizedString("directionNotComputable", tableName: nil, bundle:  Bundle.main, value: "N/C", comment: "Label used to indicate a direction.")
        case .RateOutOfRange: return NSLocalizedString("directionRateOutOfRange", tableName: nil, bundle:  Bundle.main, value: "Rate Out Of Range", comment: "Label used to indicate a direction.")
            
        }
    }
    
    public var emojiForDirection: String {
        get {
            switch (self) {
            case .none: return ""
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
        case "None": return .none
        case "DoubleUp": return .DoubleUp
        case "SingleUp": return .SingleUp
        case "FortyFiveUp": return .FortyFiveUp
        case "Flat": return .Flat
        case "FortyFiveDown": return .FortyFiveDown
        case "SingleDown": return .SingleDown
        case "DoubleDown": return .DoubleDown
        case "NOT COMPUTABLE", "NOT_COMPUTABLE": return .NotComputable
        case "RateOutOfRange": return .RateOutOfRange
        default: return .none
        }
    }
    
    public init() {
        self = .none
    }
}

extension Direction {
    public var angleForCompass: Float {
        get {
            switch (self) {
            case .FortyFiveUp:
                return -45
            case .Flat:
                return -90
            case .FortyFiveDown:
                return -120
            case .SingleDown, .DoubleDown:
                return -180
            default:
                return 0
            }
        }
    }
    public var isDoubleRingVisible: Bool {
        return self == .DoubleDown || self == .DoubleUp
    }
    
    public var isNotComputable: Bool {
        return self == .NotComputable || self == .Not_Computable || self == .none
    }
    
    public var isArrowVisible: Bool {
        return !(isNotComputable || self == .none || self == .RateOutOfRange)
    }
}

public enum Noise : Int, CustomStringConvertible {
    case none = 0, clean = 1, light = 2, medium = 3, heavy = 4, unknown = 5
    
    public var description: String {
        switch (self) {
        case .none: return NSLocalizedString("noiseNone", tableName: nil, bundle:  Bundle.main, value: "---", comment: "Label used to indicate a direction.")
        case .clean: return NSLocalizedString("noiseClean", tableName: nil, bundle:  Bundle.main, value: "Clean", comment: "Label used to indicate a direction.")
        case .light: return NSLocalizedString("noiseLight", tableName: nil, bundle:  Bundle.main, value: "Light", comment: "Label used to indicate a direction.")
        case .medium: return NSLocalizedString("noiseMedium", tableName: nil, bundle:  Bundle.main, value: "Medium", comment: "Label used to indicate a direction.")
        case .heavy: return NSLocalizedString("noiseHeavy", tableName: nil, bundle:  Bundle.main, value: "Heavy", comment: "Label used to indicate a direction.")
        case .unknown: return NSLocalizedString("noiseUnkown", tableName: nil, bundle:  Bundle.main, value: "~~~", comment: "Label used to indicate a direction.")
        }
    }
    
    public init() {
        self = .none
    }
}
