//
//  Complication.swift
//  Nightscouter
//
//  Created by Peter Ina on 2/2/16.
//  Copyright © 2016 Nothingonline. All rights reserved.
//

import Foundation

public struct ComplicationTimelineEntry: SiteMetadataDataSource, SiteMetadataDelegate, GlucoseValueDelegate, GlucoseValueDataSource, DirectionDisplayable, RawDataSource, Dateable {
    
    public var milliseconds: Mills?
    
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
    
    //    internal var sgvColorString: String
    //    internal var deltaColorString: String
    
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
        
        //        self.deltaColorString = tintColor.toHexString()
        //        self.sgvColorString = tintColor.toHexString()
        //
        self.deltaColor = tintColor
        self.sgvColor = tintColor
        
        self.milliseconds = date.timeIntervalSince1970.millisecond
        self.units = units
        self.direction = direction
        self.rawNoise = noise
    }
    
}

extension ComplicationTimelineEntry: Encodable {
    enum CodingKeys: String, CodingKey {
        case lastReadingDate, rawLabel, nameLabel, urlLabel, sgvLabel, deltaLabel, deltaColorString, sgvColorString, units, direction, rawNoise, milliseconds
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(lastReadingDate, forKey: .lastReadingDate)
        try container.encode(rawLabel, forKey: .rawLabel)
        try container.encode(nameLabel, forKey: .nameLabel)
        try container.encode(urlLabel, forKey: .urlLabel)
        try container.encode(sgvLabel, forKey: .sgvLabel)
        try container.encode(deltaLabel, forKey: .deltaLabel)
        
        try container.encode(deltaColor.toHexString(), forKey: .deltaColorString)
        try container.encode(sgvColor.toHexString(), forKey: .sgvColorString)
        try container.encode(milliseconds, forKey: .milliseconds)
        try container.encode(units, forKey: .units)
        try container.encode(direction, forKey: .direction)
        try container.encode(rawNoise, forKey: .rawNoise)
    }
}

extension ComplicationTimelineEntry: Decodable {
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        self.lastReadingDate = try values.decode(Date.self, forKey: .lastReadingDate)
        
        self.rawLabel = try values.decode(String.self, forKey: .rawLabel)
        self.nameLabel = try values.decode(String.self, forKey: .nameLabel)
        self.urlLabel = try values.decode(String.self, forKey: .urlLabel)
        self.sgvLabel = try values.decode(String.self, forKey: .sgvLabel)
        self.deltaLabel = try values.decode(String.self, forKey: .deltaLabel)
        
        let deltaColorString = try values.decode(String.self, forKey: .deltaColorString)
        let sgvColorString = try values.decode(String.self, forKey: .sgvColorString)
        
        self.deltaColor = Color(hexString: deltaColorString)
        self.sgvColor = Color(hexString: sgvColorString)
        
        self.milliseconds = try values.decode(Mills.self, forKey: .milliseconds)
        self.units = try values.decode(GlucoseUnit.self, forKey: .units)
        self.direction = try values.decode(Direction.self, forKey: .direction)
        self.rawNoise = try values.decode(Noise.self, forKey: .rawNoise)
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
