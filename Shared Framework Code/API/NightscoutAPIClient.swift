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
    func nightscoutAPIClient(nightscoutAPIClient: NightscoutAPIClient, usingNetwork: Bool) -> Void
}

// TODO: Create a queue of requests... and make this a singleton.

internal let NightscoutAPIErrorDomain: String = "com.nightscout.nightscouter.api"

public typealias JSON = AnyObject
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

public enum NightscoutAPIError {
    case NoErorr
    case DownloadErorr(String)
    case DataError(String)
    case JSONParseError(String)
}

public struct NightscoutAPIClientNotification {
    public static let DataIsStaleUpdateNow: String =  "data.stale.update"
    public static let DataUpdateSuccessful: String = "data.update.successful"
}

public class NightscoutAPIClient {
    
    lazy var config: NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
    lazy var sharedSession: NSURLSession = NSURLSession(configuration: self.config)
    
    public var url: NSURL!
    
    public var delegate: NightscoutAPIClientDelegate?
    
    public var task: NSURLSessionDownloadTask?
    
    private var apiSecret: String?
    
    var headers = [String: String]()
    
    /*! Initializes the calss with a Nightscout site URL.
    * \param url This class only needs the base URL to the site. For example, https://nightscout.hostingcompany.com, the class will discover the API. Currently uses veriion 1.
    * \apiSecret ?.
    *
    */
    public init(url: NSURL, apiSecret: String? = nil) {
        self.url = url
        self.apiSecret = apiSecret
        
        headers[HeaderPart.ContentTypeKey] = HeaderPart.ContentTypeValueApplicationJSON
        
        if let apiSecret = self.apiSecret {
            headers[HeaderPart.APISecretKey] = apiSecret
        }
    }
    
    internal convenience init() {
        self.init(url: NSURL())
    }
}

// MARK: - Meat and Potatoes of the API
extension NightscoutAPIClient {
    public func fetchDataForEntries(count: Int = 1, completetion:(entries: EntryArray?, errorCode: NightscoutAPIError) -> Void) {
//        let entriesWithCountURL = self.stringForEntriesWithCount(count)
        //find[type]=cal&count=1
        
        let cleanString = "find[type]"
        let queryItemType = NSURLQueryItem(name: cleanString, value: "sgv")
        let queryItemCount = NSURLQueryItem(name: URLPart.CountParameter, value: "\(count)")
        
        let urlComponents = NSURLComponents(URL: self.urlForEntries, resolvingAgainstBaseURL: true)
        urlComponents?.queryItems = [queryItemType, queryItemCount]

        self.fetchJSONWithURL(urlComponents?.URL, completetion: { (result, errorCode) -> Void in
            if let entries = result as? JSONArray {
                var finalArray = Array<Entry>()
                for jsonDictionary: JSONDictionary in entries {
                    let entry: Entry = Entry(jsonDictionary: jsonDictionary)
                    finalArray.append(entry)
                }
                completetion(entries: finalArray, errorCode: errorCode)
            } else {
                completetion(entries: nil, errorCode: errorCode)
            }
        })
    }
    
//    public func fetchDataForWatchEntries(count: Int = 1, completetion:(watchEntries: [WatchEntry]?, errorCode: NightscoutAPIError) -> Void) {
//        // let watchEntryUrl = self.urlForWatchEntry
//        
//        let queryItemCount = NSURLQueryItem(name: URLPart.CountParameter, value: "\(count)")
//        
//        let urlComponents = NSURLComponents(URL: self.urlForWatchEntry, resolvingAgainstBaseURL: true)
//        urlComponents?.queryItems = [queryItemCount]
//        
//        self.fetchJSONWithURL(urlComponents?.URL, completetion: { (result, errorCode) -> Void in
//            
//            if let watchEntries = result as? JSONDictionary {
//                var finalArray = Array<WatchEntry>()
//                for jsonDictionary: JSONDictionary in watchEntries {
//                    let watchEntry: WatchEntry = WatchEntry(watchEntryDictionary: jsonDictionary)
//                    finalArray.append(watchEntry)
//                }
//                completetion(watchEntries: finalArray, errorCode: errorCode)
//            }
//            completetion(watchEntries: nil, errorCode: errorCode)
//            
//        })
//    }
    
