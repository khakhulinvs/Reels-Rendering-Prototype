//
//  RenderPresenter.swift
//  iOSTestTask
//
//  Created by Viacheslav Khakhulin on 15.02.2023.
//

import UIKit

class RenderPresenter: RenderPresenterProtocol {
    private weak var view: RenderViewProtocol!
    
    private var renderer: Renderer
    private var scene: Scene
    private var videoWriter: VideoWriter?
    private var photoProcessor = PhotoProcessor()
    private(set) var renderSize = CGSize(width: 640, height: 480)
    
    init?(view: RenderViewProtocol) {
        self.view = view
        let mtkView = self.view.mtkView
        
        // Setup renderer
        guard let renderer = Renderer(metalKitView: mtkView) else {
            print("[RenderPresenter] Renderer cannot be initialized")
            return nil
        }
        self.renderer = renderer
        renderer.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)
        mtkView.delegate = renderer
        
        // Setup scene
        guard let scene = Scene(renderer: renderer) else {
            return nil
        }
        self.scene = scene

        renderer.didDraw = { [weak self] texture in
            if self?.videoWriter?.isRecording == true {
                self?.videoWriter?.writeFrame(forTexture: texture)
            }
            
            if !scene.isRealTime {
                if scene.fixedTime >= scene.maxTime {
                    self?.finishRenderingVideo()
                    return
                }
                
                self?.scene.stepTime()
                self?.view.setMtkViewNeedDisplay()
            }
        }
        
        // Setup template

        let imageNames = [
            "Photo0.jpeg",
            "Photo1.jpeg",
            "Photo2.jpeg",
            "Photo3.jpeg",
            "Photo4.jpeg",
            "Photo5.jpeg",
            "Photo6.jpeg",
            "Photo7.jpeg",
        ]
        let images = imageNames.compactMap({ UIImage(named: $0) })
        
        guard let firstImage = images.first else {
            print("[RenderPresenter] No images")
            return
        }
                
        renderSize = CGSize(width: firstImage.size.width * firstImage.scale,
                            height: firstImage.size.height * firstImage.scale)
        
        photoProcessor.process(uiImages: images) { photos in
            scene.addMaskedTemplate(photos: photos)
        }        
    }
    
    // MARK: - Time management
    
    private func setFixedTime() {
        view.setMtkViewFixedTime()
        scene.setFixedTime()
    }
    
    private func setRealTime() {
        view.setMtkViewRealTime()
        scene.setRealTime()
    }

    // MARK: - Video rendering
    
    private func startRenderingVideo() {
        if videoWriter?.isRecording == true {
            print("[RenderPresenter] startRenderingVideo failed: already rendering")
            return
        }
        
        guard let videoURL = FileManager.default.temporaryFileURL(fileName: "RenderVideoOnly.mov") else {
            return
        }
        FileManager.default.removeIfExists(url: videoURL)
        
        view.showActivity()
        
        print("[RenderPresenter] Switching to fixed-time")
        setFixedTime()
        
        let videoSize = view.mtkView.drawableSize
        videoWriter = VideoWriter(outputURL: videoURL, fileType: .mov, size: videoSize)
        videoWriter?.startRecording()
        print("[RenderPresenter] Video writer started")
        
        view.setMtkViewNeedDisplay()
    }
    
    private func finishRenderingVideo() {
        videoWriter?.finishRecording { [weak self] videoURL, fileType, videoSize in
            print("[RenderPresenter] Video writer finished")
            
            print("[RenderPresenter] Switching to real-time")
            self?.setRealTime()
            
            guard let videoURL = videoURL,
                  let fileType = fileType,
                  let videoSize = videoSize else {
                self?.view.hideActivity()
                // TODO: Show error in view
                print("[RenderPresenter] Failed to get parameters of written video")
                return
            }
            
            print("[RenderPresenter] Start merging audio and video")
            let audioURL = Bundle.main.url(forResource: "Music", withExtension: "aac")!
            AudioVideoMerger.merge(videoUrl: videoURL, audioUrl: audioURL,
                                   renderSize: videoSize,
                                   fileName: "Render.mov", fileType: fileType) { result in
                self?.view.hideActivity()
                
                print("[RenderPresenter] Finished merging audio and video")
                self?.view.shareVideo(url: result)
            } failure: { error in
                self?.view.hideActivity()
                
                // TODO: Show error in view
                let errorString = error?.localizedDescription ?? "Unknown error"
                print("[RenderPresenter] Failed merging audio and video: \(errorString)")
            }
        }
    }
    
    // MARK: - Events from view
    
    func renderButtonTapped() {
        startRenderingVideo()
    }
}
