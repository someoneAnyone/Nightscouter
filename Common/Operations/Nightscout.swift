//
//  GetConfigurationOperation.swift
//  Nightscouter
//
//  Created by Peter Ina on 8/18/16.
//  Copyright © 2016 Nothingonline. All rights reserved.
//

import Foundation

/// Need to do some conversion here... still need figure out how.
extension String {
    func sha1() -> String {
        // Temp extension
        return self
    }
}

private let API_DOMAIN = "com.Nightscout.RESTClient"

public struct NightscoutRESTClientError: Error {
    /// The domain of the error.
    public static var errorDomain: String = API_DOMAIN
    
    public let line: Int
    public let column: Int
    public let kind: ErrorKind
    
    public enum ErrorKind: CustomStringConvertible {
        case downloadedLocationIsMissing
        case couldNotCreateDataFromDownloadedFile
        case invalidJSON(Error?)
        case unknown(String)
        
        public var description: String {
            switch  self {
            case .downloadedLocationIsMissing:
                return "The file required for the app was not downloaded was not available."
            case .couldNotCreateDataFromDownloadedFile:
                return "The contents of the file were not able to be converted to data."
            case .invalidJSON:
                return "The file could not be parsed correctly."
            case .unknown:
                return "Don't know why this was thrown go investigate and fix it."
            }
        }
    }
}

internal protocol NightscouterOperation {
    var data: Data? { set get }
    var error: NightscoutRESTClientError? { set get }
}

public protocol NightscoutDownloaderDelegate {
    func nightscout(_ downloader: NightscoutDownloader, didEndWithError error: NightscoutRESTClientError?)
    func nightscout(_ downloader: NightscoutDownloader, didCompleteTask: String)
}

public class NightscoutDownloader {
    
    // MARK: - Variables
    
    static public var sharedInstance: NightscoutDownloader = NightscoutDownloader()
    
    private let processingQueue: OperationQueue = OperationQueue()
    
    
    // MARK: - Private Variables
    
    private var hostURL: URL? = nil
    private var apiSecret: String? = nil
    
    internal var isBackground: Bool = false
    
    private enum APIRoutes: String {
        case status,
        entries,
        devicestatus
    }
    
    
    // MARK: - Private Methods
    
    private func urlRequest(forAPIRoute APIRoute: APIRoutes = .status, url: URL) -> URLRequest {
        
        var headers = [String: String]()
        // Set the headers.
        // 1. Content type.
        headers["Content-Type"] = "application/json"
        // 2. Provide the API key, passphrase or api-secret token. User of the api prvides a string and this will convert to a SHA1 string.
        headers["api-secret"] = apiSecret?.sha1()
        
        let pathExtension = "json"
        
        let apiVersion = "api/v1"
        
        var requestURL = url.appendingPathComponent("\(apiVersion)/\(APIRoute.rawValue)").appendingPathExtension(pathExtension)
        
        if APIRoute == .entries {
            
            //let today = Date()
            //let twoHoursBefore = today.addingTimeInterval(-60*120)
            
            // Get the current data from REST-Call
            // let findStringStart: String = "[date][$gte]=\(today.timeIntervalSince1970.millisecond)"
            // let findQueryItemStart = URLQueryItem(name: "find", value: findStringStart)
            // let findStringEnd: String = "[date][$lte]=\(twoHoursBefore.timeIntervalSince1970.millisecond)"
            // let findQueryItemEnd = URLQueryItem(name: "find", value: findStringEnd)
            
            let entryCount = 300
            let countQueryItem = URLQueryItem(name: "count", value: "\(entryCount)")
            var comps = URLComponents(url: requestURL, resolvingAgainstBaseURL: true)
            comps!.queryItems = [countQueryItem]
            
            requestURL = comps!.url!
        }
        
        
        var request = URLRequest(url: requestURL)
        
        for (headerField, headerValue) in headers {
            request.setValue(headerValue, forHTTPHeaderField: headerField)
        }
        
        return request
    }
    
    // MARK: - Public Methods
    
    private init() {
        processingQueue.name = API_DOMAIN
    }
    
