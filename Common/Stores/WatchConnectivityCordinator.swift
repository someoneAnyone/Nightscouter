//
//  WatchConnectivityCordinator.swift
//  Nightscouter
//
//  Created by Peter Ina on 11/25/17.
//  Copyright © 2017 Peter Ina. All rights reserved.
//

import UIKit
import WatchConnectivity

#if os(watchOS)
import ClockKit
#endif

// Constants to access the payload dictionary.
// isCurrentComplicationInfo is used to tell if the userInfo is from transferCurrentComplicationUserInfo
// in session:didReceiveUserInfo: (see WCSessionDelegate).
//
struct PayloadKey {
    static let timeStamp = "timeStamp"
    static let siteData = "siteData"
    static let isCurrentComplicationInfo = "isCurrentComplicationInfo"
    static let primarySiteUUID = "primarySiteUUID"
    
}

// Constants to organize and access the information in the notication userInfo dictionary.
//
public struct UserInfoKey {
    public static let channel = "Channel"
    public static let phrase = "Phrase"
    public static let siteData = "siteData"
    public static let error = "Error"
    public static let activationStatus = "ActivationStatus"
    public static let reachable = "Reachable"
    public static let fileURL = "fileURL"
}

// Constants to identify the Watch Connectivity methods, also used as user-visible strings in UI.
//
public enum Channel: String {
    case updateAppContext = "UpdateAppContext"
    case sendMessage = "SendMessage"
    case sendMessageData = "SendMessageData"
    case transferUserInfo = "TransferUserInfo"
    case transferFile = "TransferFile"
    case transferCurrentComplicationUserInfo = "TransferCurrentComplicationUserInfo"
}

// Constants to identify the phrases of a Watch Connectivity communication,
// also shown in the logs on the iOS side.
//
public enum Phrase: String {
    case updated = "Updated"
    case sent = "Sent"
    case received = "Received"
    case replied = "Replied"
    case transferring = "Transferring"
    case finished = "Finished"
    case failed = "Failed"
}

class WatchConnectivityCordinator: NSObject, SessionDataProvider {
    
    static let shared = WatchConnectivityCordinator()
    
    var store: SiteStoreType?
    
    // private: prevent clients from creating another instance.
    //
    private override init() {
        super.init()
    }
    
