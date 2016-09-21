//
//  MeteredGlucoseValue.swift
//  Nightscouter
//
//  Created by Peter Ina on 1/11/16.
//  Copyright © 2016 Nothingonline. All rights reserved.
//

import Foundation

public struct MeteredGlucoseValue: CustomStringConvertible, Dateable, GlucoseValueHolder, DeviceOwnable {
    public let milliseconds: Double
    public let device: Device
    public let mgdl: MgdlValue
    
    public init() {
        milliseconds = AppConfiguration.Constant.knownMilliseconds
        device = Device()
        mgdl = AppConfiguration.Constant.knownMgdl
    }
    
    public init(milliseconds: Double, device: Device, mgdl: MgdlValue) {
        self.milliseconds = milliseconds
        self.device = device
        self.mgdl = mgdl
    }
    
    public var description: String {
        return "{ MeteredGlucoseValue: { milliseconds: \(milliseconds),  device: \(device), mgdl: \(mgdl) } }"
    }
}