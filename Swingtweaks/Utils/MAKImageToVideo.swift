//
//  MAKImageToVideo.swift
//  Swingtweaks
//
//  Created by m@k on 15/12/21.
//

import UIKit
import Foundation
import AVFoundation


typealias CXEMovieMakerCompletion = (URL) -> Void
typealias CXEMovieMakerUIImageExtractor = (AnyObject) -> UIImage?

class MAKImageToVideo: NSObject {
    
    //MARK: Private Properties
    
    private var assetWriter:AVAssetWriter!
    private var writeInput:AVAssetWriterInput!
    private var bufferAdapter:AVAssetWriterInputPixelBufferAdaptor!
    private var videoSettings:[String : Any]!
    private var frameTime:CMTime!
    private var fileURL:URL!
    private var completionBlock: CXEMovieMakerCompletion?
    
    //MARK: Class Method
    
    class func videoSettings(codec:String, width:Int, height:Int) -> [String: Any]{
        if(Int(width) % 16 != 0){
            print("warning: video settings width must be divisible by 16")
        }
        
        let videoSettings:[String: Any] = [AVVideoCodecKey: AVVideoCodecType.h264,
                             AVVideoWidthKey: width,
                             AVVideoHeightKey: height]
        
        return videoSettings
    }
    
    //MARK: Public methods
    
    init(videoSettings: [String: Any]) {
        super.init()
        
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        var tempPath:String
        repeat{
            let random = arc4random()
            tempPath = paths[0] + "/\(random).mp4"
        }while(FileManager.default.fileExists(atPath: tempPath))
//        let tempPath = paths[0] + "/exprotvideo.mp4"
//        if(FileManager.default.fileExists(atPath: tempPath)){
//            guard (try? FileManager.default.removeItem(atPath: tempPath)) != nil else {
//                print("remove path failed")
//                return
//            }
//        }
        
        self.fileURL = URL(fileURLWithPath: tempPath)
        self.assetWriter = try! AVAssetWriter(url: self.fileURL, fileType: AVFileType.mov)
        
        self.videoSettings = videoSettings
        self.writeInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoSettings)
        assert(self.assetWriter.canAdd(self.writeInput), "add failed")
        
        self.assetWriter.add(self.writeInput)
        let bufferAttributes:[String: Any] = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB)]
        self.bufferAdapter = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: self.writeInput, sourcePixelBufferAttributes: bufferAttributes)
        self.frameTime = CMTimeMake(value: 1, timescale: 1)
    }
    
    func createMovieFrom(url: URL, duration: Int, withCompletion: @escaping CXEMovieMakerCompletion){
        var urls = [URL]()
        var index = duration
        while(index > 0){
            urls.append(url)
            index -= 1
        }
        self.createMovieFromSource(images: urls as [AnyObject], extractor:{(inputObject:AnyObject) ->UIImage? in
            return UIImage(data: try! Data(contentsOf: inputObject as! URL))}, withCompletion: withCompletion)
    }
    
    func createMovieFrom(image: UIImage, duration: Int,withCompletion: @escaping CXEMovieMakerCompletion){
        var images = [UIImage]()
        var index = duration
        while(index > 0){
            images.append(image)
            index -= 1
        }
        self.createMovieFromSource(images: images, extractor: {(inputObject:AnyObject) -> UIImage? in
        return inputObject as? UIImage}, withCompletion: withCompletion)
    }
    
    //MARK: Private methods
    
    private func createMovieFromSource(images: [AnyObject], extractor: @escaping CXEMovieMakerUIImageExtractor, withCompletion: @escaping CXEMovieMakerCompletion){
        self.completionBlock = withCompletion
        
//        self.assetWriter.startWriting()
        self.assetWriter.startSession(atSourceTime: CMTime.zero)
        
        let mediaInputQueue = DispatchQueue(label: "mediaInputQueue")
        var i = 0
        let frameNumber = images.count
        self.writeInput.requestMediaDataWhenReady(on: mediaInputQueue){
            while(true){
                if(i >= frameNumber){
                    break
                }
                
                if (self.writeInput.isReadyForMoreMediaData){
                    var sampleBuffer:CVPixelBuffer?
                    autoreleasepool{
                        let img = extractor(images[i])
                        if img == nil{
                            i += 1
                            print("Warning: counld not extract one of the frames")
//                            continue
                        }
                        sampleBuffer = self.newPixelBufferFrom(cgImage: img!.cgImage!)
                    }
                    if (sampleBuffer != nil){
                        if(i == 0){
                            self.bufferAdapter.append(sampleBuffer!, withPresentationTime: CMTime.zero)
                        }else{
                            let value = i - 1
                            let lastTime = CMTimeMake(value: Int64(value), timescale: self.frameTime.timescale)
                            let presentTime = CMTimeAdd(lastTime, self.frameTime)
                            self.bufferAdapter.append(sampleBuffer!, withPresentationTime: presentTime)
                        }
                        i = i + 1
                    }
                }
            }
            self.writeInput.markAsFinished()
            self.assetWriter.finishWriting {
                DispatchQueue.main.sync {
                    self.completionBlock!(self.fileURL)
                }
            }
        }
    }
    
    private func newPixelBufferFrom(cgImage:CGImage) -> CVPixelBuffer?{
        let options:[String: Any] = [kCVPixelBufferCGImageCompatibilityKey as String: true, kCVPixelBufferCGBitmapContextCompatibilityKey as String: true]
        var pxbuffer:CVPixelBuffer?
        let frameWidth = self.videoSettings[AVVideoWidthKey] as! Int
        let frameHeight = self.videoSettings[AVVideoHeightKey] as! Int
        
        let status = CVPixelBufferCreate(kCFAllocatorDefault, frameWidth, frameHeight, kCVPixelFormatType_32ARGB, options as CFDictionary?, &pxbuffer)
        assert(status == kCVReturnSuccess && pxbuffer != nil, "newPixelBuffer failed")
        
        CVPixelBufferLockBaseAddress(pxbuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pxdata = CVPixelBufferGetBaseAddress(pxbuffer!)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pxdata, width: frameWidth, height: frameHeight, bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pxbuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        assert(context != nil, "context is nil")
        
        context!.concatenate(CGAffineTransform.identity)
        context!.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
        CVPixelBufferUnlockBaseAddress(pxbuffer!, CVPixelBufferLockFlags(rawValue: 0))
        return pxbuffer
    }
}


