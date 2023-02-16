//
//  CIImage+.swift
//  iOSTestTask
//
//  Created by Viacheslav Khakhulin on 15.02.2023.
//

import CoreImage

extension CIImage {
    func resized(to size: CGSize) -> CIImage? {
        let resizeFilter = CIFilter(name:"CILanczosScaleTransform")!

        // Compute scale and corrective aspect ratio
        let scale = size.height / extent.height
        let aspectRatio = size.width / (extent.width * scale)

        // Apply resizing
        resizeFilter.setValue(self, forKey: kCIInputImageKey)
        resizeFilter.setValue(scale, forKey: kCIInputScaleKey)
        resizeFilter.setValue(aspectRatio, forKey: kCIInputAspectRatioKey)
        let outputImage = resizeFilter.outputImage
        
        return outputImage
    }
}
