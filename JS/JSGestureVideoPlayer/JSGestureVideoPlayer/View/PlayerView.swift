//
//  PlayerView.swift
//  JSGestureVideoPlayer
//
//  Created by Alpaca on 2018. 5. 17..
//  Copyright © 2018년 Alpaca. All rights reserved.
//

import UIKit
import AVFoundation

class PlayerView: UIView {
    
    public var player: AVPlayer? {
        get {
            return playerLayer.player
        }
        set {
            playerLayer.player = newValue
        }
    }
    
    public var playerLayer: AVPlayerLayer {
        get {
            return layer as! AVPlayerLayer
        }
    }
    
    // Override UIView property
    override static var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
}
