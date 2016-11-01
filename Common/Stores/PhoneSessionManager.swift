

import WatchConnectivity

protocol WatchSessionManagerDelegate {
    func session(session: WCSession, didReceiveContext context: [String: AnyObject])
}

public class WatchSessionManager: NSObject, WCSessionDelegate, SessionManagerType {
    
    public static let sharedManager = WatchSessionManager()
    
    /// The store that the session manager should interact with.
    public var store: SiteStoreType?
    
    private override init() {
        
        super.init()
    }
    
    private let session: WCSession? = WCSession.isSupported() ? WCSession.default() : nil
    
    var validSession: WCSession? {
        
        // paired - the user has to have their device paired to the watch
        // watchAppInstalled - the user must have your watch app installed
        
        // Note: if the device is paired, but your watch app is not installed
        // consider prompting the user to install it for a better experience
        
        if let session = session, session.isPaired && session.isWatchAppInstalled {
            return session
        }
        return nil
    }
    
    public func startSession() {
        #if DEBUG
            print(">>> Entering \(#function) <<<")
        #endif
        
        session?.delegate = self
        session?.activate()
        
        #if DEBUG
            print("WCSession.isSupported: \(WCSession.isSupported()), Paired Watch: \(session?.isPaired), Watch App Installed: \(session?.isWatchAppInstalled)")
        #endif
    }
    
    public func updateApplicationContext(_ applicationContext: [String : Any]) throws {
        if let session = validSession {
            do {
                try session.updateApplicationContext(applicationContext)
            } catch let error {
                throw error
            }
        }
    }
    
    @discardableResult
    func processApplicationContext(context: [String : Any]) -> Bool {
        print("processApplicationContext \(context)")
        
        print("Did receive payload: \(context)")
        
        guard let store = store else {
            print("No Store")
            return false
        }
        
        store.handleApplicationContextPayload(context)
        
        return true
    }
    
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print(">>> Entering \(#function) <<<")
        print(session)
        print(activationState)
        print(error ?? "No error")
    }
    
    public func sessionDidDeactivate(_ session: WCSession) {
        print(">>> Entering \(#function) <<<")
        print(session)
    }
    
    public func sessionDidBecomeInactive(_ session: WCSession) {
        print(">>> Entering \(#function) <<<")
        print(session)
    }
    
    public func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("\(#function)")
        print(message)
        self.processApplicationContext(context: message)
    }
    
    public func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        print("\(#function)")
        print(applicationContext)
    }
}
