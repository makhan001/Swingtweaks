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
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func mergeVideo(_ sender: Any) {
        //mergeAudioWithVideo()
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
    
    private func mergeAudioWithVideo(){
        if let videoURL2 = Bundle.main.url(forResource: "videoApp", withExtension: "mov"),
           //let audioURL2 =   URL(string:recorder.fileUrl().path){
           let audioURL2 =  Bundle.main.url(forResource: "demoAudio", withExtension: "mp3") {
            LoadingView.lockView()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "SwingteaksddMMyyyyHHmmss"
            VideoGenerator.fileName =  "\(dateFormatter.string(from: Date()))"
            VideoGenerator.current.mergeVideoWithAudio(videoUrl: videoURL2, audioUrl: audioURL2) { (result) in
                LoadingView.unlockView()
                switch result {
                case .success(let url):
                    print(url)
                    let vc = self.storyboard?.instantiateViewController(withIdentifier: "CreateTweak" ) as! CreateTweakViewController
                    vc.updatedUrl = url
                    self.navigationController?.pushViewController(vc, animated: true)
                //    self.createAlertView(message: "self.FinishMergingVideoWithAudio")
                case .failure(let error):
                    print(error)
                    self.createAlertView(message: error.localizedDescription)
                }
            }
        } else {
            self.createAlertView(message:" self.Missing Video Files")
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
        if let videoLocalURL =  Bundle.main.url(forResource: "videoApp", withExtension: "mp4"),
           let firstAudioLocalURL =  Bundle.main.url(forResource: "TempFile 3", withExtension: "m4a"),
           let secondAudioLocalURL =  Bundle.main.url(forResource: "TempFile 2", withExtension: "m4a")
           {
            audioDuration(audioFileURL: firstAudioLocalURL)

            let videoAsset = VideoEditor.Asset(localURL: videoLocalURL, volume: 1.0)
            let firstAudioAsset = VideoEditor.Asset(localURL: firstAudioLocalURL, volume: 1,
                                                    startTime: CMTime.zero,
                                                    duration: CMTime(seconds: 6.0, preferredTimescale: 1))
            let secondAudioAsset = VideoEditor.Asset(localURL: secondAudioLocalURL, volume: 1,
                                                     startTime: CMTime(seconds: 8,  preferredTimescale: CMTimeScale(NSEC_PER_SEC)),
                                                     duration: CMTime(seconds: 6.0, preferredTimescale: 1))
            let videoEditor = VideoEditor()
            videoEditor.merge(video: videoAsset, audios: [firstAudioAsset, secondAudioAsset], progress: { progress in
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
    func audioDuration(audioFileURL:URL){
        let audioAsset = AVURLAsset.init(url: audioFileURL, options: nil)
        let duration = audioAsset.duration
        let durationInSeconds = CMTimeGetSeconds(duration)
        print("durationInSeconds \(durationInSeconds)")
    }
}
