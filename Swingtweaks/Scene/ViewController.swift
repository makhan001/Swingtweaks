//
//  ViewController.swift
//  Swingtweaks
//
//  Created by Lokesh Patil on 09/12/21.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    @IBOutlet weak var tableView:UITableView!
    let videoSettings = [
        AVVideoCodecKey: AVVideoCodecType.h264,
        AVVideoWidthKey: 640,
        AVVideoHeightKey: 480
    ] as [String : Any] as [String : Any]
    
    var videoConverter: MAKImageToVideo!

    var frames:[UIImage] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        self.tableView.isHidden = true
        self.videoConverter = MAKImageToVideo(videoSettings: videoSettings)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    @IBAction func PlayVideo(_ sender: Any) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "CreateTweak" ) as! CreateTweakViewController
        vc.didReload = didReload
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func didReload(frames: [UIImage]) {
        DispatchQueue.main.async {
            self.frames = frames
            self.tableView.isHidden = false
            self.tableView.reloadData()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                
                makeMovie(size: frames.first!.size, images: frames)
                
//                for obj in self.frames {
//                    
////                    self.videoConverter.createMovieFrom(image: obj, duration: 5) { videoURL in
////                        print("videoURL is ----> \(videoURL)")
////                    }
//                }
            }
        }
    }
}


extension ViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.frames.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell") else { return UITableViewCell() }
        cell.imageView?.image = self.frames[indexPath.row]
        return cell
    }
}