    //TODO: Need to wrap this up into a new class and an Operation block, that can be canceled as well as monitored.
    public func networkRequest(forNightscoutURL url: URL, apiPassword password: String? = nil, completion:@escaping (_ configuration: ServerConfiguration?,_ sensorGlucoseValues: [SensorGlucoseValue]?, _ calibrations: [Calibration]?, _ meteredGlucoseValues:[MeteredGlucoseValue]?, _ deviceStatus: [DeviceStatus]?, _ error: NightscoutRESTClientError?) -> Void) {
        
        print(">>> Entering \(#function) for \(url) <<<")
        
        // processingQueue.cancelAllOperations()
        
        self.hostURL = url
        self.apiSecret = password
        
        
        var configuration: ServerConfiguration?
        var sgvs: [SensorGlucoseValue]?
        var mbgs: [MeteredGlucoseValue]?
        var cals: [Calibration]?
        var device: [DeviceStatus]?
        
        // Need to propgate the errors back up to the UI.
        var entriesError: NightscoutRESTClientError?
        var serverConfigError: NightscoutRESTClientError?
        var deviceError: NightscoutRESTClientError?
        
        // set up the config request chain
        let configRequest = urlRequest(forAPIRoute: .status, url: url)
        let fetchConfig = DownloadOperation(withURLRequest: configRequest, isBackground: isBackground)
        let parseConfig = ParseConfigurationOperation()
        let configAdaptor = BlockOperation {
            parseConfig.data = fetchConfig.data
            parseConfig.error = fetchConfig.error
        }
        
        parseConfig.completionBlock = {
            configuration = parseConfig.configuration
            serverConfigError = parseConfig.error
            
            if let serverConfigError = serverConfigError {
                self.processingQueue.cancelAllOperations()
                OperationQueue.main.addOperation {
                    completion(nil, nil, nil, nil, nil, serverConfigError)
                }
            }
        }
        
        configAdaptor.addDependency(fetchConfig)
        parseConfig.addDependency(configAdaptor)
        
        processingQueue.addOperation(fetchConfig)
        processingQueue.addOperation(configAdaptor)
        processingQueue.addOperation(parseConfig)
        
        // Set up the entries request chain
        let downloadReadingsRequest = urlRequest(forAPIRoute: .entries, url: url)
        let fetchEntries = DownloadOperation(withURLRequest: downloadReadingsRequest, isBackground: isBackground)
        let parseEntries = ParseReadingsOperation()
        let entriesAdaptor = BlockOperation {
            parseEntries.data = fetchEntries.data
            parseEntries.error = fetchEntries.error
        }
        
        parseEntries.completionBlock = {
            sgvs = parseEntries.sensorGlucoseValues
            mbgs = parseEntries.meteredGlucoseValues
            cals = parseEntries.calibrations
            
            entriesError = parseEntries.error
            
            if let entriesError = entriesError {
                OperationQueue.main.addOperation {
                    self.processingQueue.cancelAllOperations()
                    completion(configuration, nil, nil, nil, nil, entriesError)
                }
            }
        }
        entriesAdaptor.addDependency(fetchEntries)
        parseEntries.addDependency(entriesAdaptor)
        
        processingQueue.addOperation(fetchEntries)
        processingQueue.addOperation(entriesAdaptor)
        processingQueue.addOperation(parseEntries)
        
        // Set up the device request chain
        let requestDevice = urlRequest(forAPIRoute: .devicestatus, url: url)
        let fetchDevice = DownloadOperation(withURLRequest: requestDevice, isBackground: isBackground)
        let parseDevice = ParseDeviceStatusOperation()
        let deviceAdaptor = BlockOperation {
            parseDevice.data = fetchDevice.data
            parseDevice.error = fetchDevice.error
        }
        
        parseDevice.completionBlock = {
            device = parseDevice.deviceStatus
            deviceError = parseDevice.error
            
            if let deviceError = deviceError {
                self.processingQueue.cancelAllOperations()
                OperationQueue.main.addOperation {
                    completion(configuration, sgvs, cals, mbgs, nil, deviceError)
                }
            }
        }
        
        deviceAdaptor.addDependency(fetchDevice)
        parseDevice.addDependency(deviceAdaptor)
        
        processingQueue.addOperation(fetchDevice)
        processingQueue.addOperation(deviceAdaptor)
        processingQueue.addOperation(parseDevice)
        
        let finishUp = BlockOperation {
            print("Finishing up download and parse.")
            OperationQueue.main.addOperation {
                completion(configuration, sgvs, cals, mbgs, device, nil)
            }
        }
        
        finishUp.addDependency(parseConfig)
        finishUp.addDependency(parseEntries)
        finishUp.addDependency(parseDevice)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { // change 2
            self.processingQueue.addOperation(finishUp)
        }
    }
    
}

public extension Site {
    
    var nightscouterAPI: NightscoutDownloader {
        return NightscoutDownloader.sharedInstance
    }
    
    public func fetchDataFromNetwork(useBackground background: Bool = false, completion:@escaping (_ updatedSite: Site, _ error: NightscoutRESTClientError?) -> Void) {
        
        nightscouterAPI.isBackground = background
        var updatedSite = self
        
        nightscouterAPI.networkRequest(forNightscoutURL: self.url, apiPassword: self.apiSecret) { (config, sgvs, cals, mbgs, devices, err) in
            
            if let error = err {
                print(error.kind)
                // We need to propogate the error to UI.
                updatedSite.disabled = true
                completion(updatedSite, error)
            }
            
            // Process the updates to the site.
            
            if let conf = config {
                updatedSite.configuration = conf
            }
            
            if let sgvs = sgvs {
                updatedSite.sgvs = sgvs
            }
            
            if let mbgs = mbgs {
                updatedSite.mbgs = mbgs
            }
            
            if let cals = cals {
                updatedSite.cals = cals
            }
            
            if let deviceStatus = devices {
                updatedSite.deviceStatuses = deviceStatus
            }
            
            updatedSite.updatedAt = Date()
            updatedSite.generateComplicationData()
            
            completion(updatedSite, nil)
        }
    }
}
