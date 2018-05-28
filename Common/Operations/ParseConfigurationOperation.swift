//
//  ParseConfigurationOperation.swift
//  Nightscouter
//
//  Created by Peter Ina on 9/15/16.
//  Copyright © 2016 Nothingonline. All rights reserved.
//

import Foundation

public class ParseConfigurationOperation: Operation, NightscouterOperation {

    internal var error: NightscoutRESTClientError?
    @objc internal var data: Data?
    var configuration: ServerConfiguration?
    
    @objc public convenience init(withJSONData data: Data?) {
        self.init()
        self.name = "Parse JSON for Nightscout Server Configuration"
        self.data = data
    }
    
    public override func main() {

        guard let data = data, let stringVersion = String(data: data, encoding: String.Encoding.utf8) else {
            let apiError = NightscoutRESTClientError(line: #line, column: #column, kind: .couldNotCreateDataFromDownloadedFile)
            self.error = apiError
            
            return
        }

        if self.isCancelled { return }

        do {
            
            let cleanedData = stringVersion.replacingOccurrences(of: "+", with: "").data(using: .utf8)!
            let decoder = JSONDecoder()
            let configuration = try decoder.decode(ServerConfiguration.self, from: cleanedData)

            self.configuration = configuration
            
            return
        } catch let error {
            let apiError = NightscoutRESTClientError(line: #line, column: #column, kind: .invalidJSON(error))
            self.error = apiError
            
            return
        }
    }
    
}
