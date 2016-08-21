//
//  HTTPClient.swift
//  Nightscouter
//
//  Created by Peter Ina on 2/13/16.
//  Copyright © 2016 Peter Ina. All rights reserved.
//

import Foundation

public class HTTPClient {
    
    enum RequestMethod: String {
        case GET
        case POST
        case PUT
        case DELETE
    }
    
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
    
    private let url: NSURL
    private let baseURL: NSURL
    private let pebbleURL: NSURL
    private let entriesURL: NSURL
    private let statusURL: NSURL
    private let calsURL: NSURL
    
    internal let NightscoutAPIErrorDomain: String = "com.nightscout.nightscouter.api"
    
    public typealias JSON = AnyObject
    public typealias JSONDictionary = Dictionary<String, JSON>
    public typealias JSONArray = Array<JSONDictionary>
    public typealias EntryArray = Array<Entry>
    
    
    // MARK: Lifecycle
    
    init(url: NSURL) {
        self.url = url
        self.pebbleURL = NSURL(string: URLPart.Pebble, relativeToURL: url)!
        self.baseURL = url.URLByAppendingPathComponent(URLPart.ApiVersion)
        self.entriesURL = baseURL.URLByAppendingPathComponent(URLPart.Entries).URLByAppendingPathExtension(URLPart.FileExtension)
        self.statusURL = baseURL.URLByAppendingPathComponent(URLPart.Status).URLByAppendingPathExtension(URLPart.FileExtension)
        self.calsURL = baseURL.URLByAppendingPathComponent(URLPart.Entries).URLByAppendingPathComponent(URLPart.Cals).URLByAppendingPathExtension(URLPart.FileExtension)
    }
    
    
    
    
    lazy var config: NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
    lazy var session: NSURLSession = NSURLSession(configuration: self.config)
    
    
    func fetchSiteData() {        
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = RequestMethod.GET.rawValue
        request.cachePolicy = NSURLRequestCachePolicy.ReloadIgnoringCacheData
        
            let downloadTask = session.dataTaskWithRequest(request) {
            (
            let data, let response, let error) in
            
            guard let _:NSData = data, let _:NSURLResponse = response  where error == nil else {
                print("error")
                return
            }
            
            let dataString = NSString(data: data!, encoding: NSUTF8StringEncoding)
            print(dataString)
            
        }
        downloadTask.resume()
    }
}