//
//  VideoWriter.swift
//  iOSTestTask
//
//  Created by Viacheslav Khakhulin on 14.02.2023.
//

import AVFoundation

final class VideoWriter {
    private(set) var isRecording = false
    private(set) var recordingStartTime = TimeInterval(0)
    
    private(set) var outputURL: URL
    private(set) var fileType: AVFileType
    private(set) var videoSize: CGSize
    
    private var assetWriter: AVAssetWriter
    private var assetWriterVideoInput: AVAssetWriterInput
    private var assetWriterPixelBufferInput: AVAssetWriterInputPixelBufferAdaptor
    
    init?(outputURL url: URL, fileType: AVFileType, size: CGSize) {
        self.outputURL = url
        self.fileType = fileType
        self.videoSize = size
        
        do {
            assetWriter = try AVAssetWriter(outputURL: url, fileType: fileType)
        } catch {
            return nil
        }
        
        let outputSettings: [String: Any] = [ AVVideoCodecKey : AVVideoCodecType.h264,
                                              AVVideoWidthKey : size.width,
                                             AVVideoHeightKey : size.height ]
        
        assetWriterVideoInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: outputSettings)
        assetWriterVideoInput.expectsMediaDataInRealTime = true
        
        let sourcePixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String : kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String : size.width,
            kCVPixelBufferHeightKey as String : size.height ]
        
        assetWriterPixelBufferInput = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: assetWriterVideoInput,
                                                                           sourcePixelBufferAttributes: sourcePixelBufferAttributes)
        
        assetWriter.add(assetWriterVideoInput)
    }
    
    func startRecording() {
        assetWriter.startWriting()
        assetWriter.startSession(atSourceTime: CMTime.zero)
        
        recordingStartTime = CACurrentMediaTime()
        isRecording = true
    }
    
    func finishRecording(_ completion: @escaping (URL?, AVFileType?, CGSize?) -> ()) {
        isRecording = false
        
        assetWriterVideoInput.markAsFinished()
        assetWriter.finishWriting(completionHandler: { [weak self] in
            completion(self?.outputURL, self?.fileType, self?.videoSize)
        })
    }
    
    func writeFrame(forTexture texture: MTLTexture, mipmapLevel: Int  = 0) {
        if !isRecording {
            return
        }
        
        guard assetWriterVideoInput.isReadyForMoreMediaData else {
            print("[VideoWriter] Asset writer video input isn't ready")
            return
        }
        
        guard let pixelBufferPool = assetWriterPixelBufferInput.pixelBufferPool else {
            print("[VideoWriter] Pixel buffer asset writer input did not have a pixel buffer pool available; cannot retrieve frame")
            return
        }
        
        var pixelBuffer: CVPixelBuffer? = nil
        let status  = CVPixelBufferPoolCreatePixelBuffer(nil, pixelBufferPool, &pixelBuffer)
        if status != kCVReturnSuccess {
            print("[VideoWriter] Could not get pixel buffer from asset writer input; dropping frame...")
            return
        }
        guard let pixelBuffer = pixelBuffer else {
            print("[VideoWriter] Recieved from pool pixel buffer is nil")
            return
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        let pixelBufferBytes = CVPixelBufferGetBaseAddress(pixelBuffer)!
        
        // Use the bytes per row value from the pixel buffer since its stride may be rounded up to be 16-byte aligned
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let region = MTLRegionMake2D(0, 0, texture.width, texture.height)
                
        texture.getBytes(pixelBufferBytes, bytesPerRow: bytesPerRow, from: region, mipmapLevel: mipmapLevel)
        
        let frameTime = CACurrentMediaTime() - recordingStartTime
        let presentationTime = CMTimeMakeWithSeconds(frameTime, preferredTimescale:   240)
        assetWriterPixelBufferInput.append(pixelBuffer, withPresentationTime: presentationTime)
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
        
        // You need to release memory allocated to pixelBuffer
        //CVPixelBufferRelease(pixelBuffer)
    }
}
