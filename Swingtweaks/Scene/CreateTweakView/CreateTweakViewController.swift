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
    @IBOutlet weak var imgView:UIView!
    
    @IBOutlet weak var imgDemo:UIImageView!
    
    
    var didReload:(([UIImage]) -> Void)?

    var player: AVPlayer?
    var playerController: AVPlayerViewController?
    //https://video.t-cdn.net/607e784467ebeef04eed0f3d/617bf0b13dbd43d126e0b2c3/617bf0a93dbd4373aee0b2c2/617bf0a93dbd4373aee0b2c2_Hd_Mp4_Avc_Aac_16x9_1920x1080p_24Hz_6Mbps.mp4 //FPerSeconds Optional(23.976025
    //“http://techslides.com/demos/sample-videos/small.mp4” //FPerSeconds Optional(30.0)
    let urlVideo = "https://video.t-cdn.net/607e784467ebeef04eed0f3d/617bf0b13dbd43d126e0b2c3/617bf0a93dbd4373aee0b2c2/617bf0a93dbd4373aee0b2c2_Hd_Mp4_Avc_Aac_16x9_1920x1080p_24Hz_6Mbps.mp4"

    let videoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: [String(kCVPixelBufferPixelFormatTypeKey): NSNumber(value: kCVPixelFormatType_32BGRA)])
    var totalVideoDuration = Float()
    var totalFramesPerSeconds = Float()
    var getCurrentFramePause = Float()
    var totalFPS = Float()
    
    
    var frames:[UIImage] = []
    var generator:AVAssetImageGenerator!
    
    //Tools Setup
    lazy var drawingView: DrawsanaView = {
      let drawingView = DrawsanaView()
      drawingView.delegate = self
     drawingView.operationStack.delegate = self
      return drawingView
    }()
    
    let strokeWidths: [CGFloat] = [
      5,
      10,
      20,
    ]
    var strokeWidthIndex = 0
    
    let imageView = UIImageView(image: UIImage(named: "download1"))
     
    lazy var tools: [DrawingTool] = { return [
      PenTool(),
      EllipseTool(),
      RectTool(),
      EraserTool(),
    ] }()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    func toolsSetup() {
        
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        view.addSubview(imageView) { $0.center() }
        view.addSubview(drawingView)
        
//        imageView.contentMode = .scaleAspectFit
//        drawingView.addSubview(imageView) { $0.center().height(500).width(500) }
        
       // view.addSubview(drawingView)
       // drawingView.addSubview(imgFrames)
        
        Drawing.debugSerialization = true
        drawingView.set(tool: tools[2])
       // drawingView.backgroundColor = .blue
        drawingView.userSettings.strokeColor = Constants.colors[2]!
        drawingView.userSettings.fillColor = Constants.colors.last!
        drawingView.userSettings.strokeWidth = strokeWidths[strokeWidthIndex]
        drawingView.userSettings.fontName = "Marker Felt"
       
        drawingView.translatesAutoresizingMaskIntoConstraints = false
        imgFrames.translatesAutoresizingMaskIntoConstraints = false
        
        drawingView.applyConstraints { $0.center().height(220).width(500) }
       // imgFrames.applyConstraints{ $0.center().height(220).width(500) }
        
        
       // let imageAspectRatio = imgFrames.image?.size.width ?? 200 / (imgFrames.image?.size.height)! ?? 200

//        NSLayoutConstraint.activate([
//            drawingView.centerXAnchor.constraint(equalTo: imgFrames.centerXAnchor),
//            drawingView.centerYAnchor.constraint(equalTo: imgFrames.centerYAnchor),
//            drawingView.widthAnchor.constraint(lessThanOrEqualTo: imgFrames.widthAnchor),
//            drawingView.heightAnchor.constraint(lessThanOrEqualTo: imgFrames.heightAnchor),
//            drawingView.widthAnchor.constraint(equalTo: drawingView.heightAnchor, multiplier: 3),
//            drawingView.widthAnchor.constraint(equalTo: imgFrames.widthAnchor).withPriority(.defaultLow),
//            drawingView.heightAnchor.constraint(equalTo: imgFrames.heightAnchor).withPriority(.defaultLow)
//
//            ])
    }
}