    func startSession() {
        print(">>> Entering \(#function) <<<")
        
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
         
            
            NotificationCenter.default.addObserver(
                self, selector: #selector(type(of:self).dataUpdated(_:)),
                name: .nightscoutDataUpdatedNotification, object: nil
            )
            
        }
    }
    
    @objc func dataUpdated(_ notification: Notification) {
        send(dataProvider: self, channel: .sendMessage)
    }
    
    // Update app context
    //
    private func updateAppContext(dataProvider: SessionDataProvider) -> [String: Any] {
        let payload = dataProvider.appContext
        
        var userInfo: [String: Any] = [UserInfoKey.channel: Channel.updateAppContext,
                                       UserInfoKey.siteData: payload,
                                       UserInfoKey.phrase: Phrase.updated]
        do {
            try WCSession.default.updateApplicationContext(payload)
            self.postNotificationOnMainQueue(name: .dataDidFlow, userInfo: userInfo)

        }
        catch {
            userInfo[UserInfoKey.error] = error.localizedDescription
        }
        
        return userInfo
    }
    
    // Send a message immdediately.
    //
    private func sendMessage(dataProvider: SessionDataProvider) -> [String: Any] {
        let payload = dataProvider.message
        
        var userInfo: [String: Any] = [UserInfoKey.channel: Channel.sendMessage,
                                       UserInfoKey.siteData: payload,
                                       UserInfoKey.phrase: Phrase.sent]
        
        WCSession.default.sendMessage(payload, replyHandler: { replyMessage in
            
            userInfo[UserInfoKey.siteData] = replyMessage
            userInfo[UserInfoKey.phrase] = Phrase.replied
            self.postNotificationOnMainQueue(name: .dataDidFlow, userInfo: userInfo)
            
        }, errorHandler: { error in
            userInfo[UserInfoKey.error] = error.localizedDescription
            self.postNotificationOnMainQueue(name: .dataDidFlow, userInfo: userInfo)
        })
        
        return userInfo
    }
    
    // Send a piece of message data immediately
    //
    private func sendMessageData(dataProvider: SessionDataProvider) -> [String: Any] {
        var userInfo: [String: Any] = [UserInfoKey.channel: Channel.sendMessageData,
                                       UserInfoKey.phrase: Phrase.sent]
        
        let payload = dataProvider.messageData
        
        let data = NSKeyedUnarchiver.unarchiveObject(with: payload)
        if let timedColor = data as? [String: Any] {
            userInfo[UserInfoKey.siteData] = timedColor
        }
        
        WCSession.default.sendMessageData(payload, replyHandler: { replyData in
            
            let data = NSKeyedUnarchiver.unarchiveObject(with: replyData)
            if let timedColor = data as? [String: Any] {
                userInfo[UserInfoKey.siteData] = timedColor
            }
            userInfo[UserInfoKey.phrase] = Phrase.replied
            self.postNotificationOnMainQueue(name: .dataDidFlow, userInfo: userInfo)
            
        }, errorHandler: { error in
            
            userInfo[UserInfoKey.error] = error.localizedDescription
            self.postNotificationOnMainQueue(name: .dataDidFlow, userInfo: userInfo)
        })
        
        return userInfo
    }
    
    // Transfer a piece of user info
    // a WCSessionUserInfoTransfer object is returned to monitor the progress or cancel the operation.
    //
    private func transferUserInfo(dataProvider: SessionDataProvider) -> [String: Any] {
        let payload = dataProvider.userInfo
        WCSession.default.transferUserInfo(payload)
        
        return [UserInfoKey.channel: Channel.transferUserInfo,
                UserInfoKey.siteData: payload,
                UserInfoKey.phrase: Phrase.transferring]
    }
    
    // Transfer a file.
    // A WCSessionFileTransfer object is returned to monitor the progress or cancel the operation.
    //
    private func transferFile(dataProvider: SessionDataProvider) -> [String: Any] {
        let metadata = dataProvider.fileMetaData
//        WCSession.default.transferFile(dataProvider.file, metadata: metadata)
        
        return [UserInfoKey.channel: Channel.transferFile,
                UserInfoKey.siteData: metadata,
                UserInfoKey.phrase: Phrase.transferring]
    }
    
    // Transfer a piece fo user info for current complications
    // a WCSessionUserInfoTransfer object is returned to monitor the progress or cancel the operation.
    //
    private func transferCurrentComplicationUserInfo(dataProvider: SessionDataProvider) -> [String: Any] {
        let payload = dataProvider.currentComplicationInfo
        
        var userInfo: [String: Any] = [UserInfoKey.channel: Channel.transferCurrentComplicationUserInfo,
                                       UserInfoKey.siteData: payload,
                                       UserInfoKey.phrase: Phrase.failed,
                                       UserInfoKey.error: "Not supported on watchOS!"]
        #if os(iOS)
        userInfo[UserInfoKey.error] = "\nComplication is not enabled!"
        
        if WCSession.default.isComplicationEnabled {
            WCSession.default.transferCurrentComplicationUserInfo(payload)
            
            userInfo[UserInfoKey.phrase] = Phrase.transferring
            userInfo[UserInfoKey.error] = nil // Clear the default value.
        } else {
            return transferUserInfo(dataProvider: dataProvider)
        }
        #endif
        return userInfo
    }
    
    // Post a notification on the main thread asynchronously.
    //
    func postNotificationOnMainQueue(name: NSNotification.Name, object: Any? = nil,
                                     userInfo: [AnyHashable : Any]? = nil) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: name, object: object, userInfo: userInfo)
        }
    }
    
    // Send data provided by the passed-in data provider to the paired peer, and post a notfication
    // for client to update the UI
    // For sendMessage and sendMessageData, post a notification when the data is sent, then another
    // one when the data is replied or an error occurs.
    //
    func send(dataProvider: SessionDataProvider, channel: Channel) {
        
        guard WCSession.default.activationState == .activated else {
            let userInfo: [String: Any] = [UserInfoKey.channel: channel,
                                           UserInfoKey.error: "WCSession is not activeted yet!",
                                           UserInfoKey.phrase: Phrase.failed]
            postNotificationOnMainQueue(name: .dataDidFlow, userInfo: userInfo)
            return
        }
        
        // Use the specified channel to send the data. Fill the notification user info at the same time.
        //
        let userInfo: [String: Any]
        
        switch channel {
        case .updateAppContext:
            userInfo = updateAppContext(dataProvider: dataProvider)
            
        case .sendMessage:
            userInfo = sendMessage(dataProvider: dataProvider)
            
        case .sendMessageData:
            userInfo = sendMessageData(dataProvider: dataProvider)
            
        case .transferUserInfo:
            userInfo = transferUserInfo(dataProvider: dataProvider)
            
        case .transferFile:
            userInfo = transferFile(dataProvider: dataProvider)
            
        case .transferCurrentComplicationUserInfo:
            userInfo = transferCurrentComplicationUserInfo(dataProvider: dataProvider)
        }
        
        postNotificationOnMainQueue(name: .dataDidFlow, userInfo: userInfo)
    }
   
}

