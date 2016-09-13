//
//  NightscoutAPIClient.swift
//  Nightscouter
//
//  Created by Peter Ina on 6/26/15.
//  Copyright (c) 2015 Peter Ina. All rights reserved.
//
import Foundation
/*:
Create protocol for setting base URL, API Token, etc...
*/
public protocol NightscoutAPIClientDelegate {
    func nightscoutAPIClient(_ nightscoutAPIClient: NightscoutAPIClient, usingNetwork: Bool) -> Void
}

// TODO: Create a queue of requests... and make this a singleton.

internal let NightscoutAPIErrorDomain: String = "com.nightscout.nightscouter.api"

public typealias JSON = Any
public typealias JSONDictionary = Dictionary<String, JSON>
public typealias JSONArray = Array<JSONDictionary>
public typealias EntryArray = Array<Entry>

internal struct URLPart {
    static let ApiVersion = "api/v1"
    static let Entries = "entries"
    static let Pebble = "pebble"
    static let CountParameter = "count"
    static let Status = "status"
    static let Cals = "cal"
    static let ExperimentTest = "experiments/test"
    
    static let FileExtension = "json"
}

internal struct HeaderPart {
    static let APISecretKey = "api-secret"
    static let ContentTypeKey = "Content-Type"
    static let ContentTypeValueApplicationJSON = "application/json"
}

public enum NightscoutAPIError: CustomStringConvertible {
    case noError
    case downloadErorr(String)
    case dataError(String)
    case jsonParseError(String)
    
    public var description: String {
        switch self {
        case .noError: return "No Error"
        case .dataError(let err): return err
        case .downloadErorr(let err): return err
        case .jsonParseError(let err): return err
        }
    }
}

public struct NightscoutAPIClientNotification {
    public static let DataIsStaleUpdateNow: String =  "data.stale.update"
    public static let DataUpdateSuccessful: String = "data.update.successful"
}

open class NightscoutAPIClient {
    
    lazy var config: URLSessionConfiguration = URLSessionConfiguration.default
    lazy var session: URLSession = URLSession(configuration: self.config)
    
    open var url: URL!
    
    open var delegate: NightscoutAPIClientDelegate?
    
    open var task: URLSessionDownloadTask?
    
    fileprivate var apiSecret: String?
    
    var headers = [String: String]()
    
    /*! Initializes the calss with a Nightscout site URL.
    * \param url This class only needs the base URL to the site. For example, https://nightscout.hostingcompany.com, the class will discover the API. Currently uses veriion 1.
    * \apiSecret ?.
    *
    */
    public init(url: URL, apiSecret: String? = nil) {
        self.url = url
        self.apiSecret = apiSecret
        
        headers[HeaderPart.ContentTypeKey] = HeaderPart.ContentTypeValueApplicationJSON
        
        if let apiSecret = self.apiSecret {
            headers[HeaderPart.APISecretKey] = apiSecret
        }
    }
    
    fileprivate convenience init() {
        self.init(url: URL(string: "https://nscgm.herokuapp.com")!)
    }
}

// MARK: - Meat and Potatoes of the API
extension NightscoutAPIClient {
    public func fetchDataForEntries(_ count: Int = 1, completetion:@escaping (_ entries: EntryArray?, _ errorCode: NightscoutAPIError) -> Void) {
        //        let entriesWithCountURL = self.stringForEntriesWithCount(count)
        //find[type]=cal&count=1
        
        let cleanString = "find[type]"
        let queryItemType = URLQueryItem(name: cleanString, value: "sgv")
        let queryItemCount = URLQueryItem(name: URLPart.CountParameter, value: "\(count)")
        
        var urlComponents = URLComponents(url: self.urlForEntries, resolvingAgainstBaseURL: true)
        urlComponents?.queryItems = [queryItemType, queryItemCount]
        
        self.fetchJSONWithURL(urlComponents?.url, completetion: { (result, errorCode) -> Void in
            if let entries = result as? JSONArray {
                var finalArray = Array<Entry>()
                for jsonDictionary: JSONDictionary in entries {
                    let entry: Entry = Entry(jsonDictionary: jsonDictionary)
                    finalArray.append(entry)
                }
                completetion(finalArray, errorCode)
            } else {
                completetion(nil, errorCode)
            }
        })
    }
    
