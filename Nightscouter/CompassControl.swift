//
//  CompassView.swift
//  Nightscout Watch Face
//
//  Created by Peter Ina on 4/30/15.
//  Copyright (c) 2015 Peter Ina. All rights reserved.
//

import UIKit

//@IBDesignable

public class CompassControl: UIView {
    
     var alertColor: UIColor = NSAssetKit.predefinedAlertColor
     var postiveColor: UIColor = NSAssetKit.predefinedPostiveColor
     var startingColor: UIColor = NSAssetKit.predefinedNeutralColor {
        didSet{
            color = startingColor
        }
    }
//    @IBInspectable
     var warningColor: UIColor = NSAssetKit.predefinedWarningColor
    
     var units: String?
     var lowString: String = "Low"
     var highString: String = "High"
    
     var bg_high: CGFloat = 300
     var bg_target_top: CGFloat = 250
     var bg_target_bottom: CGFloat = 70
     var bg_low: CGFloat = 60
    
    let minValue: CGFloat = 39
    let maxValue: CGFloat = 400
    
    var sgvText:String = "N/A"
    
//    let bgUnits: String = "mg/dl"
//    var oldSgvValue: Int = 0
//    var newSgvValue: Int = 0
    
    var angle: CGFloat = 0
    var isUncomputable = false
    var isDoubleUp = false
    var isArrowVisible = false
    
    public var color: UIColor? {
        didSet {
            setNeedsDisplay()
        }}
//    }= NSAssetKit.predefinedSimpleColor
    
    var animationValue: CGFloat = 0
    
     public var sgv: CGFloat = 100 {
        willSet {
//            oldSgvValue = Int(sgv)
//            updateDelta()

        }
        didSet {
//            println("Changing sgv to: \(sgv)")
            if sgv < minValue {
                sgvText = lowString
                sgv = minValue
            }
            
            if sgv > maxValue {
                sgvText = highString
                sgv = maxValue
            }
            
            if (sgv < maxValue && sgv > minValue) {
                sgvText = NSNumberFormatter.localizedStringFromNumber(sgv, numberStyle: .NoStyle)
            }
//            newSgvValue = Int(sgv)
            createSubviews()
//            updateDelta()
        }
    }
    
    var delta: String = ""
  
    @IBInspectable public var direction: Direction = .None {
        didSet {
//            println("Changing Mode to: \(direction.description)")
            switch direction {
            case .None:
                configireDrawRect(isArrowVisible: false)
            case .DoubleUp:
                configireDrawRect(isDoubleUp: true)
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
                configireDrawRect(isDoubleUp: true, angle: -180)
            case .NotComputable:
                configireDrawRect(isArrowVisible: false, isUncomputable: true)
            case .RateOutOfRange:
                configireDrawRect(isArrowVisible: false, isUncomputable: true, sgvText: direction.description)
            }
            
            createSubviews()
        }
    }
}

// MARK: - Lifecycle
public extension CompassControl {
    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = UIColor.clearColor()

        createSubviews()
    }
    
    override func drawRect(rect: CGRect) {
        
        NSAssetKit.drawTextBlock(frame: rect, arrowTintColor: self.color!, sgvText: self.sgvText, bg_delta: self.delta, textSizeForSgv: 39, textSizeForDelta: 12)
        
        if self.isUncomputable {
            NSAssetKit.drawUncomputedCircle(frame: rect, arrowTintColor:self.color!, isUncomputable: self.isUncomputable, computeAnimation: self.animationValue)
        } else {
            NSAssetKit.drawWatchFaceOnly(frame: rect, arrowTintColor: self.color!, angle: self.angle, isArrowVisible: self.isArrowVisible, doubleUp: self.isDoubleUp)
        }
    }

}

// MARK: - Methods
public extension CompassControl {
    
    func createSubviews(){
        // Create objects
        determineColor()
        // Deal with Auto Layout
        setNeedsDisplay()
    }
    
    func determineColor() {
//        println("Changing Color to: \(color)")
        color = NSAssetKit.predefinedNeutralColor
        if (sgv > bg_high) {
            color = NSAssetKit.predefinedAlertColor
        } else if (sgv > bg_target_top) {
            color = NSAssetKit.predefinedWarningColor
        } else if (sgv >= bg_target_bottom && sgv <= bg_target_top) {
            color = NSAssetKit.predefinedPostiveColor
        } else if (sgv < bg_low) {
            color = NSAssetKit.predefinedAlertColor
        } else if (sgv < bg_target_bottom) {
            color = NSAssetKit.predefinedWarningColor
        }
    }
    
    func configireDrawRect( isDoubleUp:Bool = false, isArrowVisible:Bool = true, isUncomputable:Bool = false, angle:CGFloat?=0, sgvText:String?=nil ){
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
        let image = UIGraphicsGetImageFromCurrentImageContext()
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