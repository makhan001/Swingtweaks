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
import ReplayKit

class CreateTweakViewController: UIViewController {
    
    @IBOutlet weak var videoView:UIView!
    @IBOutlet weak var btnBack:UIButton!
    @IBOutlet weak var btnPlay:UIButton!
    @IBOutlet weak var btnPencil:UIButton!
    @IBOutlet weak var btnZoom:UIButton!
    @IBOutlet weak var ViewSpeed:UIView!
    @IBOutlet weak var btnSave:UIButton!
    @IBOutlet weak var btnSpeed:UIButton!
    @IBOutlet weak var btnColor:UIButton!
    @IBOutlet weak var btnEraser:UIButton!
    @IBOutlet weak var btnRecord:UIButton!
    @IBOutlet weak var btnCircle:UIButton!
    @IBOutlet weak var btnSquare:UIButton!
    @IBOutlet weak var btnSpeedHalf:UIButton!
    @IBOutlet weak var btnSpeedNormal:UIButton!
    @IBOutlet weak var btnSpeedOneEight:UIButton!
    @IBOutlet weak var btnSpeedOneFourth:UIButton!
    @IBOutlet weak var btnAnnotationShapes:UIButton!
    @IBOutlet weak var btnDrawLine:UIButton!
    @IBOutlet weak var btnBackward:UIButton!
    @IBOutlet weak var btnSwingTweak:UIButton!
    //Hide UI
    @IBOutlet weak var toolsStackView:UIStackView!
    @IBOutlet weak var recordingBottomView:UIView!
    @IBOutlet weak var playBottomView:UIView!
    @IBOutlet weak var saveDeleteBottomView:UIView!
    @IBOutlet weak var SwingTweakBottomView:UIView!
    
    var videoUrl: URL?
    var videoOutputURL: URL?
    var playerVedioRate:Float = 1.0
    var player: AVPlayer?
    var playerController: AVPlayerViewController?
    let screenRecorder = RPScreenRecorder.shared()
    
    var playerPauseTime:Float64 = 0.0
    var audioDurationTime:Float64 = 0.0
    var isPlaying: Bool {
        return player?.rate != 0 && player?.error == nil
    }
    //  Tools Editors
    var assetsGenerator:AVAssetImageGenerator!
    //Tools Setup
    lazy var drawingView: DrawsanaView = {
        let drawingView = DrawsanaView()
        return drawingView
    }()
    let strokeWidths: [CGFloat] = [5,10,20]
    var strokeWidthIndex = 0
    lazy var selectionTool = { return SelectionTool(delegate: self) }()
    lazy var tools: [DrawingTool] = { return [
        PenTool(),
        EllipseTool(),
        RectTool(),
        EraserTool(),
        LineTool(),
        selectionTool
    ] }()
    private let addOverlayEditor = addOverlayImageLibrary()
    var isToolAdded:Bool = false
    var isAudioAdded:Bool = false
    
    var recordigURLsArray:[URL] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        SetUp()
        btnSave.isUserInteractionEnabled = false
        self.showHideBottomTopView(isHidden: true)
    }
    func showHideBottomTopView(isHidden: Bool) {
        self.toolsStackView.isHidden = isHidden
        self.recordingBottomView.isHidden = !isHidden
        self.saveDeleteBottomView.isHidden = isHidden
        self.SwingTweakBottomView.isHidden = !isHidden
        self.btnRecord.isHidden = isHidden
        self.btnBackward.isHidden = isHidden
        self.btnPlay.isUserInteractionEnabled = !isHidden
    }
}

