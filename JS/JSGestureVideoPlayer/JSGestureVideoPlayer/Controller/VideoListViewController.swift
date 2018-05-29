//
//  VideoListViewController.swift
//  JSGestureVideoPlayer
//
//  Created by Alpaca on 2018. 5. 17..
//  Copyright © 2018년 Alpaca. All rights reserved.
//

import UIKit
import AVFoundation
import Alamofire

class VideoListViewController: UIViewController {
    
    @IBOutlet weak var videoListTableView: UITableView!
    
    // MARK: Private Properties
    private lazy var videoModelList: [VideoModel] = []
    
    private let rainVideoName: String = "rain"
    private let waterVideoName: String = "water"
    private let localVideoType: String = "mp4"
    
    private let cellIdentifier: String = "VideoListCell"
    
    private let downloadSessionIdentifier: String = "downloadSessionIdentifier"
    private lazy var downloadSession: AVAssetDownloadURLSession = {
        let configuration = URLSessionConfiguration.background(withIdentifier: downloadSessionIdentifier)
        configuration.allowsCellularAccess = false
        let downloadSession = AVAssetDownloadURLSession(configuration: configuration,
                                                        assetDownloadDelegate: self,
                                                        delegateQueue: .main)
        
        return downloadSession
    }()
    
    // MARK: Rotation Properties
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return [.portrait]
    }
    
    // MARK: LifeCycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUp()
    }
    
    // MARK: Setup Methods
    private func setUp() {
        createVideoModel()
        addNotificationObserver()
    }
    
    private func createVideoModel() {
        createRemoteVideoModel()
        createLocalVideoModel()
    }
    
    private func addNotificationObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveThumbnailImage), name: NotificationName.didReceiveThumbnailImage, object: nil)
    }
    
    // MARK: Create VideoModel
    private func createRemoteVideoModel() {
        Alamofire.request("https://dantonglaw.firebaseio.com/videolist.json")
            .validate()
            .responseJSON { [weak self] response in
                guard let strongSelf = self else { return }
                
                switch response.result {
                case .success(let resultValue):
                    guard let urlStringArray = resultValue as? [String] else { return }
                    
                    urlStringArray.forEach {
                        guard let videoURL = URL(string: $0) else { return }
                        
                        let videoModel = VideoModel(remoteURL: videoURL)
                        strongSelf.videoModelList.append(videoModel)
                    }
                    
                    // 로컬에 저장이 되어 있다면 로컬 URL을 넣음
                    strongSelf.checkLocalFileExisted()
                    strongSelf.videoListTableView.reloadData()
                default:
                    assertionFailure("Get videoURL Failed")
                }
        }
    }
    
    private func checkLocalFileExisted() {
        // UserDefaults에 다운로드 된 것이 있다면 넣어주기
        for videoModel in videoModelList.filter({ $0.localURL == nil }) {
            guard let remoteURLString = videoModel.remoteURL?.absoluteString else { return }
            if let localURLString = UserDefaults.standard.object(forKey: remoteURLString) as? String {
                let baseURL = URL(fileURLWithPath: NSHomeDirectory())
                let localURL = baseURL.appendingPathComponent(localURLString)
                
                videoModel.localURL = localURL
            }
        }
    }
    
    private func createLocalVideoModel() {
        if let rainVideoURL = getLocalVideoURL(videoName: rainVideoName) {
            videoModelList.append(VideoModel(localURL: rainVideoURL))
        }
        
        if let waterVideoURL = getLocalVideoURL(videoName: waterVideoName) {
            videoModelList.append(VideoModel(localURL: waterVideoURL))
        }
    }
    
    private func getLocalVideoURL(videoName: String) -> URL? {
        guard let videoFilePath = Bundle.main.path(forResource: videoName, ofType: localVideoType) else { return nil }
        
        return URL(fileURLWithPath: videoFilePath)
    }
    
    // MARK: Notification Selector Method
    @objc private func didReceiveThumbnailImage() {
        videoListTableView.reloadData()
    }
}

extension VideoListViewController: UITableViewDataSource {
    // MARK: UITableViewDataSource Methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return videoModelList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let videoListCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? VideoListCell ?? VideoListCell()
        
        let videoModel = videoModelList[indexPath.row]
        
        videoListCell.videoNameLabel.text = videoModel.title
        videoListCell.thumbnailImageView.image = videoModel.thumbnailImage
        
        return videoListCell
    }
}

extension VideoListViewController: UITableViewDelegate {
    // MARK: UITableViewDelegate Methods
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let videoModel = videoModelList[indexPath.row]
        if videoModel.localURL == nil || videoModel.asset.assetCache?.isPlayableOffline == false {
            videoModel.setUpAssetDownload(downloadSession: downloadSession)
        }
        
        guard let playerViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PlayerViewController") as? PlayerViewController else { return }
        playerViewController.playerManager = PlayerManager(asset: videoModel.asset)
        
        navigationController?.pushViewController(playerViewController, animated: true)
    }
}

extension VideoListViewController: AVAssetDownloadDelegate {
    // MARK: AVAssetDownloadDelegate Methods
    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didFinishDownloadingTo location: URL) {
        guard let videoModel = (videoModelList.filter { $0.remoteURL == assetDownloadTask.urlAsset.url })
            .first else { return }
        videoModel.localURL = location
        
        guard let remoteURLString = videoModel.remoteURL?.absoluteString else { return }
        UserDefaults.standard.set(location.relativePath, forKey: remoteURLString)
    }
}