    public func fetchDataForWatchEntry(_ completetion:@escaping (_ watchEntry: WatchEntry?, _ errorCode: NightscoutAPIError) -> Void) {
        let watchEntryUrl = self.urlForWatchEntry
        self.fetchJSONWithURL(watchEntryUrl, completetion: { (result, errorCode) -> Void in
            if let jsonDictionary = result as? JSONDictionary {
                let watchEntry: WatchEntry = WatchEntry(watchEntryDictionary: jsonDictionary)
                completetion(watchEntry, errorCode)
            } else {
                completetion(nil, errorCode)
            }
        })
    }
    
    public func fetchCalibrations(_ count: Int = 1, completetion:@escaping (_ calibrations: [Entry]?, _ errorCode: NightscoutAPIError) -> Void) {
        //find[type]=cal&count=1
        let queryItemCount = URLQueryItem(name: URLPart.CountParameter, value: "\(count)")
        
        var urlComponents = URLComponents(url: self.urlForCalibrations, resolvingAgainstBaseURL: true)
        urlComponents?.queryItems = [queryItemCount]
        
        self.fetchJSONWithURL(urlComponents?.url, completetion: { (result, errorCode) -> Void in
            if let entries = result as? JSONArray {
                var finalArray = Array<Entry>()
                for jsonDictionary: JSONDictionary in entries {
                    let entry: Entry = Entry(jsonDictionary: jsonDictionary)
                    finalArray.append(entry)
                }
                completetion(finalArray, errorCode)
            } else {
                completetion(nil, errorCode)
            }
        })
    }
    
    internal func postExperiments() {
        let request = NSMutableURLRequest(url: self.urlForExperimentTest)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        // request.HTTPBody = "postData"
        
//        let dataTask = session.dataTask(with: request) { (data, response, error) in
//            
//        //sharedSession.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
//            if (error != nil) {
//                print(error)
//            } else {
//                let httpResponse = response as? HTTPURLResponse
//                print(httpResponse)
//            }
//        }
//        
//        dataTask.resume()
    }
    
}

// MARK: - Convenience Methods
extension NightscoutAPIClient {
    var baseURL: URL {
        return url.appendingPathComponent(URLPart.ApiVersion)
    }
    
    var entriesString: URL {
        return baseURL.appendingPathComponent(URLPart.Entries).appendingPathExtension(URLPart.FileExtension)
    }
    
    var urlForWatchEntry: URL {
        return URL(string: URLPart.Pebble, relativeTo: url)!
    }
    
    var urlForStatus: URL {
        let temp = baseURL.appendingPathComponent(URLPart.Status).appendingPathExtension(URLPart.FileExtension)
        return temp
    }
    
    internal var urlForEntries: URL {
        let temp = baseURL.appendingPathComponent(URLPart.Entries).appendingPathExtension(URLPart.FileExtension)
        return temp
    }
   
    internal var urlForCalibrations: URL {
        return baseURL.appendingPathComponent(URLPart.Entries).appendingPathComponent(URLPart.Cals).appendingPathExtension(URLPart.FileExtension)
    }
    
    internal var urlForExperimentTest: URL {
        let temp = baseURL.appendingPathComponent(URLPart.ExperimentTest)
        return temp
    }
    
}

// MARK: - Private Methods
private extension NightscoutAPIClient {
    
    func useNetwork(_ showIndicator: Bool) {
        if let delegate = self.delegate {
            delegate.nightscoutAPIClient(self, usingNetwork: showIndicator)
        }
    }
    
