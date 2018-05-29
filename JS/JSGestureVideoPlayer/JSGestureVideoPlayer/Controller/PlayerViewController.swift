//
//  PlayerViewController.swift
//  JSGestureVideoPlayer
//
//  Created by Alpaca on 2018. 5. 17..
//  Copyright © 2018년 Alpaca. All rights reserved.
//

import UIKit
import CoreMedia

class PlayerViewController: UIViewController {
    
    @IBOutlet weak var playerView: PlayerView!
    @IBOutlet weak var controlView: ControlView!
    @IBOutlet weak var lockButton: UIButton!
    
    @IBOutlet weak var doubleTapGestureRecognizer: UITapGestureRecognizer!
    @IBOutlet weak var tapGestureRecognizer: UITapGestureRecognizer!
    
    // MARK: Public Properties
    public var playerManager: PlayerManager?
    public var controlManager: ControlManager?
    
    // MARK: Private Properties
    private var newCMTime: CMTime?
    
    private var isSliderChanging: Bool = false
    
    private var isLocked: Bool = false
    private var lockButtonFadeInAnimator: UIViewPropertyAnimator?
    private var lockButtonFadeOutAnimator: UIViewPropertyAnimator?
    
    // MARK: StatusBar Hidden
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK: Rotation Properties
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return [.landscapeLeft]
    }
    
    // MARK: HomeIndicator Hidden
    override func prefersHomeIndicatorAutoHidden() -> Bool {
        return true
    }
    
    // MARK: LifeCycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUp()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        changeToPortrait()
    }
    
    // MARK: Setup Methods
    private func setUp() {
        changeToLandScape()
        setPlayer()
        setControlView()
        setDelegate()
        setGestureRecognizer()
        hideUI()
    }
    
    private func changeToLandScape() {
        let landscapeLeftOrientation = UIDeviceOrientation.landscapeLeft.rawValue
        UIDevice.current.setValue(landscapeLeftOrientation, forKey: "orientation")
    }
    
    private func setPlayer() {
        playerManager?.prepareToPlay()
        playerView.player = playerManager?.player
    }
    
    private func setControlView() {
        controlManager = ControlManager(controlView: controlView)
        controlManager?.startActivityIndicator()
        
        guard let totalTimeText = playerManager?.asset.duration.seconds.toTimeString else { return }
        controlManager?.setTotalTimeLabel(totalTimeText: totalTimeText)
    }
    
    private func setDelegate() {
        playerManager?.delegate = self
        controlManager?.delegate = self
    }
    
    private func setGestureRecognizer() {
        tapGestureRecognizer.require(toFail: doubleTapGestureRecognizer)
    }
    
    private func hideUI() {
        controlManager?.removeAndInitializeAnimations()
        controlManager?.fadeOutControlView()
        
        lockButton.isHidden = true
    }
    
    // MARK: UIButton Methods
    @IBAction func backButtonTapped(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func timeSliderValueChanged(_ sender: UISlider) {
        isSliderChanging = true
        
        let ratio = sender.value / sender.maximumValue
        
        guard let newCMTime = playerManager?.getCMTimeWithTimeSlider(with: Double(sender.value)) else { return }
        controlManager?.setCenterTimeLabelUI(timeText: newCMTime.toTimeString)
        
        guard !sender.isTracking else { return }
        isSliderChanging = false
        playerManager?.timeSliderValueChanged(ratio: ratio)
        controlView.setEmptyCenterTimeLabel()
    }
    
    @IBAction func playButtonTapped(_ sender: PlayButton) {
        let beforeState = sender.playState
        
        switch beforeState {
        case .play:
            playerManager?.pause()
        case .pause:
            playerManager?.play()
        case .replay:
            playerManager?.replay()
        }
    }
    
    @IBAction func backwardButtonTapped(_ sender: UIButton) {
        playerManager?.changeTenSeconds(to: .backward)
    }
    
    @IBAction func forwardButtonTapped(_ sender: UIButton) {
        playerManager?.changeTenSeconds(to: .forward)
    }
    
    @IBAction func lockButtonTapped(_ sender: UIButton) {
        removeAndInitailizeLockButtonAnimators()
        
        sender.isSelected = !sender.isSelected
        isLocked = sender.isSelected
        
        if sender.isSelected {
            controlManager?.fadeOutControlView(completionHandler: { [weak self] in
                guard let strongSelf = self else { return }
                
                strongSelf.lockButtonFadeOutAnimator?.startAnimation(afterDelay: Constants.animationDelay)
            })
        } else {
            controlManager?.fadeInControlView()
            lockButtonFadeInAnimator?.startAnimation()
        }
    }
    
    // MARK: UIGestureRecognizer Methods
    @IBAction func controlViewHandleTapGesture(_ sender: UITapGestureRecognizer) {
        removeAndInitailizeLockButtonAnimators()
        
        if !isLocked {
            if controlView.isVisible {
                lockButtonFadeOutAnimator?.startAnimation()
                controlManager?.fadeOutControlView()
            } else {
                controlManager?.fadeInControlView()
                lockButtonFadeInAnimator?.startAnimation()
            }
        } else {
            if lockButton.isHidden {
                lockButtonFadeInAnimator?.startAnimation()
            } else {
                lockButtonFadeOutAnimator?.startAnimation()
            }
        }
    }
    
    @IBAction func handleDoubleTapGesture(_ sender: UITapGestureRecognizer) {
        let currentVideoGravity = playerView.playerLayer.videoGravity
        if currentVideoGravity == .resizeAspect {
            playerView.playerLayer.videoGravity = .resizeAspectFill
        } else {
            playerView.playerLayer.videoGravity = .resizeAspect
        }
    }
    
    @IBAction func handlePanGesture(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began:
            controlManager?.panGestureBegan()
        case .changed:
            let translation: CGPoint = sender.translation(in: view)
            let touchLocation: CGPoint = sender.location(in: view)
            
            controlManager?.panGestureChanged(translation: translation, touchLocation: touchLocation)
        case .ended:
            controlManager?.panGestureEnded()
        default:
            break
        }
    }
    
    private func changeToPortrait() {
        let portaritOrientation = UIDeviceOrientation.portrait.rawValue
        UIDevice.current.setValue(portaritOrientation, forKey: "orientation")
    }
    
    private func removeAndInitailizeLockButtonAnimators() {
        lockButtonFadeInAnimator?.stopAnimation(true)
        lockButtonFadeOutAnimator?.stopAnimation(true)
        
        lockButtonFadeInAnimator
            = UIViewPropertyAnimator(duration: Constants.animationDuration, curve: .easeInOut) { [weak self] in
                guard let strongSelf = self else { return }
                
                strongSelf.lockButton.isHidden = false
                strongSelf.lockButton.alpha = 1.0
        }
        lockButtonFadeInAnimator?.addCompletion{ [weak self] _ in
            guard let strongSelf = self else { return }
            
            
            strongSelf.lockButtonFadeOutAnimator?.startAnimation(afterDelay: Constants.animationDelay)
        }
        
        lockButtonFadeOutAnimator
            = UIViewPropertyAnimator(duration: Constants.animationDuration, curve: .easeInOut) { [weak self] in
                guard let strongSelf = self else { return }
                
                strongSelf.lockButton.alpha = 0.05
        }
        lockButtonFadeOutAnimator?.addCompletion { [weak self] _ in
            guard let strongSelf = self else { return }
            
            strongSelf.lockButton.alpha = 0.0
            strongSelf.lockButton.isHidden = true
        }
    }
}

