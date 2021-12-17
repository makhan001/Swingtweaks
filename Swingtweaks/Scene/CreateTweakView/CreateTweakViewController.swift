//
//  CreateTweakViewController.swift
//  Swingtweaks
//
//  Created by Lokesh Patil on 09/12/21.
//

import UIKit
import AVFoundation
import AVKit
import Foundation

class CreateTweakViewController: UIViewController {
    
    @IBOutlet weak var videoView:UIView!
    @IBOutlet weak var btnBack:UIButton!
    @IBOutlet weak var btnPlay:UIButton!
    @IBOutlet weak var btnSpeed:UIButton!
    @IBOutlet weak var btnRecord:UIButton!
    @IBOutlet weak var btnLine:UIButton!
    @IBOutlet weak var btnCircle:UIButton!
    @IBOutlet weak var btnSquare:UIButton!
    @IBOutlet weak var btnAnnotationShapes:UIButton!
    @IBOutlet weak var btnZoom:UIButton!
    @IBOutlet weak var btnColor:UIButton!
    @IBOutlet weak var btnEraser:UIButton!
    @IBOutlet weak var imgFrames:UIImageView!

    var player: AVPlayer?
    var playerController: AVPlayerViewController?
    let urlVideo = "http://techslides.com/demos/sample-videos/small.mp4"
    let urlAudio = "https://www.learningcontainer.com/wp-content/uploads/2020/02/Kalimba.mp3"
    var updatedUrl: URL?
    let videoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: [String(kCVPixelBufferPixelFormatTypeKey): NSNumber(value: kCVPixelFormatType_32BGRA)])
    var totalVideoDuration = Float()
    var totalFramesPerSeconds = Float()
    var getCurrentFramePause = Float()
    var totalFPS = Float()
    
    //
    var frames:[UIImage] = []
    var generator:AVAssetImageGenerator!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        SetUp()
    }
}

extension CreateTweakViewController{
   private func SetUp() {
    guard let newurl =  updatedUrl else {
        return
    }
    setVideo(url:newurl)
       // self.playLocalVideo()
        [btnBack, btnPlay, btnSpeed, btnRecord, btnLine, btnCircle, btnSquare, btnAnnotationShapes, btnZoom, btnColor, btnEraser ].forEach {
            $0?.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
        }
    }
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
        
    }
    func playLocalVideo() {
        guard let path = Bundle.main.path(forResource: "videoApp", ofType: "mov") else {
            return
        }
        let videoURL = NSURL(fileURLWithPath: path)
        removePlayer()
        player = AVPlayer(url: videoURL as URL)
        playerController = AVPlayerViewController()
        playerController?.player = player
        player?.allowsExternalPlayback = true
        player?.usesExternalPlaybackWhileExternalScreenIsActive = true
        self.videoView.addSubview((playerController?.view)!)
        playerController?.view.frame = CGRect(x: 0, y: 0, width: self.videoView.bounds.width, height: self.videoView.bounds.height)
    }
}

// MARK:- Button Action
extension CreateTweakViewController {
    
    @objc func buttonPressed(_ sender: UIButton) {
        switch  sender {
        case btnBack:
            self.navigationController?.popViewController(animated: true)
        case btnPlay:
            self.playAction()
        case btnSpeed:
            self.speedAction()
        case btnRecord :
            self.recordAction()
        case btnLine:
            self.lineAction()
        case btnCircle:
            self.circleAction()
        case btnSquare:
            self.rectangleAction()
        case btnAnnotationShapes:
            self.AnnotationShapesAction()
        case btnZoom:
            self.zoomAction()
        case btnColor:
            self.colorAction()
        case btnEraser:
            self.eraserAction()
        default:
            break
        }
    }
    private func playAction() {
        if self.btnPlay.isSelected {
            self.btnPlay.isSelected = false //video pause
            //getCurrentFrames()
            getCurrentFramesOnPause()
            player?.pause()
        } else {
            self.btnPlay.isSelected = true //video playing
            player?.play()
            getTotalFramesCount()
            self.getAllFramesArray()
        }
    }
    
    func replaceFramesOnIndex() {
        for index in 0..<self.frames.count {
            if index % 3 == 0 {
                self.frames.remove(at: index)
                self.frames.insert(#imageLiteral(resourceName: "ImageNew"), at: index)
            }
        }
        print(self.frames)
        for index in 0..<self.frames.count {
            if index % 3 == 0 {
                let newImg = self.frames[index]
                print(newImg)
            }
        }
    }
    
    func getAllFramesArray() {
        let asset:AVAsset = AVAsset(url:URL(string: urlVideo)!)
           let duration:Float64 = CMTimeGetSeconds(asset.duration)
           self.generator = AVAssetImageGenerator(asset:asset)
           self.generator.appliesPreferredTrackTransform = true
           self.frames = []
        for index:Int in 0 ..< Int(self.totalFramesPerSeconds) {
              self.getFrame(fromTime:Float64(index))
           }
           self.generator = nil
         print("AllFrames", self.frames)
         replaceFramesOnIndex()
    }
    private func getFrame(fromTime:Float64) {
        let time:CMTime = CMTimeMakeWithSeconds(fromTime, preferredTimescale:1)
        let image:CGImage
        do {
           try image = self.generator.copyCGImage(at:time, actualTime:nil)
        } catch {
           return
        }
        self.frames.append(UIImage(cgImage:image))
    }
    func getCurrentFramesOnPause() {
        let pauseTime = (self.player?.currentTime())
        let paueseDuration = CMTimeGetSeconds(pauseTime!)
        self.getCurrentFramePause = self.totalFPS * Float(paueseDuration)
        print("PauseFrames", self.getCurrentFramePause)
    }
    func getTotalFramesCount() {
        let asset = AVURLAsset(url: URL(string: urlVideo)!, options: nil)
        let tracks = asset.tracks(withMediaType: .video)
        if let framePerSeconds = tracks.first?.nominalFrameRate {
            print("FramePerSeconds", framePerSeconds)
            self.totalFPS = framePerSeconds
            if let duration = self.player?.currentItem?.asset.duration {
                let totalSeconds = CMTimeGetSeconds(duration)
                self.totalVideoDuration = Float(totalSeconds)
                print("TotalDurationSeconds :: \(self.totalVideoDuration)")
                self.totalFramesPerSeconds = Float(totalSeconds) * framePerSeconds
                print("Total frames", self.totalFramesPerSeconds)
            }
        }
        
    }
    func getCurrentFrames() {
        let asset = AVAsset(url: URL(string: urlVideo)!)
        let assetImgGenerate = AVAssetImageGenerator(asset: asset)
        assetImgGenerate.appliesPreferredTrackTransform = true
        let time = self.player?.currentTime()
        do {
            let img = try assetImgGenerate.copyCGImage(at: time!, actualTime: nil)
            self.imgFrames.image = UIImage(cgImage: img)
        } catch {
            print("Img error")
        }
    }
    private func speedAction() {
        print("speedAction")
    }
    private func recordAction() {
        print("recordAction")
    }
    private func lineAction() {
        print("lineAction")
    }
    private func circleAction() {
        print("circleAction")
    }
    private func rectangleAction() {
        print("rectangleAction")
    }
    private func AnnotationShapesAction() {
        print("AnnotationShapesAction")
    }
    private func zoomAction() {
        print("zoomAction")
    }
    private func colorAction() {
        print("colorAction")
    }
    private func eraserAction() {
        print("eraserAction")
    }

}

