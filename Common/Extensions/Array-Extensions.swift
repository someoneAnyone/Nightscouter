//
//  Array+Extensions.swift
//  Nightscouter
//
//  Created by Peter Ina on 1/8/16.
//  Copyright © 2016 Peter Ina. All rights reserved.
//

import Foundation

public extension Array {
    subscript (safe index: Int) -> Element? {
        return indices ~= index ? self[index] : nil
    }
}

public extension Array {
    func difference<T: Equatable>(_ otherArray: [T]) -> [T] {
        var result = [T]()
        
        for e in self {
            if let element = e as? T {
                if !otherArray.contains(element) {
                    result.append(element)
                }
            }
        }
        
        return result
    }
    
    func intersection<T: Equatable>(_ otherArray: [T]) -> [T] {
        var result = [T]()
        
        for e in self {
            if let element = e as? T {
                if otherArray.contains(element) {
                    result.append(element)
                }
            }
        }
        
        return result
    }
}

extension Array where Element: Equatable {
    @discardableResult
    public mutating func insertOrUpdate(_ object: Element) -> Bool {
        if let index = self.index(of: object) {
            self[index] = object
        } else {
            self.append(object)
        }
        
        return self.contains(object)
    }
    
    public mutating func appendUniqueObject(_ object: Element) {
        if contains(object) == false {
            append(object)
        }
    }
    
    public mutating func remove(_ object: Element) -> Bool {
        if let index = self.index(of: object) {
            self.remove(at: index)
        }
        
        return !self.contains(object)
    }
}

extension Array where Element: Dateable {
    public mutating func sorted(byDateDescending descending: Bool = true) {
        let compare: ComparisonResult = descending ? .orderedDescending : .orderedAscending
        self = self.sorted(by: { (d1, d2) -> Bool in
            d1.date.compare(d2.date as Date) == compare
        })
    }
}
public func sortByDate<T: Dateable>(_ a: [T], orderDescending descending: Bool = true) -> [T] {
    let compare: ComparisonResult = descending ? .orderedDescending : .orderedAscending
    return a.sorted(by: { (d1, d2) -> Bool in
        d1.date.compare(d2.date as Date) == compare
    })
}

enum ArrayError: Error {
    case OutOfRange
}

extension Array {
    mutating func move(fromIndex oldIndex: Int, toIndex newIndex: Int) throws {
        if newIndex >= count || newIndex < 0 {
            throw ArrayError.OutOfRange
        }
        insert(remove(at: oldIndex), at: newIndex)
    }
}
