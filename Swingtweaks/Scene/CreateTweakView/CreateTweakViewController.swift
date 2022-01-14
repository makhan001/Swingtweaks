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
    @IBOutlet weak var ViewSpeed:UIView!
    @IBOutlet weak var btnSave:UIButton!
    @IBOutlet weak var btnSpeed:UIButton!
    @IBOutlet weak var btnTweak:UIButton!
    @IBOutlet weak var btnRecord:UIButton!
    @IBOutlet weak var btnSpeedHalf:UIButton!
    @IBOutlet weak var btnSpeedNormal:UIButton!
    @IBOutlet weak var btnSpeedOneEight:UIButton!
    @IBOutlet weak var btnSpeedOneFourth:UIButton!
    //Hide UI
    @IBOutlet weak var playBottomView:UIView!
    @IBOutlet weak var recordingBottomView:UIView!
    @IBOutlet weak var saveDeleteBottomView:UIView!
    @IBOutlet weak var SwingTweakBottomView:UIView!
    @IBOutlet weak var CollectionView:ToolItemCollectionView!
    //Play Seek UI
    @IBOutlet weak var btnUndo:UIButton!
    @IBOutlet weak var btnForward:UIButton!
    @IBOutlet weak var viewSeekBar: UIView!
    @IBOutlet weak var btnSeekPlay:UIButton!
    @IBOutlet weak var btnBackward:UIButton!
    @IBOutlet weak var playBackSlider: UISlider!
    @IBOutlet weak var lblVideoStartTime: UILabel!
   
    var lastValue:Float = 0.0
    var currentTime:Double = 0.0
    var videoUrl: URL?
    var videoOutputURL: URL?
    var playerVedioRate:Float = 1.0
    var player: AVPlayer?
    var playerController: AVPlayerViewController?
    let screenRecorder = RPScreenRecorder.shared()
    var tweakMode:Bool = false
    var playerPauseTime:Float64 = 0.0
    var audioDurationTime:Float64 = 0.0
    var isPlaying: Bool {
        return player?.rate != 0 && player?.error == nil
    }
    var timer = Timer()
    var assetsGenerator:AVAssetImageGenerator!
    lazy var drawingView: DrawsanaView = {
        let drawingView = DrawsanaView()
        drawingView.operationStack.delegate = self
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
    var value:Float64 = 0.0
    private var isSeekInProgress = false
    private var chaseTime = CMTime.zero
    private var preferredFrameRate: Float = 0.0
    private var totalFrames : Float = 0.0
   
    
    override func viewDidLoad() {
        super.viewDidLoad()
        playBackSlider.minimumValue = 0.0
        playBackSlider.maximumValue = 1.0
        playBackSlider.isContinuous = true
        self.lastValue = playBackSlider.value
        
        setUp()
        btnSave.isUserInteractionEnabled = false
        self.showHideBottomTopView(isHidden: true)
      
    }
    func showHideBottomTopView(isHidden: Bool) {
        CollectionView.isHidden = isHidden
        self.recordingBottomView.isHidden = !isHidden
        self.saveDeleteBottomView.isHidden = isHidden
        self.SwingTweakBottomView.isHidden = !isHidden
        self.btnRecord.isHidden = true
    }
                                   
}

extension CreateTweakViewController{
    private func setUp() {
        [btnBack, btnPlay, btnSpeed, btnRecord, btnSpeedHalf, btnSpeedNormal, btnSpeedOneFourth, btnSpeedOneEight, btnSave, btnTweak, btnSeekPlay, btnForward, btnBackward].forEach {
            $0?.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
        }
        player?.addObserver(self, forKeyPath: "rate", options: [], context: nil)
        player?.actionAtItemEnd = AVPlayer.ActionAtItemEnd.none
        playerController?.hidesBottomBarWhenPushed = true
        guard let newurl =  videoUrl else {
            return
        }
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(restartVideo),
                                               name: .AVPlayerItemDidPlayToEndTime,
                                               object: self.player?.currentItem)
        setVideo(url: newurl)
        CollectionView.configure(strokeColor: false)
        self.CollectionView.didSelectToolsAtIndex = didSelectToolsAtIndex
        setSeekBarSetup()
        playBackSlider.setThumbImage(UIImage(named: "sliderDisselect"), for: .normal)
        playBackSlider.setThumbImage(UIImage(named: "sliderSelect"), for: .highlighted)
        self.seekSliderSetup()
        
