//
//  BannerMessage.swift
//  Nightscouter
//
//  Created by Peter Ina on 8/23/16.
//  Copyright © 2016 Peter Ina. All rights reserved.
//

import UIKit

@IBDesignable
class BannerMessage: UIView {
    
    override func tintColorDidChange() {
        super.tintColorDidChange()
        line.backgroundColor = tintColor.CGColor
        messageLabel.textColor = tintColor
    }
    
    @IBInspectable
    var message: String = "" {
        didSet{
            messageLabel.text = message
            line.backgroundColor = tintColor.CGColor
            layer.addSublayer(line)
            setNeedsDisplay()
        }
    }
    
    lazy var line: CALayer = {
        let newl = CALayer()
        newl.frame = CGRect(x: self.bounds.minX, y: self.bounds.maxY-2, width: self.bounds.width, height: 2)
        newl.backgroundColor = self.tintColor.CGColor
        
        return newl
    }()
    
    lazy var blurredEffectView: UIVisualEffectView = {
        
        let blurEffect = UIBlurEffect(style: .Dark)
        let blurredEffectView = UIVisualEffectView(effect: blurEffect)
        blurredEffectView.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(blurredEffectView)
        
        let bottomConstraint = NSLayoutConstraint(item: blurredEffectView, attribute: .Bottom, relatedBy: .Equal, toItem: blurredEffectView.superview, attribute: .Bottom, multiplier: 1, constant: 0)
        let topConstraint = NSLayoutConstraint(item: blurredEffectView, attribute: .Top , relatedBy: .Equal, toItem: blurredEffectView.superview, attribute: .Top ,  multiplier: 1, constant: 0)
        let widthConstraint = NSLayoutConstraint(item: blurredEffectView, attribute: .Width , relatedBy: .Equal, toItem: blurredEffectView.superview, attribute: .Width ,  multiplier: 1, constant: 0)
        let horizontalConstraint = NSLayoutConstraint(item: blurredEffectView, attribute: .CenterX, relatedBy: .Equal, toItem: blurredEffectView.superview, attribute: .CenterX, multiplier: 1, constant: 0)
        
        
        self.addConstraints([bottomConstraint, topConstraint, widthConstraint, horizontalConstraint])
        
        return blurredEffectView
    }()
    
    
    lazy var vibrancyEffectView: UIVisualEffectView = {
        
        let vibrancyEffect = UIVibrancyEffect(forBlurEffect: self.blurredEffectView.effect as! UIBlurEffect)
        
        let vibrancyEffectView = UIVisualEffectView(effect: vibrancyEffect)
        vibrancyEffectView.translatesAutoresizingMaskIntoConstraints = false
        self.blurredEffectView.contentView.addSubview(vibrancyEffectView)
        
        let bottomConstraint = NSLayoutConstraint(item: vibrancyEffectView, attribute: .Bottom, relatedBy: .Equal, toItem: vibrancyEffectView.superview, attribute: .Bottom, multiplier: 1, constant: 0)
        let topConstraint = NSLayoutConstraint(item: vibrancyEffectView, attribute: .Top , relatedBy: .Equal, toItem: vibrancyEffectView.superview, attribute: .Top ,  multiplier: 1, constant: 0)
        
        let widthConstraint = NSLayoutConstraint(item: vibrancyEffectView, attribute: .Width , relatedBy: .Equal, toItem: vibrancyEffectView.superview, attribute: .Width ,  multiplier: 1, constant: 0)
        let horizontalConstraint = NSLayoutConstraint(item: vibrancyEffectView, attribute: .CenterX, relatedBy: .Equal, toItem: vibrancyEffectView.superview, attribute: .CenterX, multiplier: 1, constant: 0)
        
        self.blurredEffectView.addConstraints([bottomConstraint, topConstraint, widthConstraint, horizontalConstraint])
        
        return vibrancyEffectView
    }()
    
    lazy var messageLabel: UILabel = {
        let label = UILabel()
        
        label.numberOfLines = 0
        label.textAlignment = .Left
        label.tintColor = self.tintColor
        label.shadowColor = UIColor.blackColor().colorWithAlphaComponent(0.5)
        label.shadowOffset = CGSize(width: 0, height: -1)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        // self.vibrancyEffectView.contentView.addSubview(label)
        self.blurredEffectView.contentView.addSubview(label)
        
        let hConst = NSLayoutConstraint(item: label, attribute: .CenterY, relatedBy: .Equal, toItem: label.superview, attribute: .CenterY, multiplier: 1, constant: 0)
        
        let lConst = NSLayoutConstraint(item: label, attribute: .Left, relatedBy: .Equal, toItem: label.superview, attribute: .LeftMargin, multiplier: 1, constant: 0)
        
        let rConst = NSLayoutConstraint(item: label, attribute: .Right, relatedBy: .Equal, toItem: label.superview, attribute: .RightMargin, multiplier: 1, constant: 0)
        
        let tConst = NSLayoutConstraint(item: label, attribute: .Top, relatedBy: .Equal, toItem: label.superview, attribute: .Top, multiplier: 1, constant: 0)
        tConst.priority = 240
        let bConst = NSLayoutConstraint(item: label, attribute: .Bottom, relatedBy: .Equal, toItem: label.superview, attribute: .Bottom, multiplier: 1, constant: 0)
        tConst.priority = 240
        
        // self.vibrancyEffectView.addConstraints([hConst, rConst, lConst, tConst, bConst])
        self.blurredEffectView.addConstraints([hConst, rConst, lConst, tConst, bConst])
        
        return label
    }()
    
    func configureView() {
        self.backgroundColor = UIColor.clearColor()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureView()
    }
    
}
