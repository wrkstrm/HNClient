//
//  DynamicLogo.swift
//  HackerNews
//
//  Created by Cristian Monterroza on 11/9/14.
//  Copyright (c) 2014 wrkstrm. All rights reserved.
//

import Foundation

class DynamicLogo: UILabel {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    func commonInit() {
        backgroundColor = UIColor.clearColor()
        createShadowEffect()
    }
    
    func createShadowEffect() {
        layer.shadowColor = SKColor.blackColor().CGColor
        layer.shadowOffset = CGSizeMake(0.0, 0.0)
        layer.shadowOpacity = 1.0
        layer.shadowRadius = 0.0
        let horizontal = UIInterpolatingMotionEffect(keyPath: "layer.shadowOffset.width",
            type: UIInterpolatingMotionEffectType.TiltAlongHorizontalAxis)
        horizontal.minimumRelativeValue = -12
        horizontal.maximumRelativeValue = 12
        
        let vertical = UIInterpolatingMotionEffect(keyPath: "layer.shadowOffset.height",
            type: UIInterpolatingMotionEffectType.TiltAlongVerticalAxis)
        vertical.minimumRelativeValue = -12
        vertical.maximumRelativeValue = 14
        
        addMotionEffect(horizontal)
        addMotionEffect(vertical)
    }
    
    func hackerOrange() -> UIColor {
        return SKColorMakeRGB(255.0, 102.0, 0.0)
    }
}