//
//  ParseConfigurationOperation.swift
//  Nightscouter
//
//  Created by Peter Ina on 9/15/16.
//  Copyright © 2016 Nothingonline. All rights reserved.
//

import Foundation

public class ParseConfigurationOperation: NightscouterBaseOperation {
    
    var configuration: ServerConfiguration?
    
    public convenience init(withJSONData data: Data) {
        self.init()
        self.name = "Parse JSON for Nightscout Server Configuration"
        self.data = data
    }
    
    override func parse(JSONData data: Data) {
        
        guard let stringVersion = String(data: data, encoding: String.Encoding.utf8) else {
            let apiError = NightscoutRESTClientError(line: #line, column: #column, kind: .couldNotCreateDataFromDownloadedFile)
            self.error = apiError
            
            return
        }

        if self.isCancelled { return }

        do {
            let cleanedData = stringVersion.replacingOccurrences(of: "+", with: "").data(using: .utf8)!
            let object: [String: Any] = try JSONSerialization.jsonObject(with: cleanedData, options: .allowFragments) as! [String: Any]
            
            self.configuration = ServerConfiguration.decode(object)
            
            return
        } catch let error {
            let apiError = NightscoutRESTClientError(line: #line, column: #column, kind: .invalidJSON(error))
            self.error = apiError
            
            return
        }
    }
    
}
