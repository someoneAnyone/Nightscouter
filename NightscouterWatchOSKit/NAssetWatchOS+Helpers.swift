//
//  NAssetWatchOS+Helpers.swift
//  Nightscouter
//
//  Created by Peter Ina on 11/12/15.
//  Copyright © 2015 Peter Ina. All rights reserved.
//

import UIKit
// Mapping theme colors to desired color state. (Neutral, Alert, Positive, Warning).

// I need to move this somewehre else if watchentry struct is going to be shared across ios and watchos.
public func colorForDesiredColorState(_ desiredState: DesiredColorState) -> UIColor {
    switch (desiredState) {
    case .Neutral:
        return NSAssetKitWatchOS.predefinedNeutralColor
    case .Alert:
        return NSAssetKitWatchOS.predefinedAlertColor
    case .Positive:
        return NSAssetKitWatchOS.predefinedPostiveColor
    case .Warning:
        return NSAssetKitWatchOS.predefinedWarningColor
    }
}