    func fetchJSONWithURL(_ url: URL!, completetion:@escaping (_ result: JSON?, _ errorCode: NightscoutAPIError) -> Void) {
        
        useNetwork(true)
        
        
let downloadTask: URLSessionDownloadTask = session.downloadTask(with: url) { (location, response, downloadError) in
    
    
    
//    let downloadTask: URLSessionDownloadTask = sharedSession.downloadTask(with: url, completionHandler: { (location: URL?, response: URLResponse?, downloadError: NSError?) -> Void in
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200:
                    
                    guard let locationURL = location else {
                        completetion(nil, .downloadErorr("Data did not have a valid location on disk."))
                        return
                    }
                    if let dataObject: Data = try? Data(contentsOf: locationURL) {
                        var stringVersion = String(data: dataObject, encoding: String.Encoding.utf8) //NSString(data: dataObject, encoding: String.Encoding.utf8.rawValue)
                        stringVersion = stringVersion?.replacingOccurrences(of: "+", with: "")
                        
                        if let newData = stringVersion?.data(using: String.Encoding.utf8) {
                            var jsonError: NSError?
                            do {
                                let responseObject: Any = try JSONSerialization.jsonObject(with: newData, options: .allowFragments)
                                if (jsonError != nil) {
                                    print("jsonError")
                                    completetion(nil, .jsonParseError("There was a problem processing the JSON data. Error code: \(jsonError)"))
                                    
                                } else {
                                    completetion(responseObject, .noError)
                                    
                                    DispatchQueue.main.async(execute: { () -> Void in
                                        NotificationCenter.default.post(Notification(name:Notification.Name(rawValue: NightscoutAPIClientNotification.DataUpdateSuccessful), object: self))
                                    })
                                    
                                }
                            } catch let error as NSError {
                                jsonError = error
                                print("Could not create a response object")
                                completetion(nil, .dataError("Could not create a response object from given data."))
                                
                            } catch {
                                fatalError()
                            }
                        } else {
                            print("Could not create clean data for json processor")
                            completetion(nil, .dataError("Failed to create data for json."))
                        }
                    }
                    
                default:
                    print("GET request not successful. HTTP status code: \(httpResponse.statusCode)")
                    completetion(nil, .downloadErorr("GET request not successful. HTTP status code: \(httpResponse.statusCode), fullError: \(downloadError)"))
                    
                }
            } else {
                print("Error: Not a valid HTTP response")
                completetion(nil, .downloadErorr("There was a problem downloading data. Error code: \(downloadError)"))
            }
            self.useNetwork(false)
        }
        
        downloadTask.resume()
    }
}


// MARK - New Fetch Methods

public final class Box<A> {
    public let value: A
    
    init(_ value: A) {
        self.value = value
    }
}

public enum Result<A> {
    case error(NSError)
    case value(Box<A>)
}

extension NightscoutAPIClient {
    public func fetchServerConfiguration(_ callback: @escaping (Result<ServerConfiguration>) -> Void) {
        let settingsUrl = self.urlForStatus
        
        self.fetchJSONWithURL(settingsUrl, callback: { (result) -> Void in
            switch result {
            case let .error(error):
                // display error message
                print("Recieved an error fetching Configuration: \(error)")
                callback(.error(error))
                
            case let .value(boxedConfiguration):
                let result: JSON = boxedConfiguration.value
                if let settingsDictionary = result as? JSONDictionary {
                    let settingObject: ServerConfiguration = ServerConfiguration(jsonDictionary: settingsDictionary)
                    callback(.value(Box(settingObject)))
                }
            }
        })
    }
}

private extension NightscoutAPIClient {
    
