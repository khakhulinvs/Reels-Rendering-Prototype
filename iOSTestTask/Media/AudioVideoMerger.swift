//
//  AudioVideoMerger.swift
//  iOSTestTask
//
//  Created by Viacheslav Khakhulin on 14.02.2023.
//

import UIKit
import AVFoundation
import AVKit
import AssetsLibrary

class AudioVideoMerger {
    static func merge(videoUrl: URL,
                      audioUrl: URL,
                      renderSize: CGSize,
                      fileName: String,
                      fileType: AVFileType,
                      success: @escaping ((URL) -> Void),
                      failure: @escaping ((Error?) -> Void)) {
        
        let mixComposition: AVMutableComposition = AVMutableComposition()
        var mutableCompositionVideoTrack: [AVMutableCompositionTrack] = []
        var mutableCompositionAudioTrack: [AVMutableCompositionTrack] = []
        let totalVideoCompositionInstruction: AVMutableVideoCompositionInstruction = AVMutableVideoCompositionInstruction()
        
        let aVideoAsset: AVAsset = AVAsset(url: videoUrl)
        let aAudioAsset: AVAsset = AVAsset(url: audioUrl)
        
        if let videoTrack = mixComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid), let audioTrack = mixComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
            mutableCompositionVideoTrack.append( videoTrack )
            mutableCompositionAudioTrack.append( audioTrack )
            
            if let aVideoAssetTrack: AVAssetTrack = aVideoAsset.tracks(withMediaType: .video).first, let aAudioAssetTrack: AVAssetTrack = aAudioAsset.tracks(withMediaType: .audio).first {
                do {
                    try mutableCompositionVideoTrack.first?.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: aVideoAssetTrack.timeRange.duration), of: aVideoAssetTrack, at: CMTime.zero)
                    
                    let videoDuration = aVideoAsset.duration
                    if CMTimeCompare(videoDuration, aAudioAsset.duration) == -1 {
                        try mutableCompositionAudioTrack.first?.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: aVideoAssetTrack.timeRange.duration), of: aAudioAssetTrack, at: CMTime.zero)
                    } else if CMTimeCompare(videoDuration, aAudioAsset.duration) == 1 {
                        var currentTime = CMTime.zero
                        while true {
                            var audioDuration = aAudioAsset.duration
                            let totalDuration = CMTimeAdd(currentTime, audioDuration)
                            if CMTimeCompare(totalDuration, videoDuration) == 1 {
                                audioDuration = CMTimeSubtract(totalDuration, videoDuration)
                            }
                            try mutableCompositionAudioTrack.first?.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: aVideoAssetTrack.timeRange.duration), of: aAudioAssetTrack, at: currentTime)
                            
                            currentTime = CMTimeAdd(currentTime, audioDuration)
                            if CMTimeCompare(currentTime, videoDuration) == 1 || CMTimeCompare(currentTime, videoDuration) == 0 {
                                break
                            }
                        }
                    }
                    videoTrack.preferredTransform = aVideoAssetTrack.preferredTransform
                    
                } catch {
                    print("[AudioVideoMerger] Error: \(error)")
                }
                
                totalVideoCompositionInstruction.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: aVideoAssetTrack.timeRange.duration)
            }
        }
        
        let mutableVideoComposition: AVMutableVideoComposition = AVMutableVideoComposition()
        mutableVideoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        mutableVideoComposition.renderSize = renderSize
        
        if let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {
            let outputURL = URL(fileURLWithPath: documentsPath).appendingPathComponent(fileName)
            
            do {
                if FileManager.default.fileExists(atPath: outputURL.path) {
                    
                    try FileManager.default.removeItem(at: outputURL)
                }
            } catch { }
            
            if let exportSession = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality) {
                exportSession.outputURL = outputURL
                exportSession.outputFileType = fileType
                exportSession.shouldOptimizeForNetworkUse = true
                
                // try to export the file and handle the status cases
                exportSession.exportAsynchronously(completionHandler: {
                    switch exportSession.status {
                    case .failed:
                        if let error = exportSession.error {
                            failure(error)
                        }
                        
                    case .cancelled:
                        if let error = exportSession.error {
                            failure(error)
                        }
                        
                    default:
                        success(outputURL)
                    }
                })
            } else {
                failure(nil)
            }
        }
    }
}