extension PlayerViewController: PlayerManagerDelegate {
    // MARK: PlayerManagerDelegate Methods
    func playerPlayed() {
        controlManager?.setPlayButtonUI(playState: .play)
        
        controlManager?.fadeInControlView()
    }
    
    func playerPaused() {
        controlManager?.setPlayButtonUI(playState: .pause)
        
        controlManager?.fadeInControlView()
    }
    
    func playerEnded() {
        controlManager?.setPlayButtonUI(playState: .replay)
        
        controlManager?.fadeInControlView()
    }
    
    func playerSeeked() {
        controlManager?.fadeInControlView()
    }
    
    func setTimeObserverValue(time: CMTime, totalTime: CMTime) {
        guard !isSliderChanging else { return }
        let value = Float(time.seconds / totalTime.seconds)
        
        controlManager?.setCurrentTimeLabel(currentTimeText: time.seconds.toTimeString)
        controlManager?.setTimeSliderUI(value: value)
    }
    
    func isPlayedFirst() {
        controlManager?.removeAndInitializeAnimations()
        controlManager?.fadeInControlView()
        lockButton.isHidden = false
        
        controlManager?.stopActivtiyIndicator()
        controlManager?.setPlayButtonUI(playState: .play)
        controlManager?.fadeInControlView()
        
        removeAndInitailizeLockButtonAnimators()
        lockButtonFadeInAnimator?.startAnimation()
    }
}

extension PlayerViewController: ControlManagerDelegate {
    // MARK: ControlManagerDelegate Methods
    func updateNewCMTime(using ratio: Double) {
        guard let newCMTime = playerManager?.getCMTime(with: ratio) else { return }
        self.newCMTime = newCMTime
        
        controlManager?.setCenterTimeLabelUI(timeText: newCMTime.toTimeString)
    }
    
    func seekToTimeIfNeeded() {
        guard let newCMTime = newCMTime else { return }
        
        playerManager?.player.seek(to: newCMTime)
    }
}

extension PlayerViewController: UIGestureRecognizerDelegate {
    // MARK: UIGestureRecognizerDelegate Methods
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let isSliderView = touch.view is UISlider
        
        return !isSliderView
    }
}
