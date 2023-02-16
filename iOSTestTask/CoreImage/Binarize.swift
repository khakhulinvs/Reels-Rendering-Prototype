//
//  Binarize.swift
//  iOSTestTask
//
//  Created by Viacheslav Khakhulin on 15.02.2023.
//

import CoreImage

class Binarize : CIFilter {
    override var attributes: [String : Any]
        {
            return [
                kCIAttributeFilterDisplayName: "Binarize",
                
                "inputImage": [kCIAttributeIdentity: 0,
                    kCIAttributeClass: "CIImage",
                    kCIAttributeDisplayName: "Image",
                    kCIAttributeType: kCIAttributeTypeImage],
            ]
        }
    
    static let kernels = CIKernel.makeKernels(source:
        """
        kernel vec4 binarizeKernel(sampler image) {
            vec4 rgba = sample(image, samplerCoord(image));
            return vec4(float(rgba.r > 0.5));
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
        return Binarize.kernel.apply(
            extent: inputImage.extent,
            roiCallback: { _, rect in
                return rect
            },
            arguments: [inputImage])
      }
}
