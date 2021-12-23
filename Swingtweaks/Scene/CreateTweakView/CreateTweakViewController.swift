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
import QuickLook
import Photos
import VideoEditor

struct Constants {
 static let colors: [UIColor?] = [
  .black,
  .white,
  .red,
  .orange,
  .yellow,
  .green,
  .blue,
  .purple,
  .brown,
  .gray,
  nil
 ]
}

class CreateTweakViewController: UIViewController {
    
    @IBOutlet weak var videoView:UIView!
    @IBOutlet weak var btnBack:UIButton!
    @IBOutlet weak var btnPlay:UIButton!
    @IBOutlet weak var btnLine:UIButton!
    @IBOutlet weak var btnZoom:UIButton!
    @IBOutlet weak var ViewSpeed:UIView!
    @IBOutlet weak var btnSpeed:UIButton!
    @IBOutlet weak var btnColor:UIButton!
    @IBOutlet weak var btnEraser:UIButton!
    @IBOutlet weak var btnRecord:UIButton!
    @IBOutlet weak var btnPlayAudioRecord:UIButton!
    @IBOutlet weak var btnCircle:UIButton!
    @IBOutlet weak var btnSquare:UIButton!
    @IBOutlet weak var imgFrames:UIImageView!
    @IBOutlet weak var btnSpeedHalf:UIButton!
    @IBOutlet weak var btnSpeedNormal:UIButton!
    @IBOutlet weak var btnSpeedOneFourth:UIButton!
    @IBOutlet weak var btnSpeedOneEight:UIButton!
    @IBOutlet weak var btnAnnotationShapes:UIButton!
    @IBOutlet weak var btnSave:UIButton!
    var playerVedioRate:Float = 1.0
    var player: AVPlayer?
    var playerController: AVPlayerViewController?
    let urlVideo = "http://techslides.com/demos/sample-videos/small.mp4"
    let urlAudio = "https://www.learningcontainer.com/wp-content/uploads/2020/02/Kalimba.mp3"
    var updatedUrl: URL?
    let videoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: [String(kCVPixelBufferPixelFormatTypeKey): NSNumber(value: kCVPixelFormatType_32BGRA)])
    var recorder: AGAudioRecorder = AGAudioRecorder(withFileName: "TempFile")
    var playerPauseTime:Float64 = 0.0
    var isPlaying: Bool {
        return player?.rate != 0 && player?.error == nil
    }
    //  Tools Editors
      var totalVideoDuration = Float()
      var totalFramesPerSeconds = Float()
      var getCurrentFramePause = Float()
      var totalFPS = Float()
      var checkIsPlaying = 0
      var frames:[UIImage] = []
      var generator:AVAssetImageGenerator!
      //Tools Setup
      lazy var drawingView: DrawsanaView = {
       let drawingView = DrawsanaView()
       drawingView.delegate = self
       drawingView.operationStack.delegate = self
       return drawingView
      }()
      let strokeWidths: [CGFloat] = [5,10,20]
      var strokeWidthIndex = 0
      let imageView = UIImageView(image: UIImage(named: "download1"))
      lazy var tools: [DrawingTool] = { return [
       PenTool(),
       EllipseTool(),
       RectTool(),
       EraserTool(),
      ] }()
     // private let editor = VideoEditor()
     // end
    
    override func viewDidLoad() {
        super.viewDidLoad()
        SetUp()
        recorder.delegate = self
    }
}

