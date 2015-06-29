//
//  NSAssetKit+Helpers.swift
//  Nightscouter
//
//  Created by Peter Ina on 6/29/15.
//  Copyright (c) 2015 Peter Ina. All rights reserved.
//

import UIKit


    func colorForDesiredColorState(desiredState: DesiredColorState) -> UIColor {
        switch (desiredState) {
        case .Neutral:
            return NSAssetKit.predefinedNeutralColor
        case .Alert:
            return NSAssetKit.predefinedAlertColor
        case .Positive:
            return NSAssetKit.predefinedPostiveColor
        case .Warning:
            return NSAssetKit.predefinedWarningColor
        }
    }
