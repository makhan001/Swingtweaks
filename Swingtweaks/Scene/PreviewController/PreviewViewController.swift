//
//  PreviewViewController.swift
//  Swingtweaks
//
//  Created by Dr.Mac on 10/01/22.
//

import UIKit
import AVFoundation
import AVKit
import Photos

class PreviewViewController: UIViewController {

@IBOutlet weak var videoView:UIView!
    
    
    var player: AVPlayer?
    var playerController: AVPlayerViewController?
    var videoOutputURL: URL?
    var getPreviewVc: ((_ name:String)->())?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        player?.actionAtItemEnd = AVPlayer.ActionAtItemEnd.none
        playerController?.showsPlaybackControls = true
        playerController?.hidesBottomBarWhenPushed = true
        print("RecordingVideoURL",videoOutputURL)
        if self.videoOutputURL != nil {
            self.setVideo(url: videoOutputURL!)
        }
    }
    
    @IBAction func discardButtonAction(_ sender: UIButton) {
        self.dismiss(animated: false, completion: nil)
        self.getPreviewVc!("Ok")
    }
    @IBAction func saveButtonAction(_ sender: UIButton) {
        self.saveVideoToLibrary(newVideoURL: videoOutputURL!)
    }
}
extension PreviewViewController {
    private func removePlayer() {
        player?.pause()
        player = nil
        playerController?.player?.pause()
        playerController?.player = nil
        if let view = playerController?.view {
            videoView.willRemoveSubview(view)
        }
        playerController?.view.removeFromSuperview()
        playerController = nil
    }
    private func setVideo(url: URL) {
        removePlayer()
        player = AVPlayer(url: url)
        playerController = AVPlayerViewController()
        playerController?.player = player
        player?.allowsExternalPlayback = true
        player?.usesExternalPlaybackWhileExternalScreenIsActive = true
        self.videoView.addSubview((playerController?.view)!)
        playerController?.view.frame = CGRect(x: 0, y: 0, width: self.videoView.bounds.width, height: self.videoView.bounds.height)
        player?.currentItem?.audioTimePitchAlgorithm = .timeDomain
        player?.play()
    }
    func saveVideoToLibrary(newVideoURL: URL) {
        PHPhotoLibrary.shared().performChanges( {
          PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: newVideoURL)
        }) { [weak self] (isSaved, error) in
          if isSaved {
            print("Video saved.")
            DispatchQueue.main.async {
                self?.showOneButtonAlert(title: "Saved", message: "Video saved in gallery", firstBtnTitle: "Ok", completion: { (result) in
                    print(result)
                    if result == "Ok" {
                        self?.dismiss(animated: false, completion: nil)
                        self?.getPreviewVc!("Ok")
                    }
                })
            }
          } else {
            print("Cannot save video.")
            print(error ?? "unknown error")
          }
        }
    }
}
