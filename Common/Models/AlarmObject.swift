//
//  Alarms.swift
//  Nightscouter
//
//  Created by Peter Ina on 9/27/16.
//  Copyright © 2016 Peter Ina. All rights reserved.
//

import Foundation

public struct AlarmObject {
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

extension AlarmObject: Encodable, Decodable {
    struct JSONKey {
        static let warning = "warning"
        static let urgent = "urgent"
        static let isAlarmingForSgv = "isAlarmingForSgv"
        static let isSnoozed = "isSnoozed"
        static let snoozeText = "snoozeText"
        static let snoozeTimeRemaining = "snoozeTimeRemaining"
    }
    
    public func encode() -> [String : Any] {
        return [
            JSONKey.warning: warning,
            JSONKey.urgent: urgent,
            JSONKey.isAlarmingForSgv: isAlarmingForSgv,
            JSONKey.isSnoozed: isSnoozed,
            JSONKey.snoozeText: snoozeText,
            JSONKey.snoozeTimeRemaining: snoozeTimeRemaining,
        ]
    }
    
    public static func decode(_ dict: [String : Any]) -> AlarmObject? {
        guard
            let warning = dict[JSONKey.warning] as? Bool,
            let urgent = dict[JSONKey.urgent] as? Bool,
            let isAlarmingForSgv = dict[JSONKey.isAlarmingForSgv] as? Bool,
            let isSnoozed = dict[JSONKey.isSnoozed] as? Bool,
            let snoozeText = dict[JSONKey.snoozeText] as? String,
            let snoozeTimeRemaining = dict[JSONKey.snoozeTimeRemaining] as? Int
            else {
                return nil
        }
        
        return AlarmObject(warning: warning, urgent: urgent, isAlarmingForSgv: isAlarmingForSgv, isSnoozed: isSnoozed, snoozeText: snoozeText, snoozeTimeRemaining: snoozeTimeRemaining)
    }
}
