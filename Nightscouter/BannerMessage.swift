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
        tintLine.backgroundColor = tintColor
        messageLabel.textColor = tintColor
    }
    
    @IBInspectable
    var message: String = "" {
        didSet{
            messageLabel.text = message
            setNeedsDisplay()
        }
    }
    
    
    lazy var tintLine: UIView = {
        let newl = UIView()
        newl.backgroundColor = self.tintColor
        newl.translatesAutoresizingMaskIntoConstraints = false
        
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
    
    /*
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
     */
    
    lazy var messageLabel: UILabel = {
        let label = UILabel()
        
        label.numberOfLines = 0
        label.textAlignment = .Left
        label.tintColor = self.tintColor
        label.shadowColor = UIColor.blackColor().colorWithAlphaComponent(0.5)
        label.shadowOffset = CGSize(width: 0, height: -1)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        return label
    }()
    
    var labelButtonStack: UIStackView!
    var mainStack: UIStackView!
    
    func configureView() {
        self.backgroundColor = UIColor.clearColor()
        
        let label = self.messageLabel
        let line = self.tintLine
        let blurredEffectView = self.blurredEffectView
    
        mainStack = UIStackView(arrangedSubviews:[label,line])
        
        mainStack.sendSubviewToBack(blurredEffectView)
        mainStack.axis = .Vertical
        mainStack.spacing = 2
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        self.addSubview(mainStack)
        
        // Define constraints for tintLine.
        let tintLineHeightConstraint = NSLayoutConstraint(item: line, attribute: .Height , relatedBy: .Equal, toItem: nil, attribute: .Height ,  multiplier: 1, constant: 2)
        
        /*
        // Define constraints for UILabel.
        let labelHorizontalConstraint = NSLayoutConstraint(item: labelButtonStack, attribute: .CenterY, relatedBy: .Equal, toItem: labelButtonStack.superview, attribute: .CenterY, multiplier: 1, constant: 0)
        let labelLeftConstraint = NSLayoutConstraint(item: labelButtonStack, attribute: .Left, relatedBy: .Equal, toItem: labelButtonStack.superview, attribute: .LeftMargin, multiplier: 1, constant: 8)
        let labelRightConstraint = NSLayoutConstraint(item: labelButtonStack, attribute: .Right, relatedBy: .Equal, toItem: labelButtonStack.superview, attribute: .RightMargin, multiplier: 1, constant: 8)
        */
        
        // Define constratints for StackView
        let stackBottomConstraint = NSLayoutConstraint(item: mainStack, attribute: .Bottom, relatedBy: .Equal, toItem: mainStack.superview, attribute: .Bottom, multiplier: 1, constant: 0)
        let stackTopConstraint = NSLayoutConstraint(item: mainStack, attribute: .Top , relatedBy: .Equal, toItem: mainStack.superview, attribute: .Top ,  multiplier: 1, constant: 0)
        let stackWidthConstraint = NSLayoutConstraint(item: mainStack, attribute: .Width , relatedBy: .Equal, toItem: mainStack.superview, attribute: .Width ,  multiplier: 1, constant: 0)
        let stackHorizontalConstraint = NSLayoutConstraint(item: mainStack, attribute: .CenterX, relatedBy: .Equal, toItem: mainStack.superview, attribute: .CenterX, multiplier: 1, constant: 0)

        let stackHeightConstraint = NSLayoutConstraint(item: mainStack, attribute: .Height , relatedBy: .GreaterThanOrEqual, toItem: nil, attribute: .Height ,  multiplier: 1, constant: 50)
        
        
        self.addConstraints([stackTopConstraint,stackWidthConstraint, stackBottomConstraint, stackHeightConstraint, stackHorizontalConstraint, stackWidthConstraint, tintLineHeightConstraint])//, labelHorizontalConstraint, labelLeftConstraint, labelRightConstraint])

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