extension CreateTweakViewController{
    private func SetUp() {
        // self.playLocalVideo()
        [btnBack, btnPlay, btnSpeed, btnRecord, btnLine, btnCircle, btnSquare, btnAnnotationShapes, btnZoom, btnColor, btnEraser, btnSpeedHalf, btnSpeedNormal, btnSpeedOneFourth, btnSpeedOneEight, btnPlayAudioRecord, btnSave ].forEach {
            $0?.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
        }
        player?.addObserver(self, forKeyPath: "rate", options: [], context: nil)
        player?.actionAtItemEnd = AVPlayer.ActionAtItemEnd.none
        playerController?.showsPlaybackControls = true
        // Show topView
        playerController?.hidesBottomBarWhenPushed = true
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(restartVideo),
                                               name: .AVPlayerItemDidPlayToEndTime,
                                               object: self.player?.currentItem)
        // Manage video player
        guard let newurl =  updatedUrl else {
            return
        }
        setVideo(url: newurl)
        
    }
    
    @objc func restartVideo() {
        player?.pause()
        player?.currentItem?.seek(to: CMTime.zero, completionHandler: { _ in
            self.player?.pause()
            self.player?.rate = self.playerVedioRate
            self.ViewSpeed.isHidden = true
        })
    }
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "rate", let player = object as? AVPlayer {
            if player.rate == 1 {
                print("Playing")
            } else {
                print("Paused")
            }
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
        player?.currentItem?.audioTimePitchAlgorithm = .timeDomain

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
        case btnSpeedHalf:
            speedSelectionAction(speedretio:2, speed: 1/2)
        case btnSpeedNormal:
            speedSelectionAction(speedretio:1, speed: 1/1)
        case btnSpeedOneFourth:
            speedSelectionAction(speedretio:4, speed: 1/4)
        case btnSpeedOneEight:
            speedSelectionAction(speedretio:8, speed: 1/8)
        case btnPlayAudioRecord:
            recorder.doPlay()
        case btnSave:
            merge()
        default:
            break
        }
    }
    private func playAction() {
        if isPlaying {
            player?.pause()
            self.btnPlay.isSelected = false
        }
        else {
            player?.play()
            player?.rate = playerVedioRate
            self.btnPlay.isSelected = true
        }
        
    }
    
    private func speedAction() {
        ViewSpeed.isHidden = false
    }
    private func recordAction() {
        player?.pause()
        getCurrentFramesOnPause()
        print(playerPauseTime)
        recorder.doRecord()
    }
    private func lineAction() {
        self.toolsSetup(toolIndex: 0)
    }
    private func circleAction() {
        self.toolsSetup(toolIndex: 1)
    }
    private func rectangleAction() {
        self.toolsSetup(toolIndex: 2)
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
        self.toolsSetup(toolIndex: 3)
    }
    private func speedSelectionAction(speedretio:Int,speed:Float) {
        playerVedioRate = speed
        player?.rate = playerVedioRate
        ViewSpeed.isHidden = true
        btnSpeed.setTitle("1/\(speedretio)", for: .normal)
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
        playerPauseTime = paueseDuration
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
}
extension CreateTweakViewController {
    func toolsSetup(toolIndex: Int) {
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        // view.addSubview(imageView) { $0.center().height(220).width(500) }
        view.addSubview(drawingView)
        Drawing.debugSerialization = true
        drawingView.set(tool: tools[toolIndex])
        drawingView.backgroundColor = .clear
        drawingView.userSettings.strokeColor = Constants.colors.first!
        drawingView.userSettings.fillColor = Constants.colors.last!
        drawingView.userSettings.strokeWidth = strokeWidths[strokeWidthIndex]
        drawingView.userSettings.fontName = "Marker Felt"
        drawingView.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        drawingView.applyConstraints { $0.width(self.videoView.frame.width).leading(self.videoView.frame.minX).height(self.videoView.frame.height).trailing(self.videoView.frame.minY).top(100).bottom(-100) }
      }
}

// Tools delegates
extension CreateTweakViewController: ColorPickerViewControllerDelegate {
  func colorPickerViewControllerDidPick(colorIndex: Int, color: UIColor?, identifier: String) {
    switch identifier {
    case "stroke":
      drawingView.userSettings.strokeColor = color
    case "fill":
      drawingView.userSettings.fillColor = color
    default: break;
    }
    dismiss(animated: true, completion: nil)
  }
}
extension CreateTweakViewController: DrawingOperationStackDelegate {
  func drawingOperationStackDidUndo(_ operationStack: DrawingOperationStack, operation: DrawingOperation) {
     print("ddd")
      //applyUndoViewState()
  }

  func drawingOperationStackDidRedo(_ operationStack: DrawingOperationStack, operation: DrawingOperation) {
    print("ddd")
    //applyUndoViewState()
  }

  func drawingOperationStackDidApply(_ operationStack: DrawingOperationStack, operation: DrawingOperation) {
    //applyUndoViewState()
  }
}
extension CreateTweakViewController: DrawsanaViewDelegate {
  /// When tool changes, update the UI
  func drawsanaView(_ drawsanaView: DrawsanaView, didSwitchTo tool: DrawingTool) {
   // toolButton.setTitle(drawingView.tool?.name ?? "", for: .normal)
  }

  func drawsanaView(_ drawsanaView: DrawsanaView, didChangeStrokeColor strokeColor: UIColor?) {
   // strokeColorButton.backgroundColor = drawingView.userSettings.strokeColor
   // strokeColorButton.setTitle(drawingView.userSettings.strokeColor == nil ? "x" : "", for: .normal)
  }

