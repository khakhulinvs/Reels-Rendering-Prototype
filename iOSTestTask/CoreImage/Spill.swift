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
        kernel vec4 applyMaskKernel(sampler image, float texelX, float texelY) {
            vec2 coord = samplerCoord(image);
        
            int iDepth = 32;
            float fDepth = float(iDepth);
            float fDepthSqr = fDepth * fDepth;
        
            for (int x = 0; x < iDepth; x++) {
                float offsetX = float(x) * texelX;
                for (int y = 0; y < iDepth; y++) {
                    float offsetY = float(y) * texelY;
        
                    float distSqr = offsetX * offsetX + offsetY * offsetY;
                    if (distSqr > fDepthSqr) {
                        continue;
                    }
                    
                    float color = sample(image, coord + vec2(offsetX, offsetY)).r;
                    if (color > 0.5) {
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
    
    override var outputImage: CIImage? {
        guard let inputImage = inputImage else {
            return nil
        }
        return Spill.kernel.apply(
            extent: inputImage.extent,
            roiCallback: { _, rect in
                return rect
            },
            arguments: [inputImage, 1.0 / inputImage.extent.width, 1.0 / inputImage.extent.height])
      }
}
