//
//  PlayerNavigationController.swift
//  JSGestureVideoPlayer
//
//  Created by Alpaca on 2018. 5. 18..
//  Copyright © 2018년 Alpaca. All rights reserved.
//

import UIKit

class PlayerNavigationController: UINavigationController {
    
    override var shouldAutorotate: Bool {
        guard let topViewController = topViewController else { return false }
        
        return topViewController.shouldAutorotate
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        guard let topViewController = topViewController else { return [.portrait] }
        
        return topViewController.supportedInterfaceOrientations
    }
}
