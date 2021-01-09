/*
See LICENSE folder for this sample’s licensing information.

Abstract:
SessionCommands protocol defines an interface to wrap Watch Connectivity APIs and bridge the UI.
 Its extension implements Watch Connectivity commands.
 Used on both iOS and watchOS.
*/

import UIKit
import WatchConnectivity

// Define an interface to wrap Watch Connectivity APIs and
// bridge the UI. Shared by the iOS app and watchOS app.
//
protocol SessionCommands {
    func updateAppContext(_ context: [String: Any])
    func sendMessage(_ message: [String: Any])
    func sendMessageData(_ messageData: Data)
    func transferUserInfo(_ userInfo: [String: Any])
    func transferFile(_ file: URL, metadata: [String: Any])
    func transferCurrentComplicationUserInfo(_ userInfo: [String: Any])
}

// Implement the commands. Every command handles the communication and notifies clients
// when WCSession status changes or data flows. Shared by the iOS app and watchOS app.
//
extension SessionCommands {
    
    // Update app context if the session is activated and update UI with the command status.
    //
    func updateAppContext(_ context: [String: Any]) {
        var commandStatus = CommandStatus(command: .updateAppContext, phrase: .updated)
        commandStatus.timedSites = TimedSites(context)
        
        guard WCSession.default.activationState == .activated else {
            return handleSessionUnactivated(with: commandStatus)
        }
        do {
            try WCSession.default.updateApplicationContext(context)
        } catch {
            commandStatus.phrase = .failed
            commandStatus.errorMessage = error.localizedDescription
        }
        postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandStatus)
    }

    // Send a message if the session is activated and update UI with the command status.
    //
    func sendMessage(_ message: [String: Any]) {
        var commandStatus = CommandStatus(command: .sendMessage, phrase: .sent)
        commandStatus.timedSites = TimedSites(message)

        guard WCSession.default.activationState == .activated else {
            return handleSessionUnactivated(with: commandStatus)
        }
        
        WCSession.default.sendMessage(message, replyHandler: { replyMessage in
            commandStatus.phrase = .replied
            commandStatus.timedSites = TimedSites(replyMessage)
            self.postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandStatus)

        }, errorHandler: { error in
            commandStatus.phrase = .failed
            commandStatus.errorMessage = error.localizedDescription
            self.postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandStatus)
        })
        postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandStatus)
    }
    
    // Send  a piece of message data if the session is activated and update UI with the command status.
    //
    func sendMessageData(_ messageData: Data) {
        var commandStatus = CommandStatus(command: .sendMessageData, phrase: .sent)
        commandStatus.timedSites = TimedSites(messageData)
        
        guard WCSession.default.activationState == .activated else {
            return handleSessionUnactivated(with: commandStatus)
        }

        WCSession.default.sendMessageData(messageData, replyHandler: { replyData in
            commandStatus.phrase = .replied
            commandStatus.timedSites = TimedSites(replyData)
            self.postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandStatus)

        }, errorHandler: { error in
            commandStatus.phrase = .failed
            commandStatus.errorMessage = error.localizedDescription
            self.postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandStatus)
        })
        postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandStatus)
    }
    
    // Transfer a piece of user info if the session is activated and update UI with the command status.
    // A WCSessionUserInfoTransfer object is returned to monitor the progress or cancel the operation.
    //
    func transferUserInfo(_ userInfo: [String: Any]) {
        var commandStatus = CommandStatus(command: .transferUserInfo, phrase: .transferring)
        commandStatus.timedSites = TimedSites(userInfo)

        guard WCSession.default.activationState == .activated else {
            return handleSessionUnactivated(with: commandStatus)
        }

        commandStatus.userInfoTranser = WCSession.default.transferUserInfo(userInfo)
        postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandStatus)
    }
    
    // Transfer a file if the session is activated and update UI with the command status.
    // A WCSessionFileTransfer object is returned to monitor the progress or cancel the operation.
    //
    func transferFile(_ file: URL, metadata: [String: Any]) {
        var commandStatus = CommandStatus(command: .transferFile, phrase: .transferring)
        commandStatus.timedSites = TimedSites(metadata)

        guard WCSession.default.activationState == .activated else {
            return handleSessionUnactivated(with: commandStatus)
        }
        commandStatus.fileTransfer = WCSession.default.transferFile(file, metadata: metadata)
        postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandStatus)
    }
    
    // Transfer a piece fo user info for current complications if the session is activated
    // and update UI with the command status.
    // a WCSessionUserInfoTransfer object is returned to monitor the progress or cancel the operation.
    //
    func transferCurrentComplicationUserInfo(_ userInfo: [String: Any]) {
        var commandStatus = CommandStatus(command: .transferCurrentComplicationUserInfo, phrase: .failed)
        commandStatus.timedSites = TimedSites(userInfo)

        guard WCSession.default.activationState == .activated else {
            return handleSessionUnactivated(with: commandStatus)
        }
        
        commandStatus.errorMessage = "Not supported on watchOS!"
        
        #if os(iOS)
        if WCSession.default.isComplicationEnabled {
            let userInfoTranser = WCSession.default.transferCurrentComplicationUserInfo(userInfo)
            commandStatus.phrase = .transferring
            commandStatus.errorMessage = nil
            commandStatus.userInfoTranser = userInfoTranser
            
        } else {
            commandStatus.errorMessage = "\nComplication is not enabled!"
        }
        #endif
        
        postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandStatus)
    }
    
    // Post a notification on the main thread asynchronously.
    //
    private func postNotificationOnMainQueueAsync(name: NSNotification.Name, object: CommandStatus) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: name, object: object)
        }
    }

    // Handle the session unactived error. WCSession commands require an activated session.
    //
    private func handleSessionUnactivated(with commandStatus: CommandStatus) {
        var mutableStatus = commandStatus
        mutableStatus.phrase = .failed
        mutableStatus.errorMessage =  "WCSession is not activeted yet!"
        postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandStatus)
    }
}
