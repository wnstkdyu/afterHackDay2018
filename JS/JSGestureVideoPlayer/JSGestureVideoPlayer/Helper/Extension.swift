//
//  Extension.swift
//  JSGestureVideoPlayer
//
//  Created by Alpaca on 2018. 5. 17..
//  Copyright © 2018년 Alpaca. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

extension AVPlayer {
    var isPlaying: Bool {
        return rate > 0.0
    }
}

extension CMTime {
    var toTimeString: String {
        let hours: Int = Int(self.seconds / 3600)
        let minutes: Int = Int(self.seconds.truncatingRemainder(dividingBy: 3600) / 60)
        let seconds: Int = Int(self.seconds.truncatingRemainder(dividingBy: 60))
        
        if hours > 0 {
            return String(format: "%i:%02i:%02i", hours, minutes, seconds)
        } else {
            return String(format: "%02i:%02i", minutes, seconds)
        }
    }
}

extension Double {
    var toTimeString: String {
        let hours: Int = Int(self / 3600)
        let minutes: Int = Int(self.truncatingRemainder(dividingBy: 3600) / 60)
        let seconds: Int = Int(self.truncatingRemainder(dividingBy: 60))
        
        if hours > 0 {
            return String(format: "%i:%02i:%02i", hours, minutes, seconds)
        } else {
            return String(format: "%02i:%02i", minutes, seconds)
        }
    }
}
