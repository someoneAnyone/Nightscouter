//
//  CompassControl+Convience.swift
//  Nightscouter
//
//  Created by Peter Ina on 6/30/15.
//  Copyright (c) 2015 Peter Ina. All rights reserved.
//

import UIKit

extension CompassControl {
    
    
    internal func configure(sgvText: String, color: UIColor , sgvValue: Int, direction: Direction, date: NSDate, bgdelta: Int, units: String) -> Void {
        self.sgvText = sgvText
        self.color = color
        self.direction = direction
        let numberFormat = NSNumberFormatter.localizedStringFromNumber(bgdelta, numberStyle: .NoStyle)
        self.delta = "\(numberFormat) \(units)"
    }
    
    func configureWithObject(site: Site){
        
        let configuration: ServerConfiguration! = site.configuration
        let watch: WatchEntry! = site.watchEntry
        let sgv: SensorGlucoseValue! = watch!.sgv
        
        let color = colorForDesiredColorState(site.configuration!.boundedColorForGlucoseValue(sgv!.sgv))

        configure(sgv.sgvString, color: color, sgvValue: sgv.sgv, direction: sgv.direction, date: watch.date, bgdelta: watch.bgdelta, units: configuration.units.rawValue)
    }
}