  func drawsanaView(_ drawsanaView: DrawsanaView, didChangeFillColor fillColor: UIColor?) {
   // fillColorButton.backgroundColor = drawingView.userSettings.fillColor
   // fillColorButton.setTitle(drawingView.userSettings.fillColor == nil ? "x" : "", for: .normal)
  }

  func drawsanaView(_ drawsanaView: DrawsanaView, didChangeStrokeWidth strokeWidth: CGFloat) {
    strokeWidthIndex = strokeWidths.firstIndex(of: drawingView.userSettings.strokeWidth) ?? 0
   // strokeWidthButton.setTitle("\(Int(strokeWidths[strokeWidthIndex]))", for: .normal)
  }

  func drawsanaView(_ drawsanaView: DrawsanaView, didChangeFontName fontName: String) {
  }

  func drawsanaView(_ drawsanaView: DrawsanaView, didChangeFontSize fontSize: CGFloat) {
  }

  func drawsanaView(_ drawsanaView: DrawsanaView, didStartDragWith tool: DrawingTool) {
  }

  func drawsanaView(_ drawsanaView: DrawsanaView, didEndDragWith tool: DrawingTool) {
  }
}
private extension NSLayoutConstraint {
  func withPriority(_ priority: UILayoutPriority) -> NSLayoutConstraint {
    self.priority = priority
    return self
  }
}


//
// Merge videos and Audio
//
extension CreateTweakViewController {
    //
    // Merge videos and Audio
    //
    func merge(){
        if let videoLocalURL =  Bundle.main.url(forResource: "videoApp", withExtension: "mp4")
           //let firstAudioLocalURL = URL(string:recorder.fileUrl().path),
           //let secondAudioLocalURL =   URL(string:recorder.fileUrl().path)
        {
            let videoAsset = VideoEditor.Asset(localURL: videoLocalURL, volume: 1.0)
            let firstAudioAsset = VideoEditor.Asset(localURL: recorder.fileUrl(), volume: 1,
                                                    startTime: CMTime(seconds:  playerPauseTime, preferredTimescale: 1),
                                                    duration: CMTime(seconds:  audioDuration(audioFileURL: recorder.fileUrl()), preferredTimescale: 1))
            
            let secondAudioAsset = VideoEditor.Asset(localURL: recorder.fileUrl(), volume: 1,
                                                     startTime: CMTime(seconds: 8,  preferredTimescale: CMTimeScale(NSEC_PER_SEC)),
                                                     duration: CMTime(seconds: 6.0, preferredTimescale: 1))
            
            let videoEditor = VideoEditor()
           // videoEditor.merge(video: videoAsset, audios: [firstAudioAsset, secondAudioAsset], progress: {
                videoEditor.merge(video: videoAsset, audios: [firstAudioAsset], progress: {
                progress in
                print(progress)
            }, completion: { result in
                switch result {
                case .success(let videoURL):
                    print(videoURL)
                    let vc = self.storyboard?.instantiateViewController(withIdentifier: "CreateTweak" ) as! CreateTweakViewController
                    vc.updatedUrl = videoURL
                    self.navigationController?.pushViewController(vc, animated: true)
                case .failure(let error):
                    print(error)
                }
            })
        }
        else{
            print("failed")
        }
    }
    
    //
    // audio duration
    //
    func audioDuration(audioFileURL:URL) -> Float64{
        let audioAsset = AVURLAsset.init(url: audioFileURL, options: nil)
        let duration = audioAsset.duration
        let durationInSeconds = CMTimeGetSeconds(duration)
        print("durationInSeconds \(durationInSeconds)")
        return durationInSeconds
    }
}

// Recorder Delegates
extension CreateTweakViewController: AGAudioRecorderDelegate {
    func agAudioRecorder(_ recorder: AGAudioRecorder, withStates state: AGAudioRecorderState) {
        switch state {
        case .error(let e): debugPrint(e)
        case .Failed(let s): debugPrint(s)
        case .Finish:
            btnRecord.isSelected = false
        case .Recording:
            btnRecord.isSelected = true
        case .Pause:
            print("Pause")
            btnPlayAudioRecord.isSelected = false
           // playBtn.setTitle("Pause", for: .normal)
        case .Play:
            print("Play")
            btnPlayAudioRecord.isSelected = true

           // playBtn.setTitle("Play", for: .normal)
        case .Ready:
            print("Recode")
//            recodeBtn.setTitle("Recode", for: .normal)
//            playBtn.setTitle("Play", for: .normal)
        }
        debugPrint(state)
    }
    
    func agAudioRecorder(_ recorder: AGAudioRecorder, currentTime timeInterval: TimeInterval, formattedString: String) {
        debugPrint(formattedString)
    }
}