extension CreateTweakViewController{
    
    // Initial setup
   private func setup() {
    self.imgFrames.isHidden = true
    self.imgView.isHidden = true
        setVideo(url: URL(string: urlVideo)!)
        [btnBack, btnPlay, btnSpeed, btnRecord, btnLine, btnCircle, btnSquare, btnAnnotationShapes, btnZoom, btnColor, btnEraser ].forEach {
            $0?.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
        }
    }
    
    // remove setup
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
    
    // play video
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
        guard let path = Bundle.main.path(forResource: "fftg", ofType: "mov") else {
            return
        }
        let videoURL = NSURL(fileURLWithPath: path)
        
        // Create an AVPlayer, passing it the local video url path
        let player = AVPlayer(url: videoURL as URL)
        let controller = AVPlayerViewController()
        controller.player = player
        present(controller, animated: true) {
            player.play()
        }
    }
}

// MARK:- Button Action
extension CreateTweakViewController {
    
    @objc func buttonPressed(_ sender: UIButton) {
        switch  sender {
        case btnBack:
            self.didReload?(self.frames)
            self.navigationController?.popViewController(animated: true)
        case btnPlay:
            self.playAction()
        case btnSpeed:
            self.speedAction()
        case btnRecord :
            self.recordAction()
        case btnLine:
            self.lineAction(sender: sender)
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
            self.imgFrames.isHidden = false
            self.imgView.isHidden = false
            self.videoView.isHidden = true
            getCurrentFrames()
            //getCurrentFramesOnPause()
            player?.pause()
        } else {
            self.btnPlay.isSelected = true //video playing
            self.imgFrames.isHidden = true
            self.videoView.isHidden = false
            self.imgView.isHidden = true
            player?.play()
           // getTotalFramesCount()
           // self.getAllFramesArray()
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
            self.imgFrames.contentMode = .scaleAspectFit
            self.imgFrames.backgroundColor = .black
            
            self.toolsSetup()
            
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
    private func lineAction(sender: UIView) {
        print("pencilAction")
        Drawing.debugSerialization = true
        drawingView.set(tool: tools[0])
        drawingView.userSettings.strokeColor = Constants.colors.first!
        drawingView.userSettings.fillColor = Constants.colors.last!
        drawingView.userSettings.strokeWidth = strokeWidths[strokeWidthIndex]
        drawingView.userSettings.fontName = "Marker Felt"
        drawingView.translatesAutoresizingMaskIntoConstraints = false
        imgFrames.translatesAutoresizingMaskIntoConstraints = false
        presentPopover(
          ToolPickerViewController(tools: tools, delegate: self),
          sourceView: sender)
        
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
//jitu
extension CreateTweakViewController {
    private func presentPopover(_ viewController: UIViewController, sourceView: UIView) {
    viewController.modalPresentationStyle = .popover
    viewController.popoverPresentationController!.sourceView = sourceView
    viewController.popoverPresentationController!.sourceRect = sourceView.bounds
    viewController.popoverPresentationController!.delegate = self
    present(viewController, animated: true, completion: nil)
    }
}
extension CreateTweakViewController: UIPopoverPresentationControllerDelegate {
  func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
    return .none
  }
}

extension CreateTweakViewController: ToolPickerViewControllerDelegate {
  func toolPickerViewControllerDidPick(tool: DrawingTool) {
       self.videoView.isHidden = true
       drawingView.set(tool: tool)
      dismiss(animated: true, completion: nil)
  }
}
extension CreateTweakViewController: SelectionToolDelegate {
  /// When a shape is double-tapped by the selection tool, and it's text,
  /// begin editing the text
  func selectionToolDidTapOnAlreadySelectedShape(_ shape: ShapeSelectable) {
    if shape as? TextShape != nil {
        print("Shapeeee")
    } else {
      drawingView.toolSettings.selectedShape = nil
    }
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
