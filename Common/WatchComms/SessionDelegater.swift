/*
See LICENSE folder for this sample’s licensing information.

Abstract:
SessionDelegater implemments the WCSessionDelegate methods. Used on both iOS and watchOS.
*/

import Foundation
import Combine
import WatchConnectivity
import SwiftUI

#if os(watchOS)
import ClockKit
#endif

// Custom notifications.
// Posted when Watch Connectivity activation or reachibility status is changed,
// or when data is received or sent. Clients observe these notifications to update the UI.
//
extension Notification.Name {
    public static let dataDidFlow = Notification.Name("DataDidFlow")
    public static let activationDidComplete = Notification.Name("ActivationDidComplete")
    public static let reachabilityDidChange = Notification.Name("ReachabilityDidChange")
}

extension WCSessionActivationState: CustomStringConvertible {
    public var description: String {
        switch self {
            case .activated:
                return "Activated"
            case .inactive:
                return "Inactive"
            case .notActivated:
                return "Not Activated"
            @unknown default:
                return "Unknown state"
        }
    }
    
    

    
}

// Implement WCSessionDelegate methods to receive Watch Connectivity data and notify clients.
// WCsession status changes are also handled here.
//
class SessionDelegater: NSObject, WCSessionDelegate, ObservableObject, SessionManagerType, SessionCommands {
    
    
    var store: SiteStoreType?
    
    func startSession() {
        session.activate()
    }
    
    func updateApplicationContext(_ applicationContext: [String : Any]) throws {
        print(applicationContext)
        let text = debounce(delay: 1) {
            self.updateAppContext(applicationContext)
        }

        text()
    }
    
    
    public static let shared = SessionDelegater()
    
    var session: WCSession

    @Published public var isReachable: Bool = false
    @Published public var activationState: String = ""
    @Published public var watchActivated: Bool = false
    
    @Published public var currentCommandStatus: CommandStatus?
        
    private var cancellables = Set<AnyCancellable>()
    
    public override init() {
        
        self.session = WCSession.default
        super.init()
        self.session.delegate = self
//        session.activate()
//
        
        WCSession.default.publisher(for: \.isReachable)
            .receive(on: RunLoop.main)
            .sink { isReachable in
                self.isReachable = isReachable
            }
            .store(in: &cancellables)
        
    
        WCSession.default.publisher(for: \.activationState)
            .receive(on: RunLoop.main)
            .sink { active in
                self.activationState = active.description
                self.watchActivated = active.rawValue == 2 ? true : false
            }
            .store(in: &cancellables)
        
        
        NotificationCenter.default.publisher(for: .dataDidFlow)
            .debounce(for: 0.1, scheduler: RunLoop.main)
            .map( { ($0.object as! CommandStatus) } )
            .sink { status in
                print(status)
                self.currentCommandStatus = status
            }
            .store(in: &cancellables)
        
        
        
    }
    
    // Called when WCSession activation state is changed.
    //
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        postNotificationOnMainQueueAsync(name: .activationDidComplete)
    }
    
    // Called when WCSession reachability is changed.
    //
    func sessionReachabilityDidChange(_ session: WCSession) {
        postNotificationOnMainQueueAsync(name: .reachabilityDidChange)
    }
    
    // Called when an app context is received.
    //
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        var commandStatus = CommandStatus(command: .updateAppContext, phrase: .received)
        commandStatus.timedSites = TimedSites(applicationContext)
        postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandStatus)
    }
    
    // Called when a message is received and the peer doesn't need a response.
    //
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        var commandStatus = CommandStatus(command: .sendMessage, phrase: .received)
        commandStatus.timedSites = TimedSites(message)
        postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandStatus)
    }
    
    // Called when a message is received and the peer needs a response.
    //
    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        self.session(session, didReceiveMessage: message)
        replyHandler(message) // Echo back the time stamp.
    }
    
    // Called when a piece of message data is received and the peer doesn't need a response.
    //
    func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        var commandStatus = CommandStatus(command: .sendMessageData, phrase: .received)
        commandStatus.timedSites = TimedSites(messageData)
                
        postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandStatus)
    }
    
    // Called when a piece of message data is received and the peer needs a response.
    //
    func session(_ session: WCSession, didReceiveMessageData messageData: Data, replyHandler: @escaping (Data) -> Void) {
        self.session(session, didReceiveMessageData: messageData)
        replyHandler(messageData) // Echo back the time stamp.
    }
    
    // Called when a userInfo is received.
    //
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        var commandStatus = CommandStatus(command: .transferUserInfo, phrase: .received)
        commandStatus.timedSites = TimedSites(userInfo)
        
        if let isComplicationInfo = userInfo[PayloadKey.isCurrentComplicationInfo] as? Bool,
            isComplicationInfo == true {
            
            commandStatus.command = .transferCurrentComplicationUserInfo
            
            #if os(watchOS)
            let server = CLKComplicationServer.sharedInstance()
            if let complications = server.activeComplications {
                for complication in complications {
                    // Call this method sparingly. If your existing complication data is still valid,
                    // consider calling the extendTimeline(for:) method instead.
                    server.reloadTimeline(for: complication)
                }
            }
            #endif
        }
        
        postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandStatus)
    }
    
    // Called when sending a userInfo is done.
    //
    func session(_ session: WCSession, didFinish userInfoTransfer: WCSessionUserInfoTransfer, error: Error?) {
        var commandStatus = CommandStatus(command: .transferUserInfo, phrase: .finished)
        commandStatus.timedSites = TimedSites(userInfoTransfer.userInfo)
        
        #if os(iOS)
        if userInfoTransfer.isCurrentComplicationInfo {
            commandStatus.command = .transferCurrentComplicationUserInfo
        }
        #endif

        if let error = error {
            commandStatus.errorMessage = error.localizedDescription
        }
        
        
        DispatchQueue.main.async {
            print("data did flow with \(commandStatus)")
        }
        postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandStatus)
    }
    
    // Called when a file is received.
    //
    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        var commandStatus = CommandStatus(command: .transferFile, phrase: .received)
        commandStatus.file = file
        commandStatus.timedSites = TimedSites(file.metadata!)
        
        // Note that WCSessionFile.fileURL will be removed once this method returns,
        // so instead of calling postNotificationOnMainQueue(name: .dataDidFlow, userInfo: userInfo),
        // we dispatch to main queue SYNCHRONOUSLY.
        //
      
        DispatchQueue.main.sync {
            NotificationCenter.default.post(name: .dataDidFlow, object: commandStatus)
        }
    }
    
    // Called when a file transfer is done.
    //
    func session(_ session: WCSession, didFinish fileTransfer: WCSessionFileTransfer, error: Error?) {
        var commandStatus = CommandStatus(command: .transferFile, phrase: .finished)

        if let error = error {
            commandStatus.errorMessage = error.localizedDescription
            postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandStatus)
            return
        }
        commandStatus.fileTransfer = fileTransfer
        commandStatus.timedSites = TimedSites(fileTransfer.file.metadata!)

        #if os(watchOS)
        if WatchSettings.sharedContainerID.isEmpty == false {
            let defaults = UserDefaults(suiteName: WatchSettings.sharedContainerID)
            if let enabled = defaults?.bool(forKey: WatchSettings.clearLogsAfterTransferred), enabled {
                Logger.shared.clearLogs()
            }
        }
        #endif
        
        postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandStatus)
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
    
    // Post a notification on the main thread asynchronously.
    //
    private func postNotificationOnMainQueueAsync(name: NSNotification.Name, object: CommandStatus? = nil) {
        
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: name, object: object)
        }
    }
}
