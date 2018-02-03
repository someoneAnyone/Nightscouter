//
//  Protocols.swift
//  Nightscouter
//
//  Created by Peter Ina on 1/11/16.
//  Copyright © 2016 Nothingonline. All rights reserved.
//
import Foundation
#if os(iOS) || os(watchOS) || os(tvOS)
    import UIKit
#elseif os(OSX)
    import Cocoa
#endif

public typealias Mills = Double

// MARK: - Dateable. Store values in milliseconds, get a date back.
public protocol Dateable {
    var milliseconds: Mills? { get }
}

public extension Dateable {
    public var date: Date {
        return Date(timeIntervalSince1970: (TimeInterval(milliseconds ?? 1268197200000) / 1000))
    }
}
public func == <T: Dateable>(lhs: T, rhs: T) -> Bool {
    return lhs.date == rhs.date
}

extension DeviceStatus: Equatable { }
extension MeteredGlucoseValue: Equatable { }
extension Calibration: Equatable { }
extension SensorGlucoseValue: Equatable { }


// Common fields for holding a glucose value.
public typealias MgdlValue = Double

public protocol GlucoseValueHolder {
    var mgdl: MgdlValue { get }
    var isGlucoseValueOk: Bool { get }
    var reservedValueUpperEndValue: MgdlValue { get }
}

public extension GlucoseValueHolder {
    public var reservedValueUpperEndValue: MgdlValue { return 17 }
    
    public var isGlucoseValueOk: Bool {
        return mgdl >= reservedValueUpperEndValue
    }
}

public protocol ColorBoundable {
    var bottom: Double { get }
    var targetBottom: Double { get }
    var targetTop: Double { get }
    var top: Double { get }
    
    func desiredColorState(forValue value: Double) -> DesiredColorState
}

extension ColorBoundable {
    public func desiredColorState(forValue value: Double) -> DesiredColorState {
        
        var desiredState: DesiredColorState?
        if (value >= top) {
            desiredState = .alert
        } else if (value > targetTop && value < top) {
            desiredState =  .warning
        } else if (value >= targetBottom && value <= targetTop) {
            desiredState = .positive
        } else if (value < targetBottom && value > bottom) {
            desiredState = .warning
        } else if (value <= bottom && value != 0) {
            desiredState = .alert
        }
        
        return desiredState ?? .neutral
    }
}

// TODO: Should this be here?
public enum DesiredColorState: String, CustomStringConvertible {
    case alert, warning, positive, neutral, notSet
    
    public var description: String {
        return self.rawValue
    }
    
    public init() {
        self = .neutral
    }
}

// Records tagged with a device share this field.
public protocol DeviceOwnable {
    var device: Device? { get }
}

public enum Device: String, Codable, CustomStringConvertible {
    case unknown, dexcom = "dexcom", xDripDexcomShare = "xDrip-DexcomShare", watchFace = "watchFace", share2 = "share2", testDevice = "testDevice", paradigm = "connect://paradigm", medtronic = "medtronic-600://6214-1016846"
    
    public var description: String {
        return self.rawValue
    }

    public init() {
        self = .unknown
    }
}

// TODO: Create Struct to hold wacth or now data like delta, current bg, raw and battery....
public protocol DeltaDisplayable {
    var delta: MgdlValue { get set }
    var deltaNumberFormatter: NumberFormatter { get }
    func deltaString(forUnits units: GlucoseUnit) -> String
}

extension DeltaDisplayable {
    public static var deltaNumberFormatter: NumberFormatter {
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.positivePrefix = formatter.plusSign
        formatter.negativePrefix = formatter.minusSign
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        formatter.secondaryGroupingSize = 1
        
        return formatter
    }
    
    public func deltaString(forUnits units: GlucoseUnit) -> String {
        var rawDelta: MgdlValue = 0
        switch units {
        case .mgdl:
            rawDelta = delta
        case .mmol:
            rawDelta = delta.toMmol
        }
        return deltaNumberFormatter.string(from: NSNumber(value: rawDelta)) ?? PlaceHolderStrings.delta
    }
}

public extension SensorGlucoseValue {
    func calculateRaw(withCalibration cal: Calibration) -> MgdlValue {
        return calculateRawBG(fromSensorGlucoseValue: self, calibration: cal)
    }
}

public extension Calibration {
    func calculateRaw(withSensorGlucoseValue sgv: SensorGlucoseValue) -> MgdlValue {
        return calculateRawBG(fromSensorGlucoseValue: sgv, calibration: self)
    }
}

fileprivate func calculateRawBG(fromSensorGlucoseValue sgv: SensorGlucoseValue, calibration cal: Calibration) -> MgdlValue {
    var raw: Double = 0
    
    let unfiltered = sgv.unfiltered ?? 0
    let filtered = sgv.filtered ?? 0
    let sgv: Double = sgv.mgdl
    
    let slope = cal.slope 
    let scale = cal.scale 
    let intercept = cal.intercept 
    
    if (slope == 0 || unfiltered == 0 || scale == 0) {
        raw = 0
    } else if (filtered == 0 || sgv < 40) {
        raw = scale * (unfiltered - intercept) / slope
    } else {
        let ratioCalc = scale * (filtered - intercept) / slope
        let ratio = ratioCalc / sgv
        
        let rawCalc = scale * (unfiltered - intercept) / slope
        raw = rawCalc / ratio
    }
    
    return round(raw)
}


public extension DesiredColorState {
    
    private static let colorMapping = [
        DesiredColorState.neutral: Color(red: 0.851, green: 0.851, blue: 0.851, alpha: 1.000),
        DesiredColorState.alert: Color(red: 1.000, green: 0.067, blue: 0.310, alpha: 1.000),
        DesiredColorState.positive: Color(red: 0.016, green: 0.871, blue: 0.443, alpha: 1.000),
        DesiredColorState.warning: Color(red: 1.000, green: 0.902, blue: 0.125, alpha: 1.000),
        DesiredColorState.notSet: Color(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    ]
    
    #if os(iOS) || os(watchOS) || os(tvOS)
    public var colorValue: UIColor {
        return DesiredColorState.colorMapping[self]!
    }
    #elseif os(OSX)
    public var colorValue: NSColor {
    return DesiredColorState.colorMapping[self]!
    }
    #endif
}


