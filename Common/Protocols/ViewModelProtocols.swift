//
//  ViewModelProtocols.swift
//  Nightscouter
//
//  Created by Peter Ina on 3/10/16.
//  Copyright © 2016 Nothingonline. All rights reserved.
//

import Foundation

public protocol SiteMetadataDataSource {
    var lastReadingDate: Date { get }
    var nameLabel: String { get }
    var urlLabel: String { get }
}

public protocol SiteMetadataDelegate {
    var lastReadingColor: Color { get }
}

public protocol GlucoseValueDataSource {
    var sgvLabel: String { get }
    var deltaLabel: String { get }
}

public protocol GlucoseValueDelegate {
    var sgvColor: Color { get }
    var deltaColor: Color { get }
}

public protocol BatteryDataSource {
    var batteryHidden: Bool { get }
    var batteryLabel: String { get }
}
public protocol BatteryDelegate {
    var batteryColor: Color { get }
}

public protocol SiteStaleDataSource {
    var lookStale: Bool { get }
}

public protocol RawDataSource {
    var rawHidden: Bool { get }
    var rawLabel: String { get }
    var rawNoise: Noise { get }
    
    var rawFormatedLabel: String { get }
}

public extension RawDataSource {
    var rawFormatedLabel: String {
        return "\(rawLabel) : \(rawNoise.description)"
    }
    var rawFormatedLabelShort: String {
        return "\(rawLabel) : \(rawNoise.description[rawNoise.description.startIndex])"
    }
}

public protocol RawDelegate {
    var rawColor: Color { get }
}

public protocol DirectionDisplayable {
    var direction: Direction { get }
}

public protocol CompassViewDataSource: SiteMetadataDataSource, GlucoseValueDataSource, SiteStaleDataSource, DirectionDisplayable, RawDataSource {
    var text: String { get }
    var detailText: String { get }
}

public protocol CompassViewDelegate: SiteMetadataDelegate, GlucoseValueDelegate, RawDelegate {
    var desiredColor: DesiredColorState { get }
}

public typealias TableViewRowWithCompassDataSource = SiteMetadataDataSource & GlucoseValueDataSource & BatteryDataSource & CompassViewDataSource
public typealias TableViewRowWithCompassDelegate = SiteMetadataDelegate & GlucoseValueDelegate & CompassViewDelegate & BatteryDelegate

public typealias TableViewRowWithOutCompassDataSource = SiteMetadataDataSource & GlucoseValueDataSource & BatteryDataSource & RawDataSource & DirectionDisplayable
public typealias TableViewRowWithOutCompassDelegate = SiteMetadataDelegate & GlucoseValueDelegate & RawDelegate & BatteryDelegate

public typealias SiteSummaryModelViewModelDataSource = SiteMetadataDataSource & GlucoseValueDataSource & RawDataSource & BatteryDataSource & DirectionDisplayable & CompassViewDataSource
public typealias SiteSummaryModelViewModelDelegate = SiteMetadataDelegate & GlucoseValueDelegate & RawDelegate & CompassViewDelegate & BatteryDelegate
