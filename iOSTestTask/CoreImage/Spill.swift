//
//  ApplyMask.swift
//  iOSTestTask
//
//  Created by Viacheslav Khakhulin on 15.02.2023.
//

import CoreImage

class Spill : CIFilter {
    override var attributes: [String : Any]
        {
            return [
                kCIAttributeFilterDisplayName: "ApplyMask",
                
                "inputImage": [kCIAttributeIdentity: 0,
                    kCIAttributeClass: "CIImage",
                    kCIAttributeDisplayName: "Image",
                    kCIAttributeType: kCIAttributeTypeImage],
            ]
        }
    
    static let kernels = CIKernel.makeKernels(source:
        """
        kernel vec4 applyMaskKernel(sampler image, int spillDepth, float spillThreshold, float texelX, float texelY) {
            vec2 coord = samplerCoord(image);
        
            int iDepth = spillDepth;
            float fDepth = float(iDepth);
            float fDepthSqr = fDepth * fDepth;
        
            for (int x = -iDepth; x <= iDepth; x++) {
                float fx = float(x);
                float offsetX = fx * texelX;
                for (int y = -iDepth; y <= iDepth; y++) {
                    float fy = float(y);
                    float offsetY = fy * texelY;
        
                    float distSqr = fx * fx + fy * fy;
                    if (distSqr > fDepthSqr) {
                        continue;
                    }
                    
                    float color = sample(image, coord + vec2(offsetX, offsetY)).r;
                    if (color > spillThreshold) {
                        return vec4(1.0);
                    }
                }
            }
            
            return sample(image, coord);
        }
        """
    )!
    static var kernel: CIKernel {
        return kernels.first!
    }

    var inputImage: CIImage?
    var spillDepth: Int = 16
    var spillThreshold: Float = 0.1
    
    override var outputImage: CIImage? {
        guard let inputImage = inputImage else {
            return nil
        }
        return Spill.kernel.apply(
            extent: inputImage.extent,
            roiCallback: { _, rect in
                return rect
            },
            arguments: [inputImage, spillDepth, spillThreshold, 1.0 / inputImage.extent.width, 1.0 / inputImage.extent.height])
      }
}
