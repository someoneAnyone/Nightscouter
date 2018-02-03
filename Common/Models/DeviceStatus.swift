//
//  DeviceStatus.swift
//  Nightscouter
//
//  Created by Peter Ina on 1/11/16.
//  Copyright © 2016 Nothingonline. All rights reserved.
//

import Foundation

/// A record type provided by the Nightscout API, contains regarding the battery level of the uploading device.
public struct DeviceStatus: CustomStringConvertible, Dateable, Codable {
    private let zeroSymbolForBattery: String = PlaceHolderStrings.battery
    
    /** 
     The battery's raw value provided by the Nightscout API.
     The properly converted string can be found in:
     
     var batteryLevel: String { get }
     
     */
    public let uploaderBattery: Int
    public var milliseconds: Mills?
    public var createdDate: Date?
    public var pump: Pump?
    
    enum CodingKeys: String, CodingKey {
        case uploaderBattery, pump
        case milliseconds = "date"
        case createdDate = "created_at"
    }
    
    public var batteryLevel: String {
        get {
            let numFormatter = NumberFormatter()
            
            numFormatter.locale = Locale.autoupdatingCurrent
            numFormatter.numberStyle = .percent
            numFormatter.zeroSymbol = zeroSymbolForBattery
            
            let precentage = NSNumber(value: Float(uploaderBattery)/100)
            
            return numFormatter.string(from: precentage) ?? zeroSymbolForBattery
        }
    }
    
    /**
     
        Initializes a new device status structure with the default values.
     
        - Parameters:
            - None
     
     
        - Returns: DeviceStatus
     */
    public init() {
        uploaderBattery = 76
        milliseconds = 1268197200000 // AppConfiguration.Constant.knownMilliseconds
    }
    
    /**
        Initializes a new device status structure with the provided battery value and date in milliseconds.

        - Parameters:
            - uploaderBattery: The a whole integer value from JSON, like 0-99.
            - milliseconds: The EPOCH date converted into milliseconds.
        
        - Returns: DeviceStatus
     
     */
    public init(uploaderBattery: Int, milliseconds: Double) {
        self.uploaderBattery = uploaderBattery
        self.milliseconds = milliseconds
    }
    
    public var description: String {
        return "{ DeviceStatus: { uploaderBattery: \(uploaderBattery),  batteryLevel: \(batteryLevel) } }"
    }
}

extension DeviceStatus: ColorBoundable {
    public var bottom: Double { return 20.0 }
    public var targetBottom: Double { return 50.0 }
    public var targetTop: Double { return 100.0 }
    public var top: Double { return 101.0 }
    
    public var desiredColorState: DesiredColorState {
        return self.desiredColorState(forValue: Double(self.uploaderBattery))
    }
}

extension DeviceStatus: Hashable {
    public var hashValue: Int {
        return uploaderBattery.hashValue + date.hashValue
    }
}

public struct Pump: Codable {
    let battery: Battery
    
    struct Battery: Codable {
        let percent: Double
    }
    
    let clock: String
    
    let iob: InsulinOnBoard
    
    struct InsulinOnBoard: Codable {
        let bolusiob: Double
        let timestamp: String
    }
    
    let reservoir: Double
    let status: Status
    
    struct Status: Codable {
        let bolusing: Bool
        let status: String
        let suspended: Bool
    }

}