    public func fetchDataForWatchEntry(completetion:(watchEntry: WatchEntry?, errorCode: NightscoutAPIError) -> Void) {
        let watchEntryUrl = self.urlForWatchEntry
        self.fetchJSONWithURL(watchEntryUrl, completetion: { (result, errorCode) -> Void in
            if let jsonDictionary = result as? JSONDictionary {
                let watchEntry: WatchEntry = WatchEntry(watchEntryDictionary: jsonDictionary)
                completetion(watchEntry: watchEntry, errorCode: errorCode)
            } else {
                completetion(watchEntry: nil, errorCode: errorCode)
            }
        })
    }
    
    
    public func fetchCalibrations(count: Int = 1, completetion:(calibrations: EntryArray?, errorCode: NightscoutAPIError) -> Void) {
        //find[type]=cal&count=1
        let queryItemCount = NSURLQueryItem(name: URLPart.CountParameter, value: "\(count)")
        
        let urlComponents = NSURLComponents(URL: self.urlForCalibrations, resolvingAgainstBaseURL: true)
        urlComponents?.queryItems = [queryItemCount]
        
        self.fetchJSONWithURL(urlComponents?.URL, completetion: { (result, errorCode) -> Void in
            if let entries = result as? JSONArray {
                var finalArray = Array<Entry>()
                for jsonDictionary: JSONDictionary in entries {
                    let entry: Entry = Entry(jsonDictionary: jsonDictionary)
                    finalArray.append(entry)
                }
                completetion(calibrations: finalArray, errorCode: errorCode)
            } else {
                completetion(calibrations: nil, errorCode: errorCode)
            }
        })
    }
    
    internal func postExperiments() {
        let request = NSMutableURLRequest(URL: self.urlForExperimentTest)
        request.HTTPMethod = "POST"
        request.allHTTPHeaderFields = headers
        // request.HTTPBody = "postData"
        
        let dataTask: NSURLSessionDataTask = sharedSession.dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
            if (error != nil) {
                print(error)
            } else {
                let httpResponse = response as? NSHTTPURLResponse
                print(httpResponse)
            }
        })
        
        dataTask.resume()
    }
    
}

// MARK: - Convenience Methods
extension NightscoutAPIClient {
    var baseURL: NSURL {
        return url.URLByAppendingPathComponent(URLPart.ApiVersion)
    }
    
    var entriesString: NSURL {
        return baseURL.URLByAppendingPathComponent(URLPart.Entries).URLByAppendingPathExtension(URLPart.FileExtension)
    }
    
    var urlForWatchEntry: NSURL {
        return NSURL(string: URLPart.Pebble, relativeToURL: url)!
    }
    
    var urlForStatus: NSURL {
        let temp = baseURL.URLByAppendingPathComponent(URLPart.Status).URLByAppendingPathExtension(URLPart.FileExtension)
        return temp
    }

    internal var urlForEntries: NSURL {
        let temp = baseURL.URLByAppendingPathComponent(URLPart.Entries).URLByAppendingPathExtension(URLPart.FileExtension)
        return temp
    }
//    func stringForEntriesWithCount(count: Int) -> NSURL {
//        let numberOfEntries = "?\(URLPart.CountParameter)=\(count)"
//        return NSURL(string:"\(entriesString)\(numberOfEntries)")!
//    }
    
    internal var urlForCalibrations: NSURL {
        return baseURL.URLByAppendingPathComponent(URLPart.Entries).URLByAppendingPathComponent(URLPart.Cals).URLByAppendingPathExtension(URLPart.FileExtension)
    }
    
    internal var urlForExperimentTest: NSURL {
        let temp = baseURL.URLByAppendingPathComponent(URLPart.ExperimentTest)
        return temp
    }
    
}

// MARK: - Private Methods
private extension NightscoutAPIClient {
    
    func useNetwork(showIndicator: Bool) {
        if let delegate = self.delegate {
            delegate.nightscoutAPIClient(self, usingNetwork: showIndicator)
        }
    }
    
