//
//  VideoModel.swift
//  JSGestureVideoPlayer
//
//  Created by Alpaca on 2018. 5. 17..
//  Copyright © 2018년 Alpaca. All rights reserved.
//

import UIKit
import AVFoundation

class VideoModel {
    
    // MARK: Public Properties
    public var asset: AVURLAsset {
        didSet {
            getAssetPropertiesAsnychronously()
        }
    }
    public var remoteURL: URL?
    public var localURL: URL? {
        didSet {
            guard let localURL = localURL else { return }
            asset = AVURLAsset(url: localURL, options: [AVURLAssetAllowsCellularAccessKey: false])
        }
    }
    public var thumbnailImage: UIImage?
    
    public lazy var title: String = {
        if let remoteURL = remoteURL {
            return remoteURL.lastPathComponent
        } else if let localURL = localURL {
            return localURL.lastPathComponent
        }
        
        return ""
    }()
    
    // MARK: Private Properties
    private var downloadTask: AVAssetDownloadTask?
    
    // MARK: Initialize Methods
    init(remoteURL: URL) {
        self.remoteURL = remoteURL
        
        asset = AVURLAsset(url: remoteURL, options: [AVURLAssetAllowsCellularAccessKey: false])
        getAssetPropertiesAsnychronously()
    }
    
    init(localURL: URL) {
        self.localURL = localURL
        asset = AVURLAsset(url: localURL, options: [AVURLAssetAllowsCellularAccessKey: false])
    }
    
    // MARK: Public Methods
    public func setUpAssetDownload(downloadSession: AVAssetDownloadURLSession) {
        downloadTask = downloadSession.makeAssetDownloadTask(asset: asset,
                                                             assetTitle: " ",
                                                             assetArtworkData: nil,
                                                             options: nil)
        
        downloadTask?.resume()
    }
    
    // MARK: Private Properties
    private func getAssetPropertiesAsnychronously() {
        let keys: [String] = ["playable", "tracks"]
        asset.loadValuesAsynchronously(forKeys: keys) { [weak self] in
            guard let strongSelf = self else { return }
            
            var error: NSError? = nil
            let status = strongSelf.asset.statusOfValue(forKey: "tracks", error: &error)
            switch status {
            case .loaded:
                strongSelf.getThumbnailImage()
            default:
                print("tracks property load failed")
            }
        }
    }
    
    private func getThumbnailImage() {
        // 썸네일 이미지가 있는지 먼저 확인
        guard !asset.tracks(withMediaCharacteristic: .visual).isEmpty else { return }
        
        let imageGenerator: AVAssetImageGenerator = AVAssetImageGenerator(asset: asset)
        DispatchQueue.global().async { [weak self] in
            guard let strongSelf = self else { return }
            guard let thumbnailCGImage = try? imageGenerator.copyCGImage(at: CMTime(seconds: strongSelf.asset.duration.seconds / 2, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), actualTime: nil) else { return }
            
            strongSelf.thumbnailImage = UIImage(cgImage: thumbnailCGImage)
            
            NotificationCenter.default.post(name: NotificationName.didReceiveThumbnailImage, object: nil)
        }
    }
}
