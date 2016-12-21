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
    
    @IBInspectable open var sgvText:String = "---" {
        didSet{
            setNeedsDisplay()
        }
    }
    var angle: CGFloat = 0
    var isUncomputable = false
    var isDoubleUp = false
    var isArrowVisible = false
    
    @IBInspectable open var color: UIColor = NSAssetKit.predefinedNeutralColor {
        didSet {
            setNeedsDisplay()
        }
    }
    
    open override var intrinsicContentSize : CGSize {
        super.invalidateIntrinsicContentSize()
        
        let compactSize = CGSize(width: 156, height: 120)
        let midSize = CGSize(width: 156, height: 140)
        let fullSize = CGSize(width: 156, height: 200)
        
        switch direction {
        case .none, .NotComputable, .Not_Computable:
            return compactSize
        case .FortyFiveUp, .FortyFiveDown, .Flat:
            return compactSize
        case .SingleUp, .SingleDown:
            return midSize
        default:
            return fullSize
        }
    }
    
    var animationValue: CGFloat = 0
    @IBInspectable open var delta: String = "- --/--" {
        didSet{
            setNeedsDisplay()
        }
    }
    
    open var direction: Direction = .none {
        didSet {
            switch direction {
            case .none:
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
            
            invalidateIntrinsicContentSize()
            setNeedsDisplay()
            
        }
    }
}

// MARK: - Lifecycle
public extension CompassControl {
    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = UIColor.clear
        
        isAccessibilityElement = true
        
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        
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
    public func configireDrawRect( _ isDoubleUp:Bool = false, isArrowVisible:Bool = true, isUncomputable:Bool = false, angle:CGFloat?=0, sgvText:String?=nil ){
        self.isDoubleUp = isDoubleUp
        self.isArrowVisible = isArrowVisible
        self.isUncomputable = isUncomputable
        
        self.angle = angle!
        if (sgvText != nil) {
            self.sgvText = sgvText!
        }
        
    }
    
    func takeSnapshot() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, UIScreen.main.scale)
        drawHierarchy(in: self.bounds, afterScreenUpdates: true)
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