extension WatchConnectivityCordinator: WCSessionDelegate {
    // Called when WCSession activation state is changed.
    //
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        let userInfo: [String : Any] = [UserInfoKey.activationStatus: activationState]
        postNotificationOnMainQueue(name: .activationDidComplete, userInfo: userInfo)
    }
    
    // Called when WCSession reachability is changed.
    //
    func sessionReachabilityDidChange(_ session: WCSession) {
        let userInfo: [String : Any] = [UserInfoKey.reachable: session.isReachable]
        postNotificationOnMainQueue(name: .reachabilityDidChange, userInfo: userInfo)
    }
    
    // Called when an app context is received.
    //
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        let userInfo: [String : Any] = [UserInfoKey.channel: Channel.updateAppContext,
                                        UserInfoKey.phrase: Phrase.received,
                                        UserInfoKey.siteData: applicationContext]
        postNotificationOnMainQueue(name: .dataDidFlow, userInfo: userInfo)
    }
    
    // Called when a message is received and the peer doesn't need a response.
    //
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        let userInfo: [String : Any] = [UserInfoKey.channel: Channel.sendMessage,
                                        UserInfoKey.phrase: Phrase.received,
                                        UserInfoKey.siteData: message]
        postNotificationOnMainQueue(name: .dataDidFlow, userInfo: userInfo)
    }
    
    // Called when a message is received and the peer needs a response.
    //
    func session(_ session: WCSession, didReceiveMessage message: [String : Any],
                 replyHandler: @escaping ([String : Any]) -> Void) {
        self.session(session, didReceiveMessage: message)
        replyHandler(message) // Echo back the time stamp.
    }
    
    // Called when a piece of message data is received and the peer doesn't need a response.
    //
    func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        var userInfo: [String : Any] = [UserInfoKey.channel: Channel.sendMessageData,
                                        UserInfoKey.phrase: Phrase.received]

        let data = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(messageData)
        
