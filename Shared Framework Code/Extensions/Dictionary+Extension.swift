//
//  Dictionary+Extension.swift
//  Nightscouter
//
//  Created by Peter Ina on 3/2/16.
//  Copyright © 2016 Peter Ina. All rights reserved.
//

import Foundation

public extension Dictionary where Key: StringLiteralConvertible, Value: AnyObject {
    public func saveAsPlist(fileName: String = "data") -> (successful: Bool, path: NSURL?) {
        guard let rootPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first else {
            print("No documents directory!")
            return (false, nil)
        }
        
        let url = NSURL(fileURLWithPath: rootPath)
        let plistPathInDocument = url.URLByAppendingPathComponent("\(fileName).plist")
        let dict = NSDictionary(objects: self.values.map{ $0 }, forKeys: self.keys.map{ String($0) })
        let ret = dict.writeToFile(plistPathInDocument.absoluteString, atomically: true)
        // print(ret)
        //let resultDictionary = NSMutableDictionary(contentsOfFile: plistPathInDocument.absoluteString)
        //print("Saved GameData.plist file is --> \(resultDictionary?.description)")
        
        return (ret, plistPathInDocument)
    }
}
