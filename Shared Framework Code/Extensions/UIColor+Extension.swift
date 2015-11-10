//
//  UIColor+Extension.swift
//  Nightscouter
//
//  Created by Peter Ina on 11/9/15.
//  Copyright © 2015 Peter Ina. All rights reserved.
//

#if os(iOS) || os(watchOS)
    import UIKit
#endif

extension UIColor {
    class func  randomColor() -> UIColor {
        let randomRed:CGFloat = CGFloat(drand48())
        
        let randomGreen:CGFloat = CGFloat(drand48())
        
        let randomBlue:CGFloat = CGFloat(drand48())
        
        return UIColor(red: randomRed, green: randomGreen, blue: randomBlue, alpha: 1.0)
    }
}

