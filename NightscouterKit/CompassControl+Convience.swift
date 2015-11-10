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
        self.delta = "\(bgdelta.formattedForBGDelta) \(units)"
    }
    
    public func configureWith(site: Site){
        if let configuration: ServerConfiguration = site.configuration,  watch: WatchEntry = site.watchEntry,  sgv: SensorGlucoseValue = watch.sgv {
          
            var boundedColor = configuration.boundedColorForGlucoseValue(sgv.sgv)
           
            let units: Units = configuration.displayUnits
            if units == .Mmol {
                boundedColor = configuration.boundedColorForGlucoseValue(sgv.sgv.toMgdl)
            }
            
            let color = colorForDesiredColorState(boundedColor)
            
            configure(sgv.sgvString, color: color, direction: sgv.direction, bgdelta: watch.bgdelta, units: units.description)
        }
    }
    
    public func shouldLookStale(look stale: Bool) {
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