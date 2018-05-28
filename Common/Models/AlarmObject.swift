//
//  Alarms.swift
//  Nightscouter
//
//  Created by Peter Ina on 9/27/16.
//  Copyright © 2016 Peter Ina. All rights reserved.
//

import Foundation

public struct AlarmObject: Codable {
    public let warning: Bool
    public let urgent: Bool
    public let isAlarmingForSgv: Bool
    public let isSnoozed: Bool
    public let snoozeText: String
    public let snoozeTimeRemaining: Int
    public var audioFileURL: URL {
        let assetName = urgent ? "alarm2" : "alarm"
        let bundle: Bundle = Bundle(for: SitesDataSource.self)
        let path: String = bundle.path(forResource: assetName, ofType: "mp3") ?? ""
        let audioUrl = URL(fileURLWithPath: path)
        return audioUrl
    }

}

extension AlarmObject: Equatable {
    public static func ==(lhs: AlarmObject, rhs: AlarmObject) -> Bool {
        return (lhs.warning == rhs.warning && lhs.urgent == rhs.urgent && lhs.isAlarmingForSgv == rhs.isAlarmingForSgv && rhs.snoozeTimeRemaining == lhs.snoozeTimeRemaining)
    }
}
