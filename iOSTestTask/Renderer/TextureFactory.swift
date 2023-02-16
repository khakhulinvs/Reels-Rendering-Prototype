//
//  TextureFactory.swift
//  iOSTestTask
//
//  Created by Viacheslav Khakhulin on 13.02.2023.
//

import MetalKit

enum TextureFactoryError: Error {
    case uiImageHaveNoCgImage
    case failedColorSpaceConvert
    case failedToCreateCgImageFromCiImage
}

final class TextureFactory {
    private let renderer: Renderer
    private let textureLoader: MTKTextureLoader
    
    init(renderer: Renderer) {
        self.renderer = renderer
        textureLoader = MTKTextureLoader(device: renderer.device)
    }
    
    func loadTexture(name: String) throws -> MTLTexture {
        let textureLoaderOptions = [
            MTKTextureLoader.Option.textureUsage: NSNumber(value: MTLTextureUsage.shaderRead.rawValue),
            MTKTextureLoader.Option.textureStorageMode: NSNumber(value: MTLStorageMode.`private`.rawValue)
        ]
        
        return try textureLoader.newTexture(name: name,
                                            scaleFactor: 1.0,
                                            bundle: nil,
                                            options: textureLoaderOptions)
    }
    
    func loadTexture(uiImage: UIImage) throws -> MTLTexture {
        guard let cgImage = uiImage.cgImage else {
            throw TextureFactoryError.uiImageHaveNoCgImage
        }
        guard let linearCGImage = cgImage.copy(colorSpace: CGColorSpaceCreateDeviceRGB()) else {
            throw TextureFactoryError.failedColorSpaceConvert
        }
        return try textureLoader.newTexture(cgImage: linearCGImage)
    }
    
    func loadTexture(ciImage: CIImage) throws -> MTLTexture {
        guard let cgImage = CGImage.create(ciImage: ciImage) else {
            throw TextureFactoryError.failedToCreateCgImageFromCiImage
        }
        guard let linearCGImage = cgImage.copy(colorSpace: CGColorSpaceCreateDeviceRGB()) else {
            throw TextureFactoryError.failedColorSpaceConvert
        }
        return try textureLoader.newTexture(cgImage: linearCGImage)
    }
}