    func fetchJSONWithURL(_ url: URL!, callback: @escaping (Result<JSON>) -> Void) {
        
        task = session.downloadTask(with: url, completionHandler: { (location, urlResponse, downloadError) -> Void in
            
            // if the response returned an error send it to the callback
            if let err = downloadError {
                print("Recieved an error DOWNLOADING: \(downloadError)")
                callback(.error(err as NSError))
                return
            }
            
            if let httpResponse = urlResponse as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200:
                    
                    if let dataObject: Data = try? Data(contentsOf: location!) {
                        // Converting data to a string, then removing bad characters found in the Nightscout JSON
                        var dataConvertedToString = NSString(data: dataObject, encoding: String.Encoding.utf8.rawValue)
                        // Apple's JSON Serializer has a problem with + notation for large numbers. I've observed this happening in intercepts.
                        dataConvertedToString = dataConvertedToString?.replacingOccurrences(of: "+", with: "") as NSString?
                        
                        // Converting string back into data so it can be processed into JSON.
                        if let newData: Data = dataConvertedToString?.data(using: String.Encoding.utf8.rawValue) {
                            var jsonErrorOptional: NSError?
                            let jsonOptional: JSON!
                            do {
                                jsonOptional = try JSONSerialization.jsonObject(with: newData, options: JSONSerialization.ReadingOptions.allowFragments)
//                                jsonOptional = try JSONSerialization.jsonObject(with: newData, options: JSONSerialization.ReadingOptions(rawValue: 0))
                            } catch let error as NSError {
                                jsonErrorOptional = error
                                jsonOptional = nil
                            } catch {
                                fatalError()
                            }
                            
                            // if there was an error parsing the JSON send it back
                            if let err = jsonErrorOptional {
                                callback(.error(err))
                                return
                            }
                            
                            callback(.value(Box(jsonOptional)))
                            return
                        }
                    }
                    
                default:
                    // hhtpResonse other than 200
                    callback(.error(NSError(domain: NightscoutAPIErrorDomain, code: -220, userInfo: nil)))
                }
            }
            
            // if we couldn't parse all the properties then send back an error
            callback(.error(NSError(domain: NightscoutAPIErrorDomain, code: -420, userInfo: nil)))
        })
        
        task!.resume()
    }
}



/**
 Creates and returns a new debounced version of the passed block which will postpone its execution until after wait seconds have elapsed since the last time it was invoked.
 It is like a bouncer at a discotheque. He will act only after you shut up for some time.
 This technique is important if you have action wich should fire on update, however the updates are to frequent.
 
 Inspired by debounce function from underscore.js ( http://underscorejs.org/#debounce )
 */

public func debounce(delay: Int, queue: DispatchQueue = DispatchQueue.main, action: @escaping (()->()) ) -> ()->() {
    var lastFireTime   = DispatchTime.now()
    let dispatchDelay  = DispatchTimeInterval.seconds(delay)
    
    return {
        lastFireTime     = DispatchTime.now()
        let dispatchTime: DispatchTime = lastFireTime + dispatchDelay
        queue.asyncAfter(deadline: dispatchTime) {
            let when: DispatchTime = lastFireTime + dispatchDelay
            let now = DispatchTime.now()
            if now.rawValue >= when.rawValue {
                action()
            }
        }
    }
}


//public func dispatch_debounce_block(_ wait : TimeInterval, queue : DispatchQueue = DispatchQueue.main, block : @escaping ()->()) -> ()->() {
//    var cancelable : ()->()!
//    return {
//        cancelable()
//        cancelable = dispatch_after_cancellable(DispatchTime.now() + Double(Int64(wait * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), queue: queue, block: block)
//    }
//}

// Big thanks to Claus Höfele for this function
// https://gist.github.com/choefele/5e5a981ed731472b80d9
//func dispatch_after_cancellable(_ when: DispatchTime, queue: DispatchQueue, block: @escaping ()->()) -> () -> Void {
//    var isCancelled = false
//    queue.asyncAfter(deadline: when) {
//        if !isCancelled {
//            block()
//        }
//    }
//    
//    return {
//        isCancelled = true
//    }
//}
