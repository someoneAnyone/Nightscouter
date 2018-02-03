//
//  DownloadConfigurationOperation.swift
//  Nightscouter
//
//  Created by Peter Ina on 9/30/16.
//  Copyright © 2016 Peter Ina. All rights reserved.
//

import Foundation

class DownloadOperation: Operation, URLSessionDelegate, URLSessionDownloadDelegate  {
    
    @objc var request: URLRequest
    
    @objc var data: Data?
    var error: NightscoutRESTClientError?
    @objc var isBackground: Bool
    @objc var disGroup: DispatchGroup?
    
    @objc var downloadTask: URLSessionDownloadTask?
    
    @objc public init(withURLRequest request: URLRequest, isBackground background: Bool) {
        self.request = request
        self.isBackground = background
        
        super.init()
        
        let config = !isBackground ? URLSessionConfiguration.default :
            URLSessionConfiguration.background(withIdentifier: NightscoutRESTClientError.errorDomain)
        
        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        
        downloadTask = session.downloadTask(with: self.request)
        
        self.name = "Download data from \(String(describing: request.url))"
    }
    
    override func cancel() {
        downloadTask?.cancel()
        super.cancel()
    }
    
    override func main() {
        
        if self.isCancelled { return }
        
        disGroup = DispatchGroup()
        disGroup?.enter()
 
        downloadTask?.resume()
        disGroup?.wait()
    }
    
    //MARK: session delegate
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        print("session error: \(String(describing: error?.localizedDescription)).")
        if let err = error {
            let apiError = NightscoutRESTClientError(line: #line, column: #column, kind: .unknown(err.localizedDescription))
            self.error = apiError
            disGroup?.leave()
            return
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
        print("session \(session) has finished the download task \(downloadTask) of URL \(location).")
        
        guard let dataFromLocation = try? Data(contentsOf: location) else {
            let apiError = NightscoutRESTClientError(line: #line, column: #column, kind: .couldNotCreateDataFromDownloadedFile)
            self.error = apiError
            disGroup?.leave()
            return
        }
        
        self.data = dataFromLocation
        disGroup?.leave()
        
        return
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let err = error {
            let apiError = NightscoutRESTClientError(line: #line, column: #column, kind: .unknown(err.localizedDescription))
            self.error = apiError
            disGroup?.leave()
            
            return
        }
    }
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        print("background session \(session) finished events.")
        
        if let sessionId = session.configuration.identifier {
            print(sessionId)
            
            disGroup?.leave()

        }
    }
    
}
