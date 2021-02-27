/*
See LICENSE folder for this sample’s licensing information.

Abstract:
TestDataProvider protocol defines the interface for providing payload for Watch Connectivity APIs.
 Its extension provides default payload for the comands.
*/

import UIKit

// Constants to access the payload dictionary.
// isCurrentComplicationInfo is to tell if the userInfo is from transferCurrentComplicationUserInfo
// in session:didReceiveUserInfo: (see SessionDelegater).
//
public struct PayloadKey {
    public static let timeStamp = "timeStamp"
    public static let siteData = "siteData"
    public static let isCurrentComplicationInfo = "isCurrentComplicationInfo"
}

// Constants to identify the app group container used for Settings-Watch.bundle and access
// the information in Settings-Watch.bundle.
//
public struct WatchSettings {
    public static let sharedContainerID = "group.com.nothingonline.nightscouter"
    public static let useLogFileForFileTransfer = "useLogFileForFileTransfer"
    public static let clearLogsAfterTransferred = "clearLogsAfterTransferred"
}

// Define the interfaces for providing payload for Watch Connectivity APIs.
// MainViewController and MainInterfaceController adopt this protocol.
//
protocol SiteDataProvider {
    var appContext: [String: Any] { get }
    
    var message: [String: Any] { get }
    var messageData: Data { get }
    
    var userInfo: [String: Any] { get }
    
    var sites: [Site] { get }
    
    var file: URL { get }
    var fileMetaData: [String: Any] { get }
}

// Generate default payload for commands, which contains a random color and a time stamp.
//
extension SiteDataProvider {
    
    // Generate a dictionary containing a time stamp and a random color data.
    //
     func timedSiteData() -> [String: Any] {
   
        let data = try? JSONEncoder().encode(sites)
        
        guard let siteData = data else { fatalError("Failed to archive a Nightscouter sites!") }
    
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .medium
        let timeString = dateFormatter.string(from: Date())
        
        return [PayloadKey.timeStamp: timeString, PayloadKey.siteData: siteData]
    }
    
    // Generate an app context, used as the payload for updateApplicationContext.
    //
    var appContext: [String: Any] {
        return timedSiteData()
    }

    // Generate a message, used as the payload for sendMessage.
    //
    var message: [String: Any] {
        return timedSiteData()
    }
    
    // Generate a message, used as the payload for sendMessageData.
    //
    var messageData: Data {
        let data = try? NSKeyedArchiver.archivedData(withRootObject: timedSiteData(), requiringSecureCoding: false)
        guard let timedColor = data else { fatalError("Failed to archive a timedColor dictionary!") }
        return timedColor
    }

    // Generate a userInfo dictionary, used as the payload for transferUserInfo.
    //
    var userInfo: [String: Any] {
        return timedSiteData()
    }

    // Generate a file URL, used as the payload for transferFile.
    //
    // Use WatchSettings to choose the log file, which is generated by Logger
    // for debugging purpose, for file transfer from the watch side.
    // This is only for watchOS as the iOS app doesn't have WKBackgroundTask.
    //
    var file: URL {
        #if os(watchOS)
        if WatchSettings.sharedContainerID.isEmpty == false {
            let defaults = UserDefaults(suiteName: WatchSettings.sharedContainerID)
            if let enabled = defaults?.bool(forKey: WatchSettings.useLogFileForFileTransfer), enabled {
                return Logger.shared.getFileURL()
            }
        }
        #endif
        
        // Use Info.plist for file transfer.
        // Change this to a bigger file to make the file transfer progress more obvious.
        //
        guard let url = Bundle.main.url(forResource: "Info", withExtension: "plist") else {
            fatalError("Failed to find Info.plist in current bundle!")
        }
        return url
    }

    // Generate a file metadata dictionary, used as the payload for transferFile.
    //
    var fileMetaData: [String: Any] {
        return timedSiteData()
    }
    
    // Generate a complication info dictionary, used as the payload for transferCurrentComplicationUserInfo.
    //
    var currentComplicationInfo: [String: Any] {
        var complicationInfo = timedSiteData()
        complicationInfo[PayloadKey.isCurrentComplicationInfo] = true
        return complicationInfo
    }
}