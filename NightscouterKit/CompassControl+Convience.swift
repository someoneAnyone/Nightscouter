//
//  CompassControl+Convience.swift
//  Nightscouter
//
//  Created by Peter Ina on 6/30/15.
//  Copyright (c) 2015 Peter Ina. All rights reserved.
//

import UIKit

public extension CompassControl {
    
    func configure(sgvText: String, color: UIColor, direction: Direction, bgdelta: Double, units: String) -> Void {
        self.sgvText = sgvText
        self.color = color
        self.direction = direction
        self.delta = bgdelta.formattedBGDelta(forUnits: Units(string: units))//"\(bgdelta.formattedForBGDelta) \(units)"
    }
    
    public func configureWith(model: WatchModel){
        
        configure(model.sgvString, color: UIColor(hexString: model.sgvColor), direction: Direction.directionForString(model.direction.stringByReplacingOccurrencesOfString(" ", withString: "")), bgdelta: model.delta, units: model.units)
        self.shouldLookStale(look: model.warn)
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