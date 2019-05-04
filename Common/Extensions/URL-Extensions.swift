//
//  NSURL-Extensions.swift
//
//

import Foundation

//  MARK: NSURL Validation
//  Modified by Peter
//  Created by James Hickman on 11/18/14.
//  Copyright (c) 2014 NitWit Studios. All rights reserved.
public extension URL
{
    struct ValidationQueue {
        public static var queue = OperationQueue()
    }
    
    enum ValidationError: Error {
        case empty(String)
        case onlyPrefix(String)
        case containsWhitespace(String)
        case couldNotCreateURL(String)
    }
    
    static func validateUrl(_ urlString: String?) throws -> URL {
        // Description: This function will validate the format of a URL, re-format if necessary, then attempt to make a header request to verify the URL actually exists and responds.
        // Return Value: This function has no return value but uses a closure to send the response to the caller.
        var formattedUrlString : String?
        
        // Ignore Nils & Empty Strings
        if (urlString == nil || urlString == "")
        {
            throw ValidationError.empty("Url String was empty")
        }
        
        // Ignore prefixes (including partials)
        let prefixes = ["http://www.", "https://www.", "www."]
        for prefix in prefixes
        {
            if ((prefix.range(of: urlString!, options: .caseInsensitive, range: nil, locale: nil)) != nil){
                throw ValidationError.onlyPrefix("Url String was prefix only")
            }
        }
        
        // Ignore URLs with spaces (NOTE - You should use the below method in the caller to remove spaces before attempting to validate a URL)
        let range = urlString!.rangeOfCharacter(from: CharacterSet.whitespaces)
        if let _ = range {
            throw ValidationError.containsWhitespace("Url String cannot contain whitespaces")
        }
        
        // Check that URL already contains required 'http://' or 'https://', prepend if it does not
        formattedUrlString = urlString
        if (!formattedUrlString!.hasPrefix("http://") && !formattedUrlString!.hasPrefix("https://"))
        {
            formattedUrlString = "https://"+urlString!
        }
        
        guard let finalURL = URL(string: formattedUrlString!) else {
            throw ValidationError.couldNotCreateURL("Url could not be created.")
        }
        
        return finalURL
    }
    
    static func validateUrl(_ urlString: String?, completion:@escaping (_ success: Bool,_ urlString: String? , _ error: String) -> Void)
    {
        let parsedURL = try? validateUrl(urlString)
        
        // Check that an NSURL can actually be created with the formatted string
        if let validatedUrl = parsedURL //NSURL(string: formattedUrlString!)
        {
            // Test that URL actually exists by sending a URL request that returns only the header response
            var request = URLRequest(url: validatedUrl)
            request.httpMethod = "HEAD"
            
            ValidationQueue.queue.maxConcurrentOperationCount = 1
            
            let session = URLSession(configuration: URLSessionConfiguration.default, delegate: nil, delegateQueue: ValidationQueue.queue)
            
            let task = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error :Error?) in
                let url = request.url!.absoluteString
                
                // URL failed - No Response
                if (error != nil)
                {
                    completion(false, url, "The url: \(url) received no response")
                    return
                }
                
                // URL Responded - Check Status Code
                if let urlResponse = response as? HTTPURLResponse
                {
                    if ((urlResponse.statusCode >= 200 && urlResponse.statusCode < 400) || urlResponse.statusCode == 405) // 200-399 = Valid Responses, 405 = Valid Response (Weird Response on some valid URLs)
                    {
                        completion(true, url, "The url: \(url) is valid!")
                        return
                    }
                    else // Error
                    {
                        completion(false, url, "The url: \(url) received a \(urlResponse.statusCode) response")
                        return
                    }
                }

            })
            
            task.resume()
            
        }
    }
}

// Created by Pete
// inspired by https://github.com/ReactiveCocoa/ReactiveCocoaIO/blob/master/ReactiveCocoaIO/NSURL%2BTrailingSlash.m
// MARK: Detect and remove trailing forward slash in URL.
public extension URL {
    var hasTrailingSlash: Bool {
        return self.absoluteString.hasSuffix("/")
    }
    
    var appendTrailingSlash: URL? {
        
        if !self.hasTrailingSlash, let newURL = URL(string: self.absoluteString + "/") {
            return newURL
        }
        
        return nil
    }
    
    var deletedTrailingSlash: URL? {
        var urlString = self.absoluteString
        if let i = urlString.index(of: "/") {
                     urlString.remove(at: i)
            return URL(string: urlString)
        }

        return nil
    }
    
}
