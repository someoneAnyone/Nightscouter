//
//  Extensions.swift
//  Nightscouter
//
//  Created by Peter Ina on 8/16/16.
//  Copyright © 2016 Nothingonline. All rights reserved.
//

import Foundation
// Provide a private typealias for a platform specific color.
#if os(iOS)
    import UIKit
    typealias CollectionView = UICollectionView
#elseif os(OSX)
    import Cocoa
    typealias CollectionView = NSCollectionView
#endif

#if os(iOS)
public extension UINavigationItem {
    @objc public func update(with newItem: UINavigationItem) {
        self.backBarButtonItem = newItem.backBarButtonItem
        self.rightBarButtonItem = newItem.rightBarButtonItem
        self.rightBarButtonItems = newItem.rightBarButtonItems
        self.leftBarButtonItem = newItem.leftBarButtonItem
        self.leftBarButtonItems = newItem.leftBarButtonItems
        self.title = newItem.title
        self.titleView = newItem.titleView
        self.prompt = newItem.prompt
        self.backBarButtonItem = newItem.backBarButtonItem
        self.hidesBackButton = newItem.hidesBackButton
    }
}


public extension UIEdgeInsets {
    public init(with uniformInset: CGFloat) {
        self.init(top: uniformInset, left: uniformInset, bottom: uniformInset, right: uniformInset)
    }
    
    public var totalHorizontal: CGFloat {
        return left + right
    }
    
    public var totalVertical: CGFloat {
        return top + bottom
    }
}

extension CALayer {
    
    @objc func setupDefaultShaddow(cornerRadius: CGFloat = 0) {
        
        let pathBounds = bounds
        let cornerRadius = cornerRadius
        
        let shaddowLayer = self
        shaddowLayer.shadowOffset = CGSize(width: 0, height: 2)
        shaddowLayer.shadowRadius = 2.0
        shaddowLayer.shadowOpacity = 0.9
        shaddowLayer.masksToBounds = false
        shaddowLayer.shadowPath = UIBezierPath(roundedRect: pathBounds, cornerRadius: cornerRadius).cgPath
        shaddowLayer.shouldRasterize = true
        shaddowLayer.rasterizationScale = UIScreen.main.scale
    }
    
    @objc func setupGradient(with colors:[UIColor] = [#colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), UIColor.lightGray]) {
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.frame = bounds
        gradient.colors = colors.map{ $0.cgColor }
        
        let gradientLayer = self
        
        gradientLayer.insertSublayer(gradient, at: 0)
    }
    
}

public extension UIView {
    @objc public class func fromNib(nibNameOrNil: String? = nil) -> Self {
        return fromNib(nibNameOrNil: nibNameOrNil, type: self)
    }
    
    public class func fromNib<T : UIView>(nibNameOrNil: String? = nil, type: T.Type) -> T {
        let v: T? = fromNib(nibNameOrNil: nibNameOrNil, type: T.self)
        
        return v!
    }
    
    public class func fromNib<T : UIView>(nibNameOrNil: String? = nil, type: T.Type) -> T? {
        var view: T?
        let name: String
        if let nibName = nibNameOrNil {
            name = nibName
        } else {
            // Most nibs are demangled by practice, if not, just declare string explicitly
            name = nibName
        }
        let nibViews = Bundle.main.loadNibNamed(name, owner: nil, options: nil)
        for v in nibViews! {
            if let tog = v as? T {
                view = tog
            }
        }
        return view
    }
    
    @objc public class var nibName: String {
        let name = "\(self)".components(separatedBy: ".").first ?? ""
        return name
    }
    
    @objc public class var nib: UINib? {
        if let _ = Bundle.main.path(forResource: nibName, ofType: "nib") {
            return UINib(nibName: nibName, bundle: nil)
        } else {
            return nil
        }
    }
}
#endif

public extension CollectionView {
    @objc public var indexPathOfItemAtCenter: IndexPath? {
        let visiblePoint = CGPoint(x: self.center.x + self.contentOffset.x, y: self.center.y + self.contentOffset.y)
        return self.indexPathForItem(at: visiblePoint)
    }
}

public extension IndexPath {
    public static var zero: IndexPath {
        return IndexPath(item: 0, section: 0)
    }
}
