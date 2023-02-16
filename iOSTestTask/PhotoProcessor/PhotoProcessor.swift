//
//  PhotoProcessor.swift
//  iOSTestTask
//
//  Created by Viacheslav Khakhulin on 15.02.2023.
//

import UIKit

class PhotoProcessor {
    private let segmentator = CustomSegmentator()
    private(set) var canProcess = true
    private var photos = [ProcessedPhoto]()
    private var completion: (([ProcessedPhoto])->Void)?
    
    private func processPhoto(index: Int) {
        let photo = photos[index]
        
        guard let originalUIImage = photo.original,
              let originalCIImage = CIImage(image: originalUIImage) else {
            return
        }
        
        segmentator.predict(uiImage: originalUIImage, orientation: .up) { [weak self] result, resultType in
            guard resultType == .CVPixelBuffer else {
                print("[PhotoProcessor] Segmentator result is not CVPixelBuffer")
                return
            }
            let pixelBuffer = result as! CVPixelBuffer
            var mask = CIImage(cvPixelBuffer: pixelBuffer)

            // Resize mask to original image size
            if let resizedMask = mask.resized(to: originalCIImage.extent.size) {
                mask = resizedMask
            }

            // Binarize mask
            let binarize = Binarize()
            binarize.inputImage = mask
            if let filterMask = binarize.outputImage {
                mask = filterMask
            }

            // Gauss blur mask
//            if let gaussianBlurFilter = CIFilter(name: "CIGaussianBlur") {
//                gaussianBlurFilter.setValue(mask, forKey: kCIInputImageKey)
//                gaussianBlurFilter.setValue(4, forKey: kCIInputRadiusKey)
//                if let blurredMask = gaussianBlurFilter.outputImage {
//                    mask = blurredMask
//                }
//            }
            
            // CIMorphologyMinimum
//            if let maskFilter = CIFilter(name: "CIMorphologyMinimum") {
//                maskFilter.setValue(mask, forKey: kCIInputImageKey)
//                maskFilter.setValue(8, forKey: kCIInputRadiusKey)
//                if let filteredMask = maskFilter.outputImage {
//                    mask = filteredMask
//                }
//            }
            
            // Mask image
            let applyMaskFilter = ApplyMask()
            applyMaskFilter.inputImage = originalCIImage
            applyMaskFilter.inputMask = mask
            let maskedImage = applyMaskFilter.outputImage
            if maskedImage == nil {
                print("[PhotoProcessor] Failed to mask image")
            }
            photo.masked = maskedImage
            
            // Detect edges
            let edgeDetect = EdgeDetect()
            edgeDetect.inputImage = mask
            edgeDetect.threshold = 0.05
            let edges = edgeDetect.outputImage
            if edges == nil {
                print("[PhotoProcessor] Failed to detect edges image")
            }
            photo.edges = edges
            
            // Spill edges
            let spillFilter = Spill()
            spillFilter.inputImage = photo.edges
            let spillImage = spillFilter.outputImage
            if spillImage == nil {
                print("[PhotoProcessor] Failed to spill edges")
            } else {
                photo.edges = spillImage
            }

            print("[PhotoProcessor] photo processed")
            
            // Check for completion
            let photosCount = self?.photos.count ?? 0
            if index >= photosCount - 1 {
                self?.canProcess = true
                self?.completion?(self?.photos ?? [])
                return
            } else {
                self?.processPhoto(index: index + 1)
            }
        }
    }
    
    func process(uiImages: [UIImage], completion: (([ProcessedPhoto])->Void)?) {
        guard canProcess else {
            print("[PhotoProcessor] Fail to process: busy")
            return
        }
        canProcess = false
        
        photos = uiImages.map{ ProcessedPhoto(original: $0) }
        self.completion = completion
        processPhoto(index: 0)
    }
}
