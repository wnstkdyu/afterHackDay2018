//
//  ControlManager.swift
//  JSGestureVideoPlayer
//
//  Created by Alpaca on 2018. 5. 18..
//  Copyright © 2018년 Alpaca. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

protocol ControlManagerDelegate: class {
    func updateNewCMTime(using ratio: Double)
    func seekToTimeIfNeeded()
}

class ControlManager {
    
    // MARK: Public Properties
    public weak var delegate: ControlManagerDelegate?
    
    // MARK: Private Properties
    private let controlView: ControlView
    
    private var panGestureDirection: PanGestureDirection?
    private var firstBrightness: CGFloat?
    private var firstVolume: Float?
    
    private var fadeInAnimator: UIViewPropertyAnimator?
    private var fadeOutAnimator: UIViewPropertyAnimator?
    
    init(controlView: ControlView) {
        self.controlView = controlView
        self.controlView.setVolumeView()
    }
    
    // MARK: Update ControlView UI
    public func setPlayButtonUI(playState: PlayState) {
        controlView.playButton.setState(playState: playState)
    }
    
    public func setCurrentTimeLabel(currentTimeText: String) {
        controlView.currentTimeLabel.text = currentTimeText
    }
    
    public func setTotalTimeLabel(totalTimeText: String) {
        controlView.totalTimeLabel.text = totalTimeText
    }
    
    public func setTimeSliderUI(value: Float) {
        controlView.timeSlider.setValue(value, animated: true)
    }
    
    public func setCenterTimeLabelUI(timeText: String) {
        controlView.centerTimeLabel.isHidden = false
        controlView.centerTimeLabel.text = timeText
    }
    
    public func startActivityIndicator() {
        controlView.activityIndicatorView.startAnimating()
    }
    
    public func stopActivtiyIndicator() {
        controlView.activityIndicatorView.stopAnimating()
    }
    
    // MARK: UITapGesture Logic
    public func fadeInControlView(addedAnimation: (() -> ())? = nil) {
        removeAndInitializeAnimations()
        
        if let addedAnimation = addedAnimation {
            fadeInAnimator?.addAnimations {
                addedAnimation()
            }
        }
        fadeInAnimator?.startAnimation()
    }
    
    public func fadeOutControlView(completionHandler: (() -> ())? = nil) {
        removeAndInitializeAnimations()
        
        if let completionHandler = completionHandler {
            fadeOutAnimator?.addCompletion{ _ in
                completionHandler()
            }
        }
        fadeOutAnimator?.startAnimation()
    }
    
    public func removeAndInitializeAnimations() {
        fadeInAnimator?.stopAnimation(true)
        fadeOutAnimator?.stopAnimation(true)
        
        fadeInAnimator
            = UIViewPropertyAnimator(duration: Constants.animationDuration, curve: .easeInOut) { [weak self] in
                self?.controlView.outletCollection.forEach { $0.alpha = 1 }
        }
        fadeInAnimator?.addCompletion { [weak self] _ in
            guard let strongSelf = self else { return }

            strongSelf.fadeOutAnimator?.startAnimation(afterDelay: Constants.animationDelay)
            strongSelf.controlView.isVisible = true
        }
        
        fadeOutAnimator
            = UIViewPropertyAnimator(duration: Constants.animationDuration, curve: .easeInOut) {
                self.controlView.outletCollection.forEach { $0.alpha = 0.05 }
        }
        fadeOutAnimator?.addCompletion({ [weak self] _ in
            guard let strongSelf = self else { return }
            
            strongSelf.controlView.outletCollection.forEach { $0.alpha = 0.0 }
            strongSelf.controlView.isVisible = false
        })
    }
    
    // MARK: UIPanGesture Logic
    public func panGestureBegan() {
        if !controlView.expandingView.isDescendant(of: controlView) {
            controlView.addSubview(controlView.expandingView)
        }
        controlView.expandingView.isHidden = true
        
        firstBrightness = UIScreen.main.brightness
        firstVolume = AVAudioSession.sharedInstance().outputVolume
    }
    