//        let data = NSKeyedUnarchiver.unarchiveObject(with: messageData)
        if let siteData = data as? [String: Any] {
            userInfo[UserInfoKey.siteData] = siteData
        }
        else {
            userInfo[UserInfoKey.error] = "Invalid site data!"
        }
        postNotificationOnMainQueue(name: .dataDidFlow, userInfo: userInfo)
    }
    
    // Called when a piece of message data is received and the peer needs a response.
    //
    func session(_ session: WCSession, didReceiveMessageData messageData: Data, replyHandler: @escaping (Data) -> Void) {
        self.session(session, didReceiveMessageData: messageData)
        replyHandler(messageData) // Echo back the time stamp.
    }
    
    // Called when a userInfo is received.
    //
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        var channel: Channel = .transferUserInfo
        
        if let isComplicationInfo = userInfo[PayloadKey.isCurrentComplicationInfo] as? Bool, isComplicationInfo {
            channel = .transferCurrentComplicationUserInfo
            
            #if os(watchOS)
            let server = CLKComplicationServer.sharedInstance()
            if let complications = server.activeComplications {
                for complication in complications {
                    //Call this method sparingly. If your existing complication data is still valid,
                    //consider calling the extendTimeline(for:) method instead.
                    server.reloadTimeline(for: complication)
                }
            }
            #endif
        }
        
        let myUserInfo: [String : Any] = [UserInfoKey.channel: channel,
                                          UserInfoKey.phrase: Phrase.received,
                                          UserInfoKey.siteData: userInfo]
        postNotificationOnMainQueue(name: .dataDidFlow, userInfo: myUserInfo)
    }
    
    // Called when sending a userInfo is done.
    //
    func session(_ session: WCSession, didFinish userInfoTransfer: WCSessionUserInfoTransfer, error: Error?) {
        var channel: Channel = .transferUserInfo
        
        #if os(iOS)
        if userInfoTransfer.isCurrentComplicationInfo {
            channel = .transferCurrentComplicationUserInfo
        }
        #endif
        
        var userInfo: [String : Any] = [UserInfoKey.channel: channel,
                                        UserInfoKey.phrase: Phrase.finished,
                                        UserInfoKey.siteData: userInfoTransfer.userInfo]
        if let error = error {
            userInfo[UserInfoKey.error] = error.localizedDescription
        }
        postNotificationOnMainQueue(name: .dataDidFlow, userInfo: userInfo)
    }
    
    // Called when a file is received.
    //
    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        var userInfo: [String : Any] = [UserInfoKey.channel: Channel.transferFile,
                                        UserInfoKey.phrase: Phrase.received,
                                        UserInfoKey.fileURL: file.fileURL]
        
        if let fileMetadata = file.metadata {
            userInfo[UserInfoKey.siteData] = fileMetadata
        }
        
        // Note that WCSessionFile.fileURL will be removed once this method returns,
        // so instead of calling postNotificationOnMainQueue(name: .dataDidFlow, userInfo: userInfo),
        // we dispatch to main queue SYNCHRONOUSLY.
        //
        DispatchQueue.main.sync {
            NotificationCenter.default.post(name: .dataDidFlow, object: nil, userInfo: userInfo)
        }
    }
    
    // Called when a file transfer is done.
    //
    func session(_ session: WCSession, didFinish fileTransfer: WCSessionFileTransfer, error: Error?) {
        var userInfo: [String : Any] = [UserInfoKey.channel: Channel.transferFile,
                                        UserInfoKey.phrase: Phrase.finished]
        
        if let fileMetadata = fileTransfer.file.metadata {
            userInfo[UserInfoKey.siteData] = fileMetadata
        }
        
        if let error = error {
            userInfo[UserInfoKey.error] = error.localizedDescription
        }
        else {
            
            if AppConfiguration.sharedApplicationGroupSuiteName.isEmpty {
            } else {
                let defaults = UserDefaults(suiteName: AppConfiguration.sharedApplicationGroupSuiteName)
                if let enabled = defaults?.bool(forKey: AppConfiguration.sharedApplicationGroupSuiteName), enabled {
                   // FileLogger.shared.clearLogs()
                }
            }
        }
        postNotificationOnMainQueue(name: .dataDidFlow, userInfo: userInfo)
    }
    
    // WCSessionDelegate methods for iOS only.
    //
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("\(#function): activationState = \(session.activationState.rawValue)")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        // Activate the new session after having switched to a new watch.
        session.activate()
    }
    
    func sessionWatchStateDidChange(_ session: WCSession) {
        print("\(#function): activationState = \(session.activationState.rawValue)")
    }
    #endif
    
    
    
}

