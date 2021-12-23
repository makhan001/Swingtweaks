//
//  ViewController.swift
//  Swingtweaks
//
//  Created by Lokesh Patil on 09/12/21.
//

import UIKit
import AVFoundation
import AVKit
import AssetsLibrary
import VideoEditor

class ViewController: UIViewController {
    
    @IBOutlet weak var recodeBtn: UIButton!
    @IBOutlet weak var playBtn: UIButton!
    var state: AGAudioRecorderState = .Ready
    var recorder: AGAudioRecorder = AGAudioRecorder(withFileName: "TempFile")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        recodeBtn.setTitle("Recode", for: .normal)
        playBtn.setTitle("Play", for: .normal)
        recorder.delegate = self
    }
    
    @IBAction func PlayVideo(_ sender: Any) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "CreateTweak" ) as! CreateTweakViewController
        vc.updatedUrl = Bundle.main.url(forResource: "videoApp", withExtension: "mp4")
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func mergeVideo(_ sender: Any) {
        merge()
    }
    
    @IBAction func recode(_ sender: UIButton) {
        recorder.doRecord()
    }
    
    @IBAction func play(_ sender: UIButton) {
        recorder.doPlay()
    }
    /**
     Create and show an alert view
     */
    fileprivate func createAlertView(message: String?) {
        let messageAlertController = UIAlertController(title: "Message", message: message, preferredStyle: .alert)
        messageAlertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction!) in
            messageAlertController.dismiss(animated: true, completion: nil)
        }))
        DispatchQueue.main.async { [weak self] in
            self?.present(messageAlertController, animated: true, completion: nil)
        }
    }
    
    
}

extension ViewController: AGAudioRecorderDelegate {
    func agAudioRecorder(_ recorder: AGAudioRecorder, withStates state: AGAudioRecorderState) {
        switch state {
        case .error(let e): debugPrint(e)
        case .Failed(let s): debugPrint(s)
        case .Finish:
            recodeBtn.setTitle("Recode", for: .normal)
        case .Recording:
            recodeBtn.setTitle("Recoding Finished", for: .normal)
        case .Pause:
            playBtn.setTitle("Pause", for: .normal)
        case .Play:
            playBtn.setTitle("Play", for: .normal)
        case .Ready:
            recodeBtn.setTitle("Recode", for: .normal)
            playBtn.setTitle("Play", for: .normal)
        }
        debugPrint(state)
    }
    
    func agAudioRecorder(_ recorder: AGAudioRecorder, currentTime timeInterval: TimeInterval, formattedString: String) {
        debugPrint(formattedString)
    }
}

extension ViewController {
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
                                                    startTime: CMTime.zero,
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
