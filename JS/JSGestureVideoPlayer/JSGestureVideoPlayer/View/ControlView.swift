//
//  ControlView.swift
//  JSGestureVideoPlayer
//
//  Created by Alpaca on 2018. 5. 17..
//  Copyright © 2018년 Alpaca. All rights reserved.
//

import UIKit
import CoreMedia
import MediaPlayer

class ControlView: UIView {
    
    @IBOutlet var outletCollection: [UIView]!
    @IBOutlet weak var playButton: PlayButton!
    @IBOutlet weak var timeSlider: UISlider!
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var totalTimeLabel: UILabel!
    @IBOutlet weak var centerTimeLabel: UILabel!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var systemControlImageView: SystemControlImageView!
        
    // MARK: Public Properties
    public lazy var isVisible: Bool = true
    
    public lazy var expandingView: UIView = {
        let expandingView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: self.frame.width / 2, height: self.frame.height)))
        expandingView.backgroundColor = currentTimeLabel.textColor
        expandingView.alpha = 0.5
        
        return expandingView
    }()
    
    public var volumeView: MPVolumeView = MPVolumeView(frame: .zero)
    
    public func setVolumeView() {
        volumeView.clipsToBounds = true
        volumeView.isUserInteractionEnabled = false
        
        addSubview(volumeView)
    }
    
    // MARK: Frame Properties
    public var frameHeight: CGFloat {
        return frame.height
    }
    
    public var frameWidth: CGFloat {
        return frame.width
    }
    
    // MARK: Reusing Methods
    public func setEmptyCenterTimeLabel() {
        centerTimeLabel.text = nil
        centerTimeLabel.isHidden = true
    }
}