        playBackSlider.addTarget(self, action: #selector(onSliderValChanged(slider:event:)), for: .valueChanged)
        let forwordlongPress = UILongPressGestureRecognizer(target: self, action: #selector(forwordLongPress(gesture:)))
        forwordlongPress.minimumPressDuration = 0.5
        self.btnForward.addGestureRecognizer(forwordlongPress)
        
        let backwordlongPress = UILongPressGestureRecognizer(target: self, action: #selector(backwordLongPress(gesture:)))
        backwordlongPress.minimumPressDuration = 0.5
        self.btnBackward.addGestureRecognizer(backwordlongPress)
        btnUndo.addTarget(drawingView.operationStack, action: #selector(DrawingOperationStack.undo), for: .touchUpInside)
        getTotalFramesCount(videoUrl: videoUrl!)
    }
    func getTotalFramesCount(videoUrl: URL) {
        let asset = AVURLAsset(url: videoUrl, options: nil)
        let tracks = asset.tracks(withMediaType: .video)
        if let framePerSeconds = tracks.first?.nominalFrameRate {
            print("FramePerSeconds", framePerSeconds)
            self.preferredFrameRate = framePerSeconds
            if let duration = self.player?.currentItem?.asset.duration {
                let totalSeconds = CMTimeGetSeconds(duration)
                let totalFrame = Float(totalSeconds) * framePerSeconds
                totalFrames = totalFrame
            }
        }
    }
    @objc func restartVideo() {
        player?.currentItem?.seek(to: CMTime.zero, completionHandler: { _ in
            self.player?.play()
            self.player?.rate = self.playerVedioRate
            self.ViewSpeed.isHidden = true
        })
    }
    func seekSliderSetup() {
        let stackTap = UITapGestureRecognizer(target: self, action: #selector(self.jumpSliderTapped(_:)))
        self.playBackSlider?.isUserInteractionEnabled = true
        self.playBackSlider?.addGestureRecognizer(stackTap)
    }
    @objc func jumpSliderTapped(_ sender: UITapGestureRecognizer) {
        let pointTapped: CGPoint = sender.location(in: self.view)
        let positionOfSlider: CGPoint = playBackSlider.frame.origin
        let widthOfSlider: CGFloat = playBackSlider.frame.size.width
        let newValue = ((pointTapped.x - positionOfSlider.x) * CGFloat(playBackSlider.maximumValue) / widthOfSlider)
        playBackSlider.setValue(Float(newValue), animated: true)
        self.seekSliderDragged(seekSlider: playBackSlider)
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
        playerController?.showsPlaybackControls = false
        playerController?.player = player
        player?.allowsExternalPlayback = true
        player?.usesExternalPlaybackWhileExternalScreenIsActive = true
        self.videoView.addSubview((playerController?.view)!)
        playerController?.view.frame = CGRect(x: 0, y: 0, width: self.videoView.bounds.width, height: self.videoView.bounds.height)
        player?.currentItem?.audioTimePitchAlgorithm = .timeDomain
    }
    @objc func forwordLongPress(gesture: UILongPressGestureRecognizer) {
        if gesture.state == UIGestureRecognizer.State.began {
            print("Long Press Start")
            timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(forwardLongPressed), userInfo: nil, repeats: true)
        }else if gesture.state == UIGestureRecognizer.State.ended {
            print("Long Press Ended")
            timer.invalidate()
        }
    }
    @objc func forwardLongPressed(){
        player?.pause()
        btnSeekPlay.isSelected = false
        player?.currentItem?.step(byCount: 1)
    }
    @objc func backwordLongPress(gesture: UILongPressGestureRecognizer) {
        if gesture.state == UIGestureRecognizer.State.began {
            timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(backwordLongPressed), userInfo: nil, repeats: true)
        }else if gesture.state == UIGestureRecognizer.State.ended {
            timer.invalidate()
        }
    }
    @objc func backwordLongPressed(){
        player?.pause()
        btnSeekPlay.isSelected = false
        player?.currentItem?.step(byCount: -1)
    }
    
    @objc func onSliderValChanged(slider: UISlider, event: UIEvent) {
        if let touchEvent = event.allTouches?.first {
            switch touchEvent.phase {
            case .began:
                print("")
                print("begin with value \(slider.value)")
            case .moved:
                //print("moved with value \(slider.value)")
                DispatchQueue.main.async {
                    self.dragSlider(seekSlider: slider)
                }
            case .ended:
                player?.pause()
                btnSeekPlay.isSelected = false
            default:
                break
            }
        }
    }
}

// MARK:- Button Action
extension CreateTweakViewController {
    @objc func buttonPressed(_ sender: UIButton) {
        switch  sender {
        case btnBack:
            removePlayer()
            self.navigationController?.popViewController(animated: true)
        case btnPlay:
            self.playAction()
        case btnSpeed:
            self.speedAction()
        case btnRecord :
            self.recordAction()
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
            // stopRecording()
        case btnTweak:
            print("SwingTK")
            self.swingTweakButtonAction()
        case btnSeekPlay:
            seekPlayAction()
        case btnForward:
            DispatchQueue.main.async {
                self.seekForword()
            }
        case btnBackward:
            DispatchQueue.main.async {
                self.seekbackWord()
            }
        default:
            break
        }
    }
    
    func swingTweakButtonAction() {
        tweakMode = true
        player?.isMuted = true
        self.showHideBottomTopView(isHidden: false)
        self.recordingBottomView.isHidden = false
        viewSeekBar.isHidden = false
        lblVideoStartTime.isHidden = false
        self.player?.seek(to: CMTime.zero)
        player?.pause()
        btnPlay.isSelected = false
        btnUndo.isHidden = false
        btnSeekPlay.isSelected = false
        updateRecoredBtn()
    }
    private func updateRecoredBtn() {
        if tweakMode == true{
            if btnPlay.isSelected == false{
                btnPlay.setBackgroundImage(UIImage(named: "recording_on"), for: .normal)
                btnPlay.tintColor = .white
            }
            else {
                btnPlay.setBackgroundImage(UIImage(named: "recording_off"), for: .selected)
                btnPlay.tintColor = .black
            }
        }
    }
    private func playAction() {
        if tweakMode == true {
            if self.btnPlay.isSelected {
                //Stop recording
                self.btnPlay.isSelected = false
                if #available(iOS 14.0, *) {
                    self.stopRecordingCreateVideo()
                } else {
                    
                }
                updateRecoredBtn()
            }
            else {
                //Start recording
                self.btnPlay.isSelected = true
                self.startRecording(isMicrophoneEnabled: true)
                updateRecoredBtn()
            }
            
        }
        else{
            if self.btnPlay.isSelected {
                player?.pause()
                self.btnPlay.isSelected = false
                self.btnSeekPlay.isSelected  = false
            }
            else{
                player?.play()
                self.btnPlay.isSelected = true
                self.btnSeekPlay.isSelected  = true
            }
        }
    }
    
    private func speedAction() {
        ViewSpeed.isHidden = false
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(4), execute: {
            print("done")
            self.ViewSpeed.isHidden = true
        })
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
        CollectionView.configure(strokeColor:true)
        self.CollectionView.didSelectColorAtIndex = didSelectColorAtIndex
    }
    private func eraserAction() {
        print("drawingView.drawing.shapescount\(drawingView.drawing.shapes.count)")
        //self.drawingView.drawing.shapes.removeLast()
        //DrawingOperationStack.undo
      //  self.drawingView.drawing.shapes.remove(at: 1)
        //        self.toolsSetup(toolIndex: 3)
//        drawingView.toolSettings.selectedShape = nil
//        drawingView.userSettings.strokeWidth = strokeWidths[2]
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
    func seekPlayAction() {
        if self.btnSeekPlay.isSelected {
            self.player?.pause()
            self.btnSeekPlay.isSelected = false
            if !tweakMode{ self.btnPlay.isSelected = false }
        }
        else {
            self.player?.play()
            self.btnSeekPlay.isSelected = true
            if !tweakMode{ self.btnPlay.isSelected = true }
        }
    }
    func seekForword() {
        player?.pause()
        btnSeekPlay.isSelected = false
        player?.currentItem?.step(byCount: 1)
    }
    func seekbackWord() {
        player?.pause()
        btnSeekPlay.isSelected = false
        player?.currentItem?.step(byCount: -1)
    }
    func setSeekBarSetup() {
        let interval = CMTime(seconds: 0.1,
                              preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        let mainQueue = DispatchQueue.main
        self.playerController?.player?.addPeriodicTimeObserver(forInterval: interval, queue: mainQueue, using: { [weak self] (currentTime) in
            let currentSeconds = CMTimeGetSeconds(currentTime)
            guard let duration = self?.playerController?.player?.currentItem?.duration else { return }
            
            let totalSeconds = CMTimeGetSeconds(duration)
            self?.lblVideoStartTime.text = String(format: "%.3f", currentSeconds)
            let progress: Float = Float(currentSeconds/totalSeconds)
            self?.playBackSlider.value = Float (progress)
        })
    }
    
    
    func seekSliderDragged(seekSlider: UISlider) {
        if let duration = player?.currentItem?.duration {
            let totalSeconds = CMTimeGetSeconds(duration)
            let value = Float64(seekSlider.value) * totalSeconds
            self.lblVideoStartTime.text = String(format: "%.3f", value)
            
            let seekTime = CMTime(value: CMTimeValue(Float64(value)), timescale: 1)
            player?.seek(to: seekTime, completionHandler: { (completedSeek) in
                self.player?.pause()
                self.btnSeekPlay.isSelected = false
            })
        }
    }
    
    func dragSlider(seekSlider: UISlider) {
        self.player?.pause()
        if seekSlider.value > lastValue { // forward
            self.stepByFrame(in: .forward, slider: seekSlider)
        } else { // backward
            self.stepByFrame(in: .backward, slider: seekSlider)
        }
        self.lastValue = seekSlider.value
        //print("lastValue ---> \(lastValue)")
//        DispatchQueue.main.async {
//            //            if self.currentTime >= self.lasttime {
//            //                self.player?.currentItem?.step(byCount: 1)
//            //            }
//            //            else{
//            //                self.player?.currentItem?.step(byCount: -1)
//            //            }
//
//            self.player?.currentItem?.step(byCount: 1)
//            //            self.lasttime = self.currentTime
//            //            self.currentTime = Double(seekSlider.value)
//
//            self.btnSeekPlay.isSelected = false
//        }
    }
    
    @available(iOS 14.0, *)
    func stopRecordingCreateVideo() {
        self.videoOutputURL = tempURL(movieType: ".mov")
        print("videoOutputURL",self.videoOutputURL)
        self.screenRecorder.stopRecording(withOutput: self.videoOutputURL!) { (errorVideo) in
            print("ErrorVideo", errorVideo)
            if errorVideo == nil {
                DispatchQueue.main.async {
                    self.moveToPreviewController()
                }
            }
        }
    }
    func tempURL(movieType: String) -> URL? {
        let directory = NSTemporaryDirectory() as NSString
        if directory != "" {
            let path = directory.appendingPathComponent(NSUUID().uuidString + movieType)
            return URL(fileURLWithPath: path)
        }
        return nil
    }
    func moveToPreviewController() {
        let previewViewController = self.storyboard?.instantiateViewController(withIdentifier: "PreviewViewController") as! PreviewViewController
        previewViewController.videoOutputURL = self.videoOutputURL
        previewViewController.getPreviewVc = { response in
            if response == "Ok" {
                self.navigationController?.popViewController(animated: false)
            }
        }
        self.navigationController?.present(previewViewController, animated: true, completion: nil)
    }
    
}
extension CreateTweakViewController {
    public enum Direction {
        case forward
        case backward
    }

    public func seekWithFrame(to time: CMTime) {
        seekSmoothlyToTime(newChaseTime: time)
    }
    func stepByFrame(in direction: Direction, slider:UISlider) {
        let frameRate = preferredFrameRate //preferredFrameRate
            ?? player?.currentItem?.tracks
            .first(where: { $0.assetTrack?.mediaType == .video })?
                .currentVideoFrameRate ?? -1
        let time = player?.currentItem?.currentTime() ?? CMTime.zero
        let seconds = Double(1) / Double(frameRate)
        let timescale = Double(seconds) / Double(time.timescale) < 1 ? 600 : time.timescale
        print("slider.value\(slider.value)")
        print("totalfrmesCount\(totalFrames)")
        print("seconds\(seconds)")
        print("preferredFrameRate\(preferredFrameRate)")
        let oneFrame = CMTime(seconds:0.03, preferredTimescale: timescale)
        let next = direction == .forward
            ? CMTimeAdd(time, oneFrame)
            : CMTimeSubtract(time, oneFrame)
        seekSmoothlyToTime(newChaseTime: next)
    }
    func actuallySeekToTime() {
        isSeekInProgress = true
        let seekTimeInProgress = chaseTime
        player?.seek(to: seekTimeInProgress, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero) { [weak self] _ in
            guard let self = self else { return }
            let value = Double(seekTimeInProgress.value)
           // print("value ---> \(value.roundToDecimal(3))")
            let timescale = Double(seekTimeInProgress.timescale)
           // print("timescale ---> \(timescale.roundToDecimal(3))")
          //  print("result ---> \(Float(value / timescale))")
//            self.playBackSlider.setValue(Float(value / timescale), animated: false)
            if CMTimeCompare(seekTimeInProgress, self.chaseTime) == 0 {
                self.isSeekInProgress = false
            } else {
                self.trySeekToChaseTime()
            }
        }
    }
    private func trySeekToChaseTime() {
        guard player?.status == .readyToPlay else { return }
        actuallySeekToTime()
    }
    func seekSmoothlyToTime(newChaseTime: CMTime) {
        if CMTimeCompare(newChaseTime, chaseTime) != 0 {
            chaseTime = newChaseTime
            if !isSeekInProgress {
                trySeekToChaseTime()
            }
        }
    }
}
extension Double {
    func roundToDecimal(_ fractionDigits: Int) -> Double {
        let multiplier = pow(10, Double(fractionDigits))
        return Darwin.round(self * multiplier) / multiplier
    }
}
extension CreateTweakViewController {
    func toolsSetup(toolIndex: Int) {
        view.addSubview(drawingView)
        Drawing.debugSerialization = true
        drawingView.set(tool: tools[toolIndex])
        drawingView.backgroundColor = .clear
        drawingView.userSettings.fillColor = Constants.colors.last!
        drawingView.userSettings.strokeWidth = strokeWidths[strokeWidthIndex]
        drawingView.userSettings.fontName = "Marker Felt"
        drawingView.translatesAutoresizingMaskIntoConstraints = false
        drawingView.applyConstraints { $0.width(self.videoView.frame.width).leading(self.videoView.frame.minX).height(self.videoView.frame.height).trailing(self.videoView.frame.minY).top(120).bottom(-165) }
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

//Replaykit delegates
extension CreateTweakViewController: RPPreviewViewControllerDelegate {
    func startRecording(isMicrophoneEnabled:Bool) {
        guard screenRecorder.isAvailable else {
            print("Recording is not available at this time.")
            return
        }
        screenRecorder.isMicrophoneEnabled = isMicrophoneEnabled
        if #available(iOS 15.0, *) {
            screenRecorder.startRecording{ [unowned self] (error) in
                guard error == nil else {
                    print("There was an error starting the recording in 15")
                    return
                }
                print("Started Recording Successfully in 15")
            }
        } else {
            screenRecorder.startRecording(withMicrophoneEnabled: isMicrophoneEnabled) {(error) in
                guard error == nil else {
                    print("There was an error starting the recording 14 or less")
                    return
                }
                print("Started Recording Successfully in 14 or less")
            }
        }
    }
    
    func stopRecording() {
        screenRecorder.stopRecording { [unowned self] (preview, error) in
            guard preview != nil else {
                print("Preview controller is not available.")
                return
            }
            preview?.previewControllerDelegate = self
            self.present(preview!, animated: true, completion: nil)
        }
    }
    
    func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
        dismiss(animated: true)
    }
}
// MARK: Closure Callback
extension CreateTweakViewController {
    func didSelectToolsAtIndex(_ index: Int) {
        switch index {
        case 0:
            self.lineAction()
            saveBtnInitialSetup()
        case 1:
            self.drawLineAction()
            saveBtnInitialSetup()
        case 2:
            self.circleAction()
            saveBtnInitialSetup()
        case 3:
            self.rectangleAction()
            saveBtnInitialSetup()
        case 4:
            self.AnnotationShapesAction()
        case 5:
            self.zoomAction()
        case 6:
            self.colorAction()
        case 7:
            print("eraser")
           // self.eraserAction()
            
        default:
            print("pencil")
        }
    }
    /// Update button states to reflect undo stack
    private func applyUndoViewState() {
        btnUndo.isEnabled = drawingView.operationStack.canUndo
        btnUndo.alpha = btnUndo.isEnabled ? 1 : 0.5
    }
}
// MARK: Color Closure Callback
extension CreateTweakViewController {
    func didSelectColorAtIndex(_ index: Int) {
        drawingView.userSettings.strokeColor = Constants.colors[index]
        CollectionView.configure(strokeColor: false)
        self.CollectionView.didSelectToolsAtIndex = didSelectToolsAtIndex
    }
}

extension CreateTweakViewController: DrawingOperationStackDelegate {
  func drawingOperationStackDidUndo(_ operationStack: DrawingOperationStack, operation: DrawingOperation) {
    applyUndoViewState()
  }

  func drawingOperationStackDidRedo(_ operationStack: DrawingOperationStack, operation: DrawingOperation) {
    applyUndoViewState()
  }

  func drawingOperationStackDidApply(_ operationStack: DrawingOperationStack, operation: DrawingOperation) {
    applyUndoViewState()
  }
}
