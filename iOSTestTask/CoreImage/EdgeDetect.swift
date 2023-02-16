//
//  EdgeDetect.swift
//  Env
//
//  Created by Viacheslav Khakhulin on 25.01.2022.
//  Copyright © 2022 Hazor Games. All rights reserved.
//

import Foundation
import CoreImage

class EdgeDetect : CIFilter {
    override var attributes: [String : Any]
        {
            return [
                kCIAttributeFilterDisplayName: "Edge Detect",
                
                "inputImage": [kCIAttributeIdentity: 0,
                    kCIAttributeClass: "CIImage",
                    kCIAttributeDisplayName: "Image",
                    kCIAttributeType: kCIAttributeTypeImage],
                
                "inputMin": [kCIAttributeIdentity: 0,
                    kCIAttributeClass: "NSNumber",
                    kCIAttributeDescription: "Min",
                    kCIAttributeDefault: 0.0,
                    kCIAttributeDisplayName: "Min",
                    kCIAttributeMin: 0,
                    kCIAttributeSliderMin: 0,
                    kCIAttributeSliderMax: 10,
                    kCIAttributeType: kCIAttributeTypeScalar],

                "inputMax": [kCIAttributeIdentity: 0,
                    kCIAttributeClass: "NSNumber",
                    kCIAttributeDescription: "Max",
                    kCIAttributeDefault: 1.0,
                    kCIAttributeDisplayName: "Max",
                    kCIAttributeMin: 0,
                    kCIAttributeSliderMin: 0,
                    kCIAttributeSliderMax: 10,
                    kCIAttributeType: kCIAttributeTypeScalar],
            ]
        }
    
    private static func sampleSource(toGrayScale: Bool) -> String {
        var source = "float edgeDetectSample(sampler image, vec2 coord) {"
        if toGrayScale {
            source +=
            """
                vec3 rgb = sample(image, coord).rgb;
                float grayScale = (rgb.r + rgb.g + rgb.b) / 3.0;
                return grayScale;
            """
        } else {
            source += "return sample(image, coord).r;"
        }
        source += "}"
        return source
    }
    
    private static func source(toGrayScale: Bool, computeDiagonals: Bool) -> String {
        var source = sampleSource(toGrayScale: toGrayScale)
        source +=
        """
        kernel vec4 edgeDetect(sampler image, float texelSizeX, float texelSizeY, float threshold) {
            vec2 centerCoord = samplerCoord(image);

            vec2 offsetXCoord = vec2(texelSizeX, 0.0);
            float colorXMin = edgeDetectSample(image, centerCoord - offsetXCoord);
            float colorXMax = edgeDetectSample(image, centerCoord + offsetXCoord);
            float gradX = float(abs(colorXMax - colorXMin) > threshold);

            vec2 offsetYCoord = vec2(0.0, texelSizeY);
            float colorYMin = edgeDetectSample(image, centerCoord - offsetYCoord);
            float colorYMax = edgeDetectSample(image, centerCoord + offsetYCoord);
            float gradY = float(abs(colorYMax - colorYMin) > threshold);
        """
        
        if computeDiagonals {
            source +=
            """
            vec2 offsetXYCoord = vec2(texelSizeX, texelSizeY);
            float colorXYMin = edgeDetectSample(image, centerCoord - offsetXYCoord);
            float colorXYMax = edgeDetectSample(image, centerCoord + offsetXYCoord);
            float gradXY = float(abs(colorXYMax - colorXYMin) > threshold);

            vec2 offsetYXCoord = vec2(texelSizeX, -texelSizeY);
            float colorYXMin = edgeDetectSample(image, centerCoord - offsetYXCoord);
            float colorYXMax = edgeDetectSample(image, centerCoord + offsetYXCoord);
            float gradYX = float(abs(colorYXMax - colorYXMin) > threshold);
            
            float grad = (gradX + gradY + gradXY + gradYX) * 0.25;
            """
        } else {
            source += "float grad = (gradX + gradY) * 0.5;"
        }
        
        source +=
        """
            return vec4(grad);
        }
        """
        return source
    }

    private static var kernels = [String: CIKernel]()
    private static func kernel(toGrayScale: Bool, computeDiagonals: Bool) -> CIKernel {
        var kernelKey = toGrayScale ? "toGrayScale" : "firstChannel"
        if computeDiagonals {
            kernelKey += "ComputeDiagonals"
        }
        
        // Reuse
        if let kernel = EdgeDetect.kernels[kernelKey] {
            return kernel
        }
        
        // Make new
        let kernel = (CIKernel.makeKernels(source:source(toGrayScale: toGrayScale, computeDiagonals: computeDiagonals))?.first)!
        EdgeDetect.kernels[kernelKey] = kernel
        return kernel
    }

    var inputImage: CIImage?
    var threshold: CGFloat = 0.01
    var toGrayScale = false
    var computeDiagonals = false

    override var outputImage: CIImage? {
        guard let inputImage = inputImage else { return nil }
        let texelSizeX = 1.0 / inputImage.extent.size.width
        let texelSizeY = 1.0 / inputImage.extent.size.height
        let kernel = EdgeDetect.kernel(toGrayScale: toGrayScale, computeDiagonals: computeDiagonals)
        return kernel.apply(
            extent: inputImage.extent,
            roiCallback: { _, rect in
                return rect
            },
            arguments: [inputImage, texelSizeX, texelSizeY, threshold])
    }
}
