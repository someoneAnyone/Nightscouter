//
//  DownloadConfigurationOperation.swift
//  Nightscouter
//
//  Created by Peter Ina on 9/30/16.
//  Copyright © 2016 Peter Ina. All rights reserved.
//

import Foundation

class DownloadOperation: Operation {
    
    var request: URLRequest
    
    var data: Data?
    var error: NightscoutRESTClientError?

    public init(withURLRequest request: URLRequest) {
        self.request = request
        super.init()
        self.name = "Download data from \(request.url)"
    }
    
    override func main() {
        
        if self.isCancelled { return }
        
        let disGroup = DispatchGroup()
        
        disGroup.enter()
        
        let serverConfigTask = URLSession.shared.downloadTask(with: self.request) { (location, response, error) in
            print(">>> serverConfigTask task is complete. <<<")
            //print(">>> downloadTask: {\nlocation: \(location),\nresponse: \(response),\nerror: \(error)\n} <<<")
            
            if self.isCancelled { return }
            
            if let err = error {
                let apiError = NightscoutRESTClientError(line: #line, column: #column, kind: .unknown(err.localizedDescription))
                self.error = apiError
                return
            }
            
            // Is there a file at the location provided?
            guard let location = location else {
                let apiError = NightscoutRESTClientError(line: #line, column: #column, kind: .downloadedLocationIsMissing)
                self.error = apiError
                return
            }
            
            guard let dataFromLocation = try? Data(contentsOf: location) else {
                let apiError = NightscoutRESTClientError(line: #line, column: #column, kind: .couldNotCreateDataFromDownloadedFile)
                self.error = apiError
                return
            }
            
            self.data = dataFromLocation
    
            disGroup.leave()
        }

        serverConfigTask.resume()

        disGroup.wait()
    }
}
