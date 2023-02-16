//
//  ApplyMask.swift
//  iOSTestTask
//
//  Created by Viacheslav Khakhulin on 15.02.2023.
//

import CoreImage

class ApplyMask : CIFilter {
    override var attributes: [String : Any]
        {
            return [
                kCIAttributeFilterDisplayName: "ApplyMask",
                
                "inputImage": [kCIAttributeIdentity: 0,
                    kCIAttributeClass: "CIImage",
                    kCIAttributeDisplayName: "Image",
                    kCIAttributeType: kCIAttributeTypeImage],

                "maskImage": [kCIAttributeIdentity: 0,
                    kCIAttributeClass: "CIImage",
                    kCIAttributeDisplayName: "Image",
                    kCIAttributeType: kCIAttributeTypeImage],
            ]
        }
    
    static let kernels = CIKernel.makeKernels(source:
        """
        kernel vec4 applyMaskKernel(sampler image, sampler mask) {
            vec2 coord = samplerCoord(image);
            vec3 rgb = sample(image, coord).rgb;
            float alpha = sample(mask, coord).r;
            return vec4(rgb, alpha);
        }
        """
    )!
    static var kernel: CIKernel {
        return kernels.first!
    }

    var inputImage: CIImage?
    var inputMask: CIImage?
    
    override var outputImage: CIImage? {
        guard let inputImage = inputImage,
              let inputMask = inputMask else {
            return nil
        }
        return ApplyMask.kernel.apply(
            extent: inputImage.extent,
            roiCallback: { _, rect in
                return rect
            },
            arguments: [inputImage, inputMask])
      }
}
