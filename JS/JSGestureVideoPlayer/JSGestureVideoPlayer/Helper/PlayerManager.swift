//
//  PlayerManager.swift
//  JSGestureVideoPlayer
//
//  Created by Alpaca on 2018. 5. 17..
//  Copyright © 2018년 Alpaca. All rights reserved.
//

import Foundation
import AVFoundation

protocol PlayerManagerDelegate: class {
    func playerPlayed()
    func playerPaused()
    func playerSeeked()
    func playerEnded()
    func setTimeObserverValue(time: CMTime, totalTime: CMTime)
    func isPlayedFirst()
}

class PlayerManager: NSObject {
    
    // MARK: Public Properties
    public weak var delegate: PlayerManagerDelegate?
    
    public var asset: AVAsset
    public var player: AVPlayer
    
    // MARK: Private Properties
    private var playerItemObserverList: [NSKeyValueObservation] = []
    
    private var timeObserverToken: Any?
    
    private var playerItemStatus: AVPlayerItemStatus = .unknown
    private var isFirstPlaying: Bool = true
    
    private var chaseTime: CMTime = kCMTimeZero
    private var isSeekInProgress: Bool = false
    
    // MARK: Initialize Methods
    init(asset: AVAsset) {
        self.asset = asset
        player = AVPlayer()
    }
    
    deinit {
        removePeriodicTimeObserver()
        removePlayerItemObserver()
    }
    
    // MARK: Prepare Playback
    public func prepareToPlay() {
        // PlayerItem 준비
        let assetKeys = ["playable", "hasProtectedContent"]
        let playerItem = AVPlayerItem(asset: asset, automaticallyLoadedAssetKeys: assetKeys)
        
        let playerItemObserver = playerItem.observe(\.status) { [weak self] (playerItem, _) in
            guard let strongSelf = self else { return }
            
            strongSelf.playerItemStatus = playerItem.status
            
            switch playerItem.status {
            case .readyToPlay:
                guard strongSelf.isFirstPlaying else { return }
                strongSelf.player.currentItem?.preferredPeakBitRate = 0
                strongSelf.player.play()
                
                strongSelf.delegate?.isPlayedFirst()
                strongSelf.isFirstPlaying = false
            case .failed:
                assertionFailure("PlayerItem failed.")
            case .unknown:
                assertionFailure("PlayerItem is not yet ready.")
            }
        }
        playerItemObserverList.append(playerItemObserver)

        NotificationCenter.default.addObserver(self, selector: #selector(didReceivePlayerItmeEnded), name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)
        
        // 처음에 제한을 두고 재생시작하면 풀기
        playerItem.preferredPeakBitRate = 2000
        
        // Player 준비
        player.replaceCurrentItem(with: playerItem)
        
        addPeriodicTimeObserver()
    }
    
    private func addPeriodicTimeObserver() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let strongSelf = self else { return }
            
            strongSelf.delegate?.setTimeObserverValue(time: time, totalTime: strongSelf.asset.duration)
        }
    }
    
    private func removePeriodicTimeObserver() {
        guard let timeObserverToken = timeObserverToken else { return }
        player.removeTimeObserver(timeObserverToken)
        self.timeObserverToken = nil
    }
    
    private func removePlayerItemObserver() {
        playerItemObserverList.removeAll()
    }
    
    @objc private func didReceivePlayerItmeEnded() {
        delegate?.playerEnded()
    }
    
    // MARK: Playback Methods
    public func play() {
        player.play()
        
        delegate?.playerPlayed()
    }
    
    public func pause() {
        player.pause()
        
        delegate?.playerPaused()
    }
    
    public func replay() {
        player.seek(to: kCMTimeZero)
        
        play()
    }
    
    public func changeTenSeconds(to direction: SeekToDirection) {
        let currentTimeSeconds = player.currentTime().seconds
        let tenSeconds: Double = 10.0
        let timeToBeChanged: CMTime = {
            switch direction {
            case .backward:
                return CMTime(seconds: currentTimeSeconds - tenSeconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
            case .forward:
                return CMTime(seconds: currentTimeSeconds + tenSeconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
            }
        }()
        
        player.seek(to: timeToBeChanged) { [weak self] _ in
            guard let strongSelf = self else { return }
            
            strongSelf.player.isPlaying ? strongSelf.play() : strongSelf.pause()
        }
        
        delegate?.playerSeeked()
    }
    
    public func timeSliderValueChanged(ratio: Float) {
        guard let totalSeconds = player.currentItem?.duration.seconds else { return }
        let currentTimeSeconds = Double(ratio) * totalSeconds
        let timeToBeChanged = CMTime(seconds: currentTimeSeconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        
        stopPlayingAndSeekSmoothlyToTime(newChaseTime: timeToBeChanged)
    }
    
    // MARK: TimeSlider ValueChanged
    private func stopPlayingAndSeekSmoothlyToTime(newChaseTime: CMTime) {
        guard CMTimeCompare(newChaseTime, chaseTime) != 0 else { return }
        chaseTime = newChaseTime
        
        guard !isSeekInProgress else { return }
        trySeekToChaseTime()
    }
    
    private func trySeekToChaseTime() {
        guard playerItemStatus == .readyToPlay else { return }
        actuallySeekToTime()
    }
    
    private func actuallySeekToTime() {
        isSeekInProgress = true
        let seekTimeInProgress = chaseTime
        
        player.seek(to: seekTimeInProgress) { [weak self] _ in
            guard let strongSelf = self else { return }
            
            if CMTimeCompare(seekTimeInProgress, strongSelf.chaseTime) == 0 {
                strongSelf.isSeekInProgress = false
            } else {
                strongSelf.trySeekToChaseTime()
            }
            
            guard let isPlaying = self?.player.isPlaying else { return }
            isPlaying ? strongSelf.play() : strongSelf.pause()
        }
    }
    
    // MARK: Get CMTime Methods
    public func getCMTime(with ratio: Double) -> CMTime? {
        let currentTimeSeconds = player.currentTime().seconds
        guard let assetDuration = player.currentItem?.duration.seconds else { return nil }
        
        let oneMinuteSeconds: Double = 60
        var newSeconds = currentTimeSeconds + oneMinuteSeconds * ratio
        if newSeconds > assetDuration {
            newSeconds = assetDuration
        } else if newSeconds < 0 {
            newSeconds = 0
        }
        
        return CMTime(seconds: newSeconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
    }
    
    public func getCMTimeWithTimeSlider(with value: Double) -> CMTime? {
        guard let assetDuration = player.currentItem?.duration.seconds else { return nil }
        
        var newSeconds = assetDuration * value
        if newSeconds > assetDuration {
            newSeconds = assetDuration
        } else if newSeconds < 0 {
            newSeconds = 0
        }
        
        return CMTime(seconds: newSeconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
    }
}
