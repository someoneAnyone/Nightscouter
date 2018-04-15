//
//  SessionDataProvider.swift
//  Nightscouter
//
//  Created by Peter Ina on 2/6/18.
//  Copyright © 2018 Peter Ina. All rights reserved.
//

import Foundation


// Defines the interfaces to provide payload for Watch Connectivity APIs
// ViewController and InterfaceController adopt this protocol to work with SessionCoordinator
//
public protocol SessionDataProvider {
    var appContext: [String: Any] { get }
    
    var message: [String: Any] { get }
    var messageData: Data { get }
    
    var userInfo: [String: Any] { get }
    
    //    var file: URL { get }
    var fileMetaData: [String: Any] { get }
    
    var currentComplicationInfo: [String: Any] { get }
    
}

// This protocol extension provides an implementation to generate a default payload, which contains
// a random color and a time stamp. ViewController and InterfaceController thus don't need to
// provide their own implementation.
//
extension SessionDataProvider {
    
    // Generate a dictionary containing a time stamp and a random color data
    //
    private func timedColor() -> [String: Any] {
        
        let plist = PropertyListEncoder()
        do {
            let encodedSites = try plist.encode(SitesDataSource.sharedInstance.sites)
            
            let dateFormatter = DateFormatter()
            dateFormatter.timeStyle = .medium
            let timeString = dateFormatter.string(from: Date())
            
            return [PayloadKey.timeStamp: timeString, PayloadKey.siteData: encodedSites]
            
        } catch {
            return [:]
        }
    }
    
    // Generate an app context, used as the payload for updateApplicationContext
    //
    public var appContext: [String: Any] {
        return timedColor()
    }
    
    // Generate a message, used as the payload for sendMessage.
    //
    public var message: [String: Any] {
        return timedColor()
    }
    
    // Generate a message, used as the payload for sendMessageData.
    //
    public var messageData: Data {
        return NSKeyedArchiver.archivedData(withRootObject: timedColor())
    }
    
    // Generate a userInfo dictionary, used as the payload for transferUserInfo.
    //
    public var userInfo: [String: Any] {
        return timedColor()
    }
    
    // Generate a file URL, used as the payload for transferFile.
    //    //
    //    var file: URL {
    //        return FileLogger.shared.fileURL
    //    }
    
    // Generate a file metadata dictionary, used as the payload for transferFile.
    //
    public var fileMetaData: [String: Any] {
        return timedColor()
    }
    
    // Generate a complication info dictionary, used as the payload for transferCurrentComplicationUserInfo,
    //
    public var currentComplicationInfo: [String: Any] {
        var complicationInfo = timedColor()
        complicationInfo[PayloadKey.isCurrentComplicationInfo] = true
        return complicationInfo
    }
}
