//
//  CompassControl+Convience.swift
//  Nightscouter
//
//  Created by Peter Ina on 6/30/15.
//  Copyright (c) 2015 Peter Ina. All rights reserved.
//

import UIKit

public extension CompassControl {
    
 func configure(sgvText: String, color: UIColor, direction: Direction, bgdelta: Int, units: String) -> Void {
        self.sgvText = sgvText
        self.color = color
        self.direction = direction
        self.delta = "\(bgdelta.formattedForBGDelta) \(units)"
    }
    
    public func configureWith(site: Site){
        if let configuration: ServerConfiguration = site.configuration,  watch: WatchEntry = site.watchEntry,  sgv: SensorGlucoseValue = watch.sgv {
          
            let color = colorForDesiredColorState(configuration.boundedColorForGlucoseValue(sgv.sgv))
           
            var units: Units = configuration.displayUnits
            
            configure(sgv.sgvString, color: color, direction: sgv.direction, bgdelta: watch.bgdelta, units: units.rawValue)
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