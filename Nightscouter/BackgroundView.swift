//
//  TableViewBackgroundView.swift
//  Nightscouter
//
//  Created by Peter Ina on 7/17/15.
//  Copyright (c) 2015 Peter Ina. All rights reserved.
//

import UIKit
import NightscouterKit

@IBDesignable
class BackgroundView: UIView {
    
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        NSAssetKit.drawTableViewBackgroundView(backgroundFrame: rect)
    }
}
