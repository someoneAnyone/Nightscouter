//
//  Complication.swift
//  Nightscouter
//
//  Created by Peter Ina on 2/2/16.
//  Copyright © 2016 Nothingonline. All rights reserved.
//

import Foundation

public struct ComplicationTimelineEntry: SiteMetadataDataSource, SiteMetadataDelegate, GlucoseValueDelegate, GlucoseValueDataSource, DirectionDisplayable, RawDataSource, Dateable {
    
    public var milliseconds: Mills
    
    public var nameLabel: String
    public var urlLabel: String = ""
    public var lastReadingDate: Date
    
    public var sgvLabel: String
    public var deltaLabel: String
    public var deltaShort: String {
        return deltaLabel.replacingOccurrences(of: units.description, with: PlaceHolderStrings.deltaAltJ)
    }
    
    public var rawHidden: Bool {
        return (rawLabel == "")
    }
    public var rawLabel: String
    public var rawNoise: Noise
 
    public var lastReadingColor: Color = Color.clear

    public var sgvColor: Color
    public var deltaColor: Color
    
    public var units: GlucoseUnit
    public var direction: Direction
    
    public var stale: Bool {
        return date.timeIntervalSinceNow < -(60.0 * 15.0)
    }
    
    public init(date: Date, rawLabel: String?, nameLabel: String, sgvLabel: String, deltaLabel: String = "", tintColor: Color, units: GlucoseUnit = .mgdl, direction: Direction = .none, noise: Noise = .none) {
        self.lastReadingDate = date

        self.rawLabel = rawLabel ?? ""
        self.nameLabel = nameLabel
        self.urlLabel = ""
        self.sgvLabel = sgvLabel
        self.deltaLabel = deltaLabel
        self.deltaColor = tintColor
        self.sgvColor = tintColor
        
        self.milliseconds = date.timeIntervalSince1970.millisecond
        self.units = units
        self.direction = direction
        self.rawNoise = noise
    }

}

extension ComplicationTimelineEntry: Equatable {}
public func ==(lhs: ComplicationTimelineEntry, rhs: ComplicationTimelineEntry) -> Bool {
    return lhs.milliseconds == rhs.milliseconds &&
        lhs.lastReadingDate == rhs.lastReadingDate &&
        lhs.rawLabel == rhs.rawLabel &&
        lhs.nameLabel == rhs.nameLabel &&
        lhs.urlLabel == rhs.urlLabel &&
        lhs.sgvLabel == rhs.sgvLabel &&
        lhs.deltaLabel == rhs.deltaLabel &&
        lhs.rawNoise == rhs.rawNoise &&
        lhs.lastReadingColor == rhs.lastReadingColor &&
        lhs.sgvColor == rhs.sgvColor &&
        lhs.deltaColor == rhs.deltaColor &&
        lhs.units == rhs.units &&
        lhs.direction == rhs.direction &&
        lhs.stale == rhs.stale
}
