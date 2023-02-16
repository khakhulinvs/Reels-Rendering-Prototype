//
//  Scene.swift
//  iOSTestTask
//
//  Created by Viacheslav Khakhulin on 13.02.2023.
//

import UIKit

class Scene {
    private(set) var renderer: Renderer
    private(set) var textureFactory: TextureFactory
    private(set) var meshFactory: MeshFactory
    private(set) var animationSystem = AnimationSystem()
    
    private(set) var isRealTime = true
    var fps: Float = 25
    private(set) var fixedTime: Float = 0
    
    var maxTime: Float {
        return animationSystem.maxLengthAnimation()?.length ?? 0
    }
    
    private func timeForAnimation() -> Float {
        guard isRealTime else {
            return fixedTime
        }
        return Float(Date().timeIntervalSince1970.truncatingRemainder(dividingBy: Double(maxTime)))
    }
    
    func setFixedTime() {
        fixedTime = 0
        isRealTime = false
    }
    
    func setRealTime() {
        isRealTime = true
    }
    
    func stepTime() {
        if isRealTime {
            print("[Scene] Warning! Scene is in real-time")
        }
        fixedTime += 1.0 / fps
    }
    
    init?(renderer: Renderer) {
        self.renderer = renderer
        textureFactory = TextureFactory(renderer: renderer)
        guard let meshFactory = try? MeshFactory(renderer: renderer) else {
            return nil
        }
        self.meshFactory = meshFactory
        
        self.renderer.willDraw = { [weak self] in
            self?.animationSystem.animate(time: self?.timeForAnimation() ?? 0)
        }
    }
    
    private func addSimpleMesh(positionZ: Float, aspect: Float,
                               timeOffset: Float, length: Float = 1,
                               upscale: Bool = false,
                               rotate: Bool = false) -> Mesh? {
        guard let mesh = try? meshFactory.createXYPlane(dimesions: SIMD2<Float>(x: 1, y: aspect)) else {
            return nil
        }
        
        let scale: Float = upscale ? 1.1 : 1
        let angle: Float = rotate ? 0.1 : 0
                
        let animation = animationSystem.createAnimation(target: mesh)
        animation.add(keyFrame: KeyFrame(transform: Transform(position: vector_float3(0, 0, positionZ)),
                                         isVisible: false,
                                         time: 0))
        animation.add(keyFrame: KeyFrame(transform: Transform(position: vector_float3(0, 0, positionZ)),
                                         isVisible: true,
                                         time: timeOffset,
                                         interpolation: .linear))
        animation.add(keyFrame: KeyFrame(transform: Transform(position: vector_float3(0, 0, positionZ),
                                                             rotation: vector_float3(0, 0, angle),
                                                              scale: vector_float3(scale, scale, scale)),
                                         isVisible: false,
                                         time: timeOffset + length))
        
        renderer.entities.append(mesh)
        
        return mesh
    }

    private func addSimpleMesh(positionZ: Float, ciImage: CIImage,
                               timeOffset: Float, length: Float = 1,
                               upscale: Bool = false,
                               rotate: Bool = false) {
        let aspect = Float(ciImage.extent.height / ciImage.extent.width)
        guard let mesh = addSimpleMesh(positionZ: positionZ, aspect: aspect,
                                       timeOffset: timeOffset, length: length,
                                       upscale: upscale,
                                       rotate: rotate) else {
            return
        }
        mesh.colorMap = try? textureFactory.loadTexture(ciImage: ciImage)
    }

    private func addSimpleMesh(positionZ: Float, uiImage: UIImage,
                               timeOffset: Float, length: Float = 1,
                               upscale: Bool = false,
                               rotate: Bool = false) {
        let aspect = Float(uiImage.size.height / uiImage.size.width)
        guard let mesh = addSimpleMesh(positionZ: positionZ, aspect: aspect,
                                       timeOffset: timeOffset, length: length,
                                       upscale: upscale,
                                       rotate: rotate) else {
            return
        }
        mesh.colorMap = try? textureFactory.loadTexture(uiImage: uiImage)
    }

    func addSimpleTemplate(ciImages: [CIImage]) {
        for index in 0..<ciImages.count {
            addSimpleMesh(positionZ: 0, ciImage: ciImages[index], timeOffset: Float(index))
        }
    }
    
    func addMaskedTemplate(photos: [ProcessedPhoto]) {
        guard photos.count > 0 else {
            print("[Scene] Failed addMaskedTemplate: no photos")
            return
        }
        
        guard let firstImage = photos[0].original else {
            print("[Scene] Failed addMaskedTemplate: missing first photo")
            return
        }
        addSimpleMesh(positionZ: 0.2, uiImage: firstImage, timeOffset: 0, length: 2)
        for index in 1..<photos.count {
            if let original = photos[index].original {
                addSimpleMesh(positionZ: 0.2, uiImage: original,
                              timeOffset: Float(index) * 2, length: 2,
                              upscale: index % 2 == 0)
            }

            if let edges = photos[index].edges {
                addSimpleMesh(positionZ: 0.15, ciImage: edges,
                              timeOffset: Float(index) * 2 - 1,
                              upscale: true)
            }

            if let masked = photos[index].masked {
                addSimpleMesh(positionZ: 0.1, ciImage: masked,
                              timeOffset: Float(index) * 2 - 1,
                              rotate: index % 2 == 1)
            }
        }
    }
}
