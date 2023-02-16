//
//  HSV.swift
//  Env
//
//  Created by Viacheslav Khakhulin on 25.01.2022.
//  Copyright © 2022 Hazor Games. All rights reserved.
//

import CoreImage

class RGBToHSV : CIFilter {
    override var attributes: [String : Any]
        {
            return [
                kCIAttributeFilterDisplayName: "RGBToHSV",
                
                "inputImage": [kCIAttributeIdentity: 0,
                    kCIAttributeClass: "CIImage",
                    kCIAttributeDisplayName: "Image",
                    kCIAttributeType: kCIAttributeTypeImage],
            ]
        }
    
    static let kernels = CIKernel.makeKernels(source: CIFilter.rgbToHsvSource() +
        """
        kernel vec4 rgbToHsvKernel(sampler image) {
            vec4 rgba = sample(image, samplerCoord(image));
        
            vec3 hsv = rgbToHsv(rgba.rgb);
        
            return vec4(hsv, rgba.a);
        }
        """
    )!
    static var kernel: CIKernel {
        return kernels.first!
    }

    var inputImage: CIImage?
    
    override var outputImage: CIImage? {
        guard let inputImage = inputImage else { return nil }
        return RGBToHSV.kernel.apply(
          extent: inputImage.extent,
          roiCallback: { _, rect in
            return rect
          },
          arguments: [inputImage])
      }
}
