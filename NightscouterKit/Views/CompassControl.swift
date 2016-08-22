//
//  CompassView.swift
//  Nightscout Watch Face
//
//  Created by Peter Ina on 4/30/15.
//  Copyright (c) 2015 Peter Ina. All rights reserved.
//

import UIKit

@IBDesignable
public class CompassControl: UIView {
    
    @IBInspectable public var sgvText:String = "---" {
        didSet{
            setNeedsDisplay()
        }
    }
    var angle: CGFloat = 0
    var isUncomputable = false
    var isDoubleUp = false
    var isArrowVisible = false
    
    @IBInspectable public var color: UIColor = NSAssetKit.predefinedNeutralColor {
        didSet {
            setNeedsDisplay()
        }
    }
    
    public override func intrinsicContentSize() -> CGSize {
        return CGSizeMake(156, 196)
    }
    
    var animationValue: CGFloat = 0
    @IBInspectable public var delta: String = "- --/--" {
        didSet{
            setNeedsDisplay()
        }
    }
  
    public var direction: Direction = .None {
        didSet {
            switch direction {
            case .None:
                configireDrawRect(isArrowVisible: false)
            case .DoubleUp:
                configireDrawRect(true)
            case .SingleUp:
                configireDrawRect()
            case .FortyFiveUp:
                configireDrawRect(angle:-45)
            case .Flat:
                configireDrawRect(angle:-90)
            case .FortyFiveDown:
                configireDrawRect(angle:-120)
            case .SingleDown:
                configireDrawRect(angle:-180)
            case .DoubleDown:
                configireDrawRect(true, angle: -180)
            case .NotComputable, .Not_Computable:
                configireDrawRect(isArrowVisible: false, isUncomputable: true)
            case .RateOutOfRange:
                configireDrawRect(isArrowVisible: false, isUncomputable: true, sgvText: direction.description)
            }
                setNeedsDisplay()

        }
    }
}

// MARK: - Lifecycle
public extension CompassControl {
    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = UIColor.clearColor()

        isAccessibilityElement = true

        setNeedsDisplay()
    }
    
    override func drawRect(rect: CGRect) {
        
        NSAssetKit.drawTextBlock(frame: rect, arrowTintColor: self.color, sgvText: self.sgvText, bg_delta: self.delta, textSizeForSgv: 39, textSizeForDelta: 12)
        
        if self.isUncomputable {
            NSAssetKit.drawUncomputedCircle(rect, arrowTintColor:self.color, isUncomputable: self.isUncomputable, computeAnimation: self.animationValue)
        } else {
            NSAssetKit.drawWatchFaceOnly(rect, arrowTintColor: self.color, angle: self.angle, isArrowVisible: self.isArrowVisible, doubleUp: self.isDoubleUp)
        }
        
        accessibilityHint = "Glucose Value of \(sgvText) with a delta of \(delta), with the following direction \(direction)"
    }

}

// MARK: - Methods
public extension CompassControl {
    public func configireDrawRect( isDoubleUp:Bool = false, isArrowVisible:Bool = true, isUncomputable:Bool = false, angle:CGFloat?=0, sgvText:String?=nil ){
        self.isDoubleUp = isDoubleUp
        self.isArrowVisible = isArrowVisible
        self.isUncomputable = isUncomputable
        
        self.angle = angle!
        if (sgvText != nil) {
            self.sgvText = sgvText!
        }
        
    }
    
    func takeSnapshot() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, UIScreen.mainScreen().scale)
        drawViewHierarchyInRect(self.bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
}

// MARK: - Delegate Methods
public extension CompassControl {
    
}

// MARK: - Actions
public extension CompassControl {
    
}