    public func panGestureChanged(translation: CGPoint, touchLocation: CGPoint) {
        let xRatio = translation.x / controlView.frameWidth
        let yRatio = translation.y / controlView.frameHeight
        
        let isHorizontal: Bool = abs(xRatio) > abs(yRatio)
        if isHorizontal {
            if let panGestureDirection = panGestureDirection {
                guard panGestureDirection == .horizontal else { return }
            } else {
                panGestureDirection = .horizontal
            }
            
            horizontallyMoved(xRatio: xRatio)
        } else {
            if let panGestureDirection = panGestureDirection {
                guard panGestureDirection == .vertical else { return }
            } else {
                panGestureDirection = .vertical
            }
            
            verticallyMoved(yRatio: yRatio, touchLocation: touchLocation)
        }
    }
    
    private func horizontallyMoved(xRatio: CGFloat) {
        let ratio = Double(xRatio)
        
        delegate?.updateNewCMTime(using: ratio)
    }
    
    private func verticallyMoved(yRatio: CGFloat, touchLocation: CGPoint) {
        controlView.expandingView.isHidden = false
        controlView.systemControlImageView.isHidden = false
        
        let isLeft = touchLocation.x <= controlView.frameWidth / 2
        if isLeft {
            setBrightness(yRatio: yRatio)
        } else {
            setVolume(yRatio: yRatio)
        }
        
        guard controlView.expandingView.frame.origin.y >= 0 else {
            controlView.expandingView.frame.origin.y = 0
            
            return
        }
    }
    
    private func setBrightness(yRatio: CGFloat) {
        guard let firstBrightness = firstBrightness else { return }
        UIScreen.main.brightness = CGFloat(firstBrightness) - yRatio
        
        controlView.systemControlImageView.setSystemControlImage(systemControl: .brightness)
        
        let expadingViewOriginY: CGFloat = controlView.frameHeight * (1 - UIScreen.main.brightness)
        setExpandingViewOrigin(origin: CGPoint(x: 0, y: expadingViewOriginY))
        
        let maskViewOriginY: CGFloat
            = controlView.systemControlImageView.frame.height * (1 - UIScreen.main.brightness)
        setMaskViewOriginY(originY: maskViewOriginY)
    }
    
    private func setVolume(yRatio: CGFloat) {
        guard let firstVolume = firstVolume,
            let volumeSlider = controlView.volumeView.subviews.first as? UISlider else { return }
        volumeSlider.setValue(firstVolume - Float(yRatio), animated: false)
        
        controlView.systemControlImageView.setSystemControlImage(systemControl: .volume)
        
        let expandingViewOriginY: CGFloat = controlView.frameHeight * CGFloat(1 - (firstVolume - Float(yRatio)))
        setExpandingViewOrigin(origin: CGPoint(x: controlView.frameWidth / 2, y: expandingViewOriginY))
        
        let maskViewOriginY: CGFloat
            = controlView.systemControlImageView.frame.height * CGFloat(1 - (firstVolume - Float(yRatio)))
        setMaskViewOriginY(originY: maskViewOriginY)
    }
    
    private func setExpandingViewOrigin(origin: CGPoint) {
        controlView.expandingView.frame.origin = origin
    }
    
    private func setMaskViewOriginY(originY: CGFloat) {
        print(controlView.systemControlImageView.colorView.frame)
        controlView.systemControlImageView.setMaskViewOriginY(originY: originY)
    }
    
    public func panGestureEnded() {
        if let panGestureDirection = panGestureDirection,
            panGestureDirection == .horizontal {
            delegate?.seekToTimeIfNeeded()
        }
        
        // 초기화
        initalizeStateProperties()
        controlView.setEmptyCenterTimeLabel()
        controlView.systemControlImageView.setEmptyForReuse()
        setExpandingViewOrigin(origin: CGPoint(x: 0, y: controlView.frame.maxY))
    }
    
    private func initalizeStateProperties() {
        panGestureDirection = nil
        firstBrightness = nil
        firstVolume = nil
    }
}