extension CreateTweakViewController{
    private func SetUp() {
        [btnBack, btnPlay, btnSpeed, btnRecord, btnPencil, btnCircle, btnSquare, btnAnnotationShapes, btnZoom, btnColor, btnEraser, btnSpeedHalf, btnSpeedNormal, btnSpeedOneFourth, btnSpeedOneEight, btnSave, btnDrawLine, btnSwingTweak].forEach {
            $0?.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
        }
        player?.addObserver(self, forKeyPath: "rate", options: [], context: nil)
        player?.actionAtItemEnd = AVPlayer.ActionAtItemEnd.none
        playerController?.showsPlaybackControls = true
        playerController?.hidesBottomBarWhenPushed = true
        guard let newurl =  videoUrl else {
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
        case btnPencil:
            self.lineAction()
            saveBtnInitialSetup()
        case btnDrawLine:
            drawLineAction()
            saveBtnInitialSetup()
        case btnCircle:
            self.circleAction()
            saveBtnInitialSetup()
        case btnSquare:
            self.rectangleAction()
            saveBtnInitialSetup()
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
        case btnSave:
            print("btnSave")
        case btnSwingTweak:
            print("SwingTK")
            self.swingTweakButtonAction()
        default:
            break
        }
    }
    func swingTweakButtonAction() {
        self.showHideBottomTopView(isHidden: false)
        self.recordingBottomView.isHidden = false
    }
    private func playAction() {
        if self.btnPlay.isSelected {
            //Stop recording
            self.btnPlay.isSelected = false
           // self.stopRecording()
            if #available(iOS 14.0, *) {
                self.stopRecordingCreateVideo()
            } else {
                // Fallback on earlier versions
            }
        }
        else {
            //Start recording
            self.btnPlay.isSelected = true
            showTwoButtonAlert(title: "Alert", message: "Do you also want to add audio?", firstBtnTitle: "Yes", SecondBtnTitle:"No") { value in
                if value == "Yes" {
                    self.startRecording(isMicrophoneEnabled: true)
                }
                else{
                    self.startRecording(isMicrophoneEnabled: false)
                    
                }
            }
        }
    }
    
    private func speedAction() {
        ViewSpeed.isHidden = false
    }
    private func recordAction() {
        if self.btnRecord.isSelected {
            screenRecorder.isMicrophoneEnabled = false
            self.btnRecord.isSelected = false
        }
        else{
            screenRecorder.isMicrophoneEnabled = true
            self.btnRecord.isSelected = true
        }
//        self.isAudioAdded = true
//        self.btnSave.isUserInteractionEnabled = true
//        self.btnSave.backgroundColor = .blue
//        player?.pause()
//        print(playerPauseTime)
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
        self.toolsSetup(toolIndex: 5)
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
    private func drawLineAction() {
        self.toolsSetup(toolIndex: 4)
    }
    private func speedSelectionAction(speedretio:Int,speed:Float) {
        playerVedioRate = speed
        player?.rate = playerVedioRate
        ViewSpeed.isHidden = true
        btnSpeed.setTitle("1/\(speedretio)", for: .normal)
    }
    private func saveBtnInitialSetup() {
        self.isToolAdded = true
        btnSave.isUserInteractionEnabled = true
        btnSave.backgroundColor = .blue
    }
    
}
extension CreateTweakViewController {
    func toolsSetup(toolIndex: Int) {
        view.addSubview(drawingView)
        Drawing.debugSerialization = true
        drawingView.set(tool: tools[toolIndex])
        drawingView.backgroundColor = .clear
        drawingView.userSettings.strokeColor = Constants.colors.first!
        drawingView.userSettings.fillColor = Constants.colors.last!
        drawingView.userSettings.strokeWidth = strokeWidths[strokeWidthIndex]
        drawingView.userSettings.fontName = "Marker Felt"
        drawingView.translatesAutoresizingMaskIntoConstraints = false
        drawingView.applyConstraints { $0.width(self.videoView.frame.width).leading(self.videoView.frame.minX).height(self.videoView.frame.height).trailing(self.videoView.frame.minY).top(100).bottom(-140) }
    }
}

extension CreateTweakViewController: SelectionToolDelegate {
    func selectionToolDidTapOnAlreadySelectedShape(_ shape: ShapeSelectable) {
        if shape as? TextShape != nil {
        } else {
            drawingView.toolSettings.selectedShape = nil
        }
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


extension CreateTweakViewController: RPPreviewViewControllerDelegate {
    
    func startRecording(isMicrophoneEnabled:Bool) {
        guard screenRecorder.isAvailable else {
            print("Recording is not available at this time.")
            return
        }
        screenRecorder.isMicrophoneEnabled = isMicrophoneEnabled
        screenRecorder.startRecording{ [unowned self] (error) in
            guard error == nil else {
                print("There was an error starting the recording.")
                return
            }
            print("Started Recording Successfully")
        }
    }
    
    func stopRecording() {
        screenRecorder.stopRecording { [unowned self] (preview, error) in
            guard preview != nil else {
                print("Preview controller is not available.")
                return
            }
            showTwoButtonAlert(title: "Recording Finished", message: "Would you like to edit or delete your recording?", firstBtnTitle: "Delete", SecondBtnTitle: "Edit") { value in
                if value == "Edit" {
                    preview?.previewControllerDelegate = self
                    self.present(preview!, animated: true, completion: nil)
                }
                else{
                    self.screenRecorder.discardRecording(handler: { () -> Void in
                        print("Recording suffessfully deleted.")
                    })
                }
            }
        }
    }
    
    @available(iOS 14.0, *)
    func stopRecordingCreateVideo() {
        self.videoOutputURL = tempURL()
        print("videoOutputURL",self.videoOutputURL)
        if self.videoOutputURL != nil {
            self.recordigURLsArray.append(self.videoOutputURL!)
        }
        self.screenRecorder.stopRecording(withOutput: self.videoOutputURL!) { (errorVideo) in
            print("ErrorVideo", errorVideo)
            if errorVideo == nil {
                self.saveVideoToPhotos(newVideoURL: self.videoOutputURL!)
            }
        }
        print("recordigURLsArrayCount", self.recordigURLsArray.count)
    }
    func tempURL() -> URL? {
        let directory = NSTemporaryDirectory() as NSString
        if directory != "" {
            let path = directory.appendingPathComponent(NSUUID().uuidString + ".mp4")
            return URL(fileURLWithPath: path)
        }
        return nil
    }
    func saveMultipleVideoSetup() {
        
    }
    func saveVideoToPhotos(newVideoURL: URL) {
        PHPhotoLibrary.shared().performChanges( {
          PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: newVideoURL)
        }) { [weak self] (isSaved, error) in
          if isSaved {
            print("Video saved.")
          } else {
            print("Cannot save video.")
            print(error ?? "unknown error")
          }
        }
    }
    func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
        dismiss(animated: true)
    }
}

