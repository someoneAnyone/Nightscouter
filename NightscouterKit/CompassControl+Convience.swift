//
//  CompassControl+Convience.swift
//  Nightscouter
//
//  Created by Peter Ina on 6/30/15.
//  Copyright (c) 2015 Peter Ina. All rights reserved.
//

import UIKit

public extension CompassControl {
    
    func configure(_ sgvText: String, color: UIColor, direction: Direction, bgdelta: String, units: String) -> Void {
        self.sgvText = sgvText
        self.color = color
        self.direction = direction
        self.delta = bgdelta//bgdelta.formattedBGDelta(forUnits: GlucoseUnit(rawValue: units))//"\(bgdelta.formattedForBGDelta) \(units)"
    }
    
    public func configure(withDataSource dataSource: CompassViewDataSource, delegate: CompassViewDelegate?) {
        direction = dataSource.direction
        delta = dataSource.detailText
        sgvText = dataSource.text
        color = delegate?.desiredColor.colorValue ?? DesiredColorState.neutral.colorValue
        shouldLookStale(look: dataSource.lookStale)
    }
    
    public func shouldLookStale(look stale: Bool = true) {
        if stale {
            let compass = CompassControl()
            self.alpha = 0.5
            self.color = compass.color
            self.sgvText = compass.sgvText
            self.direction = compass.direction
            self.delta = compass.delta
        } else {
            self.alpha = 1.0
        }
    }
    
}