    func fetchJSONWithURL(url: NSURL!, completetion:(result: JSON?, errorCode: NightscoutAPIError) -> Void) {
        
        useNetwork(true)
        
        let downloadTask: NSURLSessionDownloadTask = sharedSession.downloadTaskWithURL(url, completionHandler: { (location: NSURL?, response: NSURLResponse?, downloadError: NSError?) -> Void in
            if let httpResponse = response as? NSHTTPURLResponse {
                switch httpResponse.statusCode {
                case 200:
                    
                    guard let locationURL = location else {
                        completetion(result: nil, errorCode: .DownloadErorr("Data did not have a valid location on disk."))
                        return
                    }
                    if let dataObject: NSData = NSData(contentsOfURL: locationURL) {
                        var stringVersion = NSString(data: dataObject, encoding: NSUTF8StringEncoding)
                        stringVersion = stringVersion?.stringByReplacingOccurrencesOfString("+", withString: "")
                        
                        if let newData = stringVersion?.dataUsingEncoding(NSUTF8StringEncoding) {
                            var jsonError: NSError?
                            do {
                                let responseObject: AnyObject = try NSJSONSerialization.JSONObjectWithData(newData, options: .AllowFragments)
                                if (jsonError != nil) {
                                    print("jsonError")
                                    completetion(result: nil, errorCode: .JSONParseError("There was a problem processing the JSON data. Error code: \(jsonError)"))
                                    
                                } else {
                                    completetion(result: responseObject, errorCode: .NoErorr)
                                    
                                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                        NSNotificationCenter.defaultCenter().postNotification(NSNotification(name:NightscoutAPIClientNotification.DataUpdateSuccessful, object: self))
                                    })
                                    
                                }
                            } catch let error as NSError {
                                jsonError = error
                                print("Could not create a response object")
                                completetion(result: nil, errorCode: .DataError("Could not create a response object from given data."))
                                
                            } catch {
                                fatalError()
                            }
                        } else {
                            print("Could not create clean data for json processor")
                            completetion(result: nil, errorCode: .DataError("Failed to create data for json."))
                        }
                    }
                    
                default:
                    print("GET request not successful. HTTP status code: \(httpResponse.statusCode)")
                    completetion(result: nil, errorCode: .DownloadErorr("GET request not successful. HTTP status code: \(httpResponse.statusCode), fullError: \(downloadError)"))
                    
                }
            } else {
                print("Error: Not a valid HTTP response")
                completetion(result: nil, errorCode: .DownloadErorr("There was a problem downloading data. Error code: \(downloadError)"))
            }
            self.useNetwork(false)
        })
        
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
    case Error(NSError)
    case Value(Box<A>)
}

extension NightscoutAPIClient {
    public func fetchServerConfiguration(callback: (Result<ServerConfiguration>) -> Void) {
        let settingsUrl = self.urlForStatus
        
        self.fetchJSONWithURL(settingsUrl, callback: { (result) -> Void in
            switch result {
            case let .Error(error):
                // display error message
                print("Recieved an error fetching Configuration: \(error)")
                callback(.Error(error))
                
            case let .Value(boxedConfiguration):
                let result: JSON = boxedConfiguration.value
                if let settingsDictionary = result as? JSONDictionary {
                    let settingObject: ServerConfiguration = ServerConfiguration(jsonDictionary: settingsDictionary)
                    callback(.Value(Box(settingObject)))
                }
            }
        })
    }
}

private extension NightscoutAPIClient {
    
    func fetchJSONWithURL(url: NSURL!, callback: (Result<JSON>) -> Void) {
        
        task = sharedSession.downloadTaskWithURL(url, completionHandler: { (location, urlResponse, downloadError) -> Void in
            
            // if the response returned an error send it to the callback
            if let err = downloadError {
                print("Recieved an error DOWNLOADING: \(downloadError)")
                callback(.Error(err))
                return
            }
            
            if let httpResponse = urlResponse as? NSHTTPURLResponse {
                switch httpResponse.statusCode {
                case 200:
                    
                    if let dataObject: NSData = NSData(contentsOfURL: location!) {
                        // Converting data to a string, then removing bad characters found in the Nightscout JSON
                        var dataConvertedToString = NSString(data: dataObject, encoding: NSUTF8StringEncoding)
                        // Apple's JSON Serializer has a problem with + notation for large numbers. I've observed this happening in intercepts.
                        dataConvertedToString = dataConvertedToString?.stringByReplacingOccurrencesOfString("+", withString: "")
                        
                        // Converting string back into data so it can be processed into JSON.
                        if let newData: NSData = dataConvertedToString?.dataUsingEncoding(NSUTF8StringEncoding) {
                            var jsonErrorOptional: NSError?
                            let jsonOptional: JSON!
                            do {
                                jsonOptional = try NSJSONSerialization.JSONObjectWithData(newData, options: NSJSONReadingOptions(rawValue: 0))
                            } catch let error as NSError {
                                jsonErrorOptional = error
                                jsonOptional = nil
                            } catch {
                                fatalError()
                            }
                            
                            // if there was an error parsing the JSON send it back
                            if let err = jsonErrorOptional {
                                callback(.Error(err))
                                return
                            }
                            
                            callback(.Value(Box(jsonOptional)))
                            return
                        }
                    }
                    
                default:
                    // hhtpResonse other than 200
                    callback(.Error(NSError(domain: NightscoutAPIErrorDomain, code: -220, userInfo: nil)))
                }
            }
            
            // if we couldn't parse all the properties then send back an error
            callback(.Error(NSError(domain: NightscoutAPIErrorDomain, code: -420, userInfo: nil)))
        })
        
        task!.resume()
    }
}