//
//  MeteredGlucoseValue.swift
//  Nightscouter
//
//  Created by Peter Ina on 1/11/16.
//  Copyright © 2016 Nothingonline. All rights reserved.
//

import Foundation

public struct MeteredGlucoseValue: CustomStringConvertible, Dateable, GlucoseValueHolder, DeviceOwnable, Codable {
    public let milliseconds: Mills?
    public let device: Device
    public let mgdl: MgdlValue
    
    enum CodingKeys: String, CodingKey {
        case device, mgdl = "mbg"
        case milliseconds = "date"
    }
    
    public init() {
        milliseconds = AppConfiguration.Constant.knownMilliseconds
        device = Device()
        mgdl = AppConfiguration.Constant.knownMgdl
    }
    
    public init(milliseconds: Mills, device: Device, mgdl: MgdlValue) {
        self.milliseconds = milliseconds
        self.device = device
        self.mgdl = mgdl
    }
    
    public var description: String {
        return "{ MeteredGlucoseValue: { milliseconds: \(String(describing: milliseconds)),  device: \(device), mgdl: \(mgdl) } }"
    }
}
