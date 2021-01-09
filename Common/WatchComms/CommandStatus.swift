/*
See LICENSE folder for this sample’s licensing information.

Abstract:
CommandStatus struct wraps the command status. Used on both iOS and watchOS.
*/

import UIKit
import WatchConnectivity

// Constants to identify the Watch Connectivity methods, also used as user-visible strings in UI.
//
public enum Command: String, Identifiable {
    public var id: String {
        return self.rawValue
    }
    
    case updateAppContext = "UpdateAppContext"
    case sendMessage = "SendMessage"
    case sendMessageData = "SendMessageData"
    case transferUserInfo = "TransferUserInfo"
    case transferFile = "TransferFile"
    case transferCurrentComplicationUserInfo = "TransferComplicationUserInfo"
}

// Constants to identify the phrases of a Watch Connectivity communication.
//
public enum Phrase: String {
    case updated = "Updated"
    case sent = "Sent"
    case received = "Received"
    case replied = "Replied"
    case transferring = "Transferring"
    case canceled = "Canceled"
    case finished = "Finished"
    case failed = "Failed"
}

// Wrap a timed color payload dictionary with a stronger type.
//
public struct TimedSites {
    public var timeStamp: String
    public var siteData: Data
    
    public var sites: [Site] {
        
        let optional = load(siteData, as: [Site].self) ?? []
        //let optional = try? NSKeyedUnarchiver.unarchivedObject(ofClasses: [UIColor.self], from: colorData)
     
        return optional
    }
    public var timedSites: [String: Any] {
        return [PayloadKey.timeStamp: timeStamp, PayloadKey.siteData: siteData]
    }
    
    init(_ timedSite: [String: Any]) {
        guard let timeStamp = timedSite[PayloadKey.timeStamp] as? String,
            let colorData = timedSite[PayloadKey.siteData] as? Data else {
                fatalError("Timed color dictionary doesn't have right keys!")
        }
        self.timeStamp = timeStamp
        self.siteData = colorData
    }
    
    init(_ timedSites: Data) {
        let data = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(timedSites)
        guard let dictionary = data as? [String: Any] else {
            fatalError("Failed to unarchive a timedColor dictionary!")
        }
        self.init(dictionary)
    }
}

// Wrap the command status to bridge the commands status and UI.
//
public struct CommandStatus {
    public var command: Command
    public var phrase: Phrase
    public var timedSites: TimedSites?
    public var fileTransfer: WCSessionFileTransfer?
    public var file: WCSessionFile?
    public var userInfoTranser: WCSessionUserInfoTransfer?
    public var errorMessage: String?
    
    public init(command: Command, phrase: Phrase) {
        self.command = command
        self.phrase = phrase
    }
}
