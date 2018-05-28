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
            setNeedsUpdateConstraints()
        }
    }
    
    
    lazy var tintLine: UIView = {
        let newl = UIView()
        newl.backgroundColor = self.tintColor
        newl.translatesAutoresizingMaskIntoConstraints = false
        
        return newl
    }()
    
    lazy var blurredEffectView: UIVisualEffectView = {
        
        let blurEffect = UIBlurEffect(style: .dark)
        let blurredEffectView = UIVisualEffectView(effect: blurEffect)
        blurredEffectView.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(blurredEffectView)
        
        let bottomConstraint = NSLayoutConstraint(item: blurredEffectView, attribute: .bottom, relatedBy: .equal, toItem: blurredEffectView.superview, attribute: .bottom, multiplier: 1, constant: 0)
        let topConstraint = NSLayoutConstraint(item: blurredEffectView, attribute: .top , relatedBy: .equal, toItem: blurredEffectView.superview, attribute: .top ,  multiplier: 1, constant: 0)
        let widthConstraint = NSLayoutConstraint(item: blurredEffectView, attribute: .width , relatedBy: .equal, toItem: blurredEffectView.superview, attribute: .width ,  multiplier: 1, constant: 0)
        let horizontalConstraint = NSLayoutConstraint(item: blurredEffectView, attribute: .centerX, relatedBy: .equal, toItem: blurredEffectView.superview, attribute: .centerX, multiplier: 1, constant: 0)
        
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
        label.textAlignment = .left
        label.tintColor = self.tintColor
        label.shadowColor = UIColor.black.withAlphaComponent(0.5)
        label.shadowOffset = CGSize(width: 0, height: -1)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        return label
    }()
    
    var mainStack:UIStackView = UIStackView()
    
    func configureView() {
        self.backgroundColor = UIColor.clear
        
        let label = self.messageLabel
        let line = self.tintLine
        let blurredEffectView = self.blurredEffectView
        
        mainStack = UIStackView(arrangedSubviews:[label, line])
        mainStack.sendSubview(toBack: blurredEffectView)
        mainStack.axis = .vertical
        mainStack.spacing = 2
        
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(mainStack)
        
        // Define constraints for tintLine.
        let tintLineHeightConstraint = NSLayoutConstraint(item: line, attribute: .height , relatedBy: .equal, toItem: nil, attribute: .height ,  multiplier: 1, constant: 2)
        
        
         // Define constraints for UILabel.
         //let labelHorizontalConstraint = NSLayoutConstraint(item: labelButtonStack, attribute: .CenterY, relatedBy: .Equal, toItem: nil, attribute: .CenterY, multiplier: 1, constant: 0)
         //let labelLeftConstraint = NSLayoutConstraint(item: label, attribute: .Leading, relatedBy: .Equal, toItem: mainStack, attribute: .LeadingMargin, multiplier: 1, constant: 8)
         //let labelRightConstraint = NSLayoutConstraint(item: label, attribute: .Trailing, relatedBy: .Equal, toItem: mainStack, attribute: .TrailingMargin, multiplier: 1, constant: 8)
 
        
        // Define constratints for StackView
        let stackBottomConstraint = NSLayoutConstraint(item: mainStack, attribute: .bottom, relatedBy: .equal, toItem: mainStack.superview, attribute: .bottom, multiplier: 1, constant: 0)
        stackBottomConstraint.priority = UILayoutPriority(rawValue: 999)
        
        let stackTopConstraint = NSLayoutConstraint(item: mainStack, attribute: .top , relatedBy: .equal, toItem: mainStack.superview, attribute: .top ,  multiplier: 1, constant: 0)
        //let stackWidthConstraint = NSLayoutConstraint(item: mainStack, attribute: .Width , relatedBy: .Equal, toItem: mainStack.superview, attribute: .Width ,  multiplier: 1, constant: 0)
        
        let stackLeftConstraint = NSLayoutConstraint(item: mainStack, attribute: .leading, relatedBy: .equal, toItem: mainStack.superview, attribute: .leadingMargin, multiplier: 1, constant: 0)
        
        let stackRightConstraint = NSLayoutConstraint(item: mainStack, attribute: .trailing, relatedBy: .equal, toItem: mainStack.superview, attribute: .trailingMargin, multiplier: 1, constant: 0)
        
        //let stackHorizontalConstraint = NSLayoutConstraint(item: mainStack, attribute: .CenterX, relatedBy: .Equal, toItem: mainStack.superview, attribute: .CenterX, multiplier: 1, constant: 0)
        
        let stackHeightConstraint = NSLayoutConstraint(item: mainStack, attribute: .height , relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .height ,  multiplier: 1, constant: 50)
        
        stackHeightConstraint.priority = UILayoutPriority(rawValue: 999)
        stackHeightConstraint.isActive = !isHidden
        
        
        self.addConstraints([stackTopConstraint, stackBottomConstraint, stackHeightConstraint, tintLineHeightConstraint, stackLeftConstraint, stackRightConstraint])
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
