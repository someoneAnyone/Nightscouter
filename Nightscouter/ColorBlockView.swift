//
//  colorBlockView.swift
//  Nightscouter
//
//  Created by Peter Ina on 7/23/15.
//  Copyright (c) 2015 Peter Ina. All rights reserved.
//

import UIKit
@IBDesignable

class ColorBlockView: UIView {

    
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
        if let color = self.backgroundColor {
            NSAssetKit.drawColorBlockBackgroundView(arrowTintColor: color, backgroundFrame: rect)
        }
    }


}
