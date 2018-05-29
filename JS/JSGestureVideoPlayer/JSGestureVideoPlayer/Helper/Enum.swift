//
//  Enum.swift
//  JSGestureVideoPlayer
//
//  Created by Alpaca on 2018. 5. 17..
//  Copyright © 2018년 Alpaca. All rights reserved.
//

import UIKit

public enum SeekToDirection {
    case backward
    case forward
}

public enum PanGestureDirection {
    case horizontal
    case vertical
}

public enum PlayState {
    case play
    case pause
    case replay
    
    func getImage() -> UIImage {
        switch self {
        case .play:
            return #imageLiteral(resourceName: "playerPauseDefault")
        case .pause:
            return #imageLiteral(resourceName: "playerPlayDefault")
        case .replay:
            return #imageLiteral(resourceName: "ic_replay_white_48pt")
        }
    }
}

public enum SystemControl {
    case brightness
    case volume
    
    func getImage() -> UIImage {
        switch self {
        case .brightness:
            return #imageLiteral(resourceName: "baseline_wb_sunny_white_48pt")
        case .volume:
            return #imageLiteral(resourceName: "baseline_volume_up_white_48pt")
        }
    }
}
