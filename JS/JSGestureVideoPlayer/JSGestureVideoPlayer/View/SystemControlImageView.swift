//
//  SystemControlView.swift
//  JSGestureVideoPlayer
//
//  Created by Alpaca on 2018. 5. 19..
//  Copyright © 2018년 Alpaca. All rights reserved.
//

import UIKit

class SystemControlImageView: UIImageView {
    
    public lazy var colorView: UIView = {
        let colorView: UIView = UIView(frame: bounds)
        colorView.backgroundColor = .white
        
        return colorView
    }()
        
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        mask = colorView
    }
    
    public func setSystemControlImage(systemControl: SystemControl) {
        image = systemControl.getImage()
    }
    
    public func setEmptyForReuse() {
        image = nil
        isHidden = true
    }
    
    // MARK: Setting MaskView
    public func setMaskViewOriginY(originY: CGFloat) {
        print(colorView.frame)
        colorView.frame.origin.y = originY
    }
}
