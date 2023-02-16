//
//  BaseSegmentator.swift
//  iOSTestTask
//
//  Created by Viacheslav Khakhulin on 15.02.2023.
//

import CoreML
import Vision
import CoreImage
import UIKit

@available(iOS 11.0, *)
public protocol MultiArrayType: Comparable {
    static var multiArrayDataType: MLMultiArrayDataType { get }
    static func +(lhs: Self, rhs: Self) -> Self
    static func -(lhs: Self, rhs: Self) -> Self
    static func *(lhs: Self, rhs: Self) -> Self
    static func /(lhs: Self, rhs: Self) -> Self
    init(_: Int)
    var toUInt8: UInt8 { get }
}

@available(iOS 11.0, *)
extension Double: MultiArrayType {
    public static var multiArrayDataType: MLMultiArrayDataType { return .double }
    public var toUInt8: UInt8 { return UInt8(self) }
}

@available(iOS 11.0, *)
extension Float: MultiArrayType {
    public static var multiArrayDataType: MLMultiArrayDataType { return .float32 }
    public var toUInt8: UInt8 { return UInt8(self) }
}

@available(iOS 11.0, *)
extension Int32: MultiArrayType {
    public static var multiArrayDataType: MLMultiArrayDataType { return .int32 }
    public var toUInt8: UInt8 { return UInt8(self) }
}

@available(iOS 11.0, *)
class BaseSegmentator {
    // Figure out which dimensions to use for the channels, height, and width.
    var widthAxis = 0
    var heightAxis = 1
    
    var rgbToHsv = false
    
    enum SourceType: Int {
        case CMSampleBuffer
        case CVPixelBuffer
        case UIImage
        case CGImage
    }

    enum ResultType: Int {
        case none
        case MLMultiArray
        case CVPixelBuffer
    }

    private let queue = OperationQueue()
    private var request: VNCoreMLRequest?
    private var requestDate: Date?
    private var completion: ((Any?, ResultType) -> Void)?
    var canSegment: Bool = true
    var log = false
    
    init(model: MLModel?) {
        guard let model = model else {
            return
        }

        do {
            let visionModel = try VNCoreMLModel(for: model)
            request = VNCoreMLRequest(model: visionModel, completionHandler: visionRequestDidComplete)
            request?.imageCropAndScaleOption = .scaleFill
        } catch let error {
            print("[Segmentator] Error: \(error)")
            fatalError()
        }
    }
    
    func cancelAndWaitUntilAllOperationsAreFinished() {
        queue.cancelAllOperations()
        queue.waitUntilAllOperationsAreFinished()
    }
    
    private func predict(source: Any, sourceType: SourceType, orientation: CGImagePropertyOrientation, completion: @escaping (Any?, ResultType) -> Void) {
        guard canSegment else {
            completion(nil, .none)
            return
        }
        self.completion = completion
        
        guard let request = self.request else {
            assertionFailure("[BaseSegmentator] request is nil")
            return
        }
        
        var ciImage: CIImage!
        switch sourceType {
        case .CMSampleBuffer:
            if let cvPixelBuffer = CMSampleBufferGetImageBuffer(source as! CMSampleBuffer) {
                ciImage = CIImage(cvPixelBuffer: cvPixelBuffer)
            }
        case .CVPixelBuffer:
            ciImage = CIImage(cvPixelBuffer: source as! CVPixelBuffer)
        case .UIImage:
            ciImage = CIImage(image: source as! UIImage)
        case .CGImage:
            ciImage = CIImage(cgImage: source as! CGImage)
        }
        
        if rgbToHsv {
            let RGBToHSV = RGBToHSV()
            RGBToHSV.inputImage = ciImage
            ciImage = RGBToHSV.outputImage!
        }
        
        queue.addOperation {
            do {
                self.requestDate = Date()
                let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation, options: [:])
                try handler.perform([request])
            } catch {
                print("[BaseSegmentator] Error: \(error)")
            }
        }
    }
    
    func predict(cmSampleBuffer: CMSampleBuffer, orientation: CGImagePropertyOrientation, completion: @escaping (Any?, ResultType) -> Void) {
        predict(source: cmSampleBuffer, sourceType: .CMSampleBuffer, orientation: orientation, completion: completion)
    }

    func predict(cvPixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation, completion: @escaping (Any?, ResultType) -> Void) {
        predict(source: cvPixelBuffer, sourceType: .CVPixelBuffer, orientation: orientation, completion: completion)
    }
    
    func predict(cgImage: CGImage, orientation: CGImagePropertyOrientation, completion: @escaping (Any?, ResultType) -> Void) {
        predict(source: cgImage, sourceType: .CGImage, orientation: orientation, completion: completion)
    }
    
    func predict(uiImage: UIImage, orientation: CGImagePropertyOrientation, completion: @escaping (Any?, ResultType) -> Void) {
        predict(source: uiImage, sourceType: .UIImage, orientation: orientation, completion: completion)
    }

    func visionRequestDidComplete(request: VNRequest, error: Error?) {
        if log, let requestDate = requestDate {
            let didCompleteDate = Date()
            let didCompleteInterval = didCompleteDate.timeIntervalSince(requestDate)
            print("[Segmentator] Request did complete interval: \(didCompleteInterval)")
        }
                
        guard let firstResult = request.results?.first else {
            print("[Segmentator] Request results are missing")
            canSegment = true
            completion?(nil, .none)
            return
        }
        
        // Try VNCoreMLFeatureValueObservation
        if let observation = firstResult as? VNCoreMLFeatureValueObservation {
            guard let multiArray = observation.featureValue.multiArrayValue else {
                canSegment = true
                completion?(nil, .none)
                return
            }
            
            canSegment = true
            completion?(multiArray, .MLMultiArray)
            return
        }
        
        // Try VNPixelBufferObservation
        if let observation = firstResult as? VNPixelBufferObservation {
            canSegment = true
            completion?(observation.pixelBuffer, .CVPixelBuffer)
            return
        }
        
        canSegment = true
        completion?(nil, .none)
    }
    
    // MARK: - Convertions
    
    private func toRawBytes<T: MultiArrayType>(multiArray: MLMultiArray,
                                               invert: Bool,
                                               min: T,
                                               max: T) -> (bytes: [UInt8], width: Int, height: Int)? {
        if multiArray.shape.count < 2 {
            print("[BaseSegmentator] Cannot convert MLMultiArray of shape \(multiArray.shape) to image")
            return nil
        }
        
        let height = multiArray.shape[heightAxis].intValue
        let width = multiArray.shape[widthAxis].intValue
                        
        // Allocate storage for the RGBA or grayscale pixels. Set everything to
        // 255 so that alpha channel is filled in if only 3 channels.
        let count = height * width
        var pixels = [UInt8](repeating: 255, count: count)
        
        // Grab the pointer to MLMultiArray's memory.
        let ptr = UnsafeMutablePointer<Float32>(OpaquePointer(multiArray.dataPointer))
        
        // Loop through all the pixels and all the channels and copy them over.
        
        for i in 0..<height {
            for j in 0..<width {
                let index = i * width + j;
                let value = invert ? 1.0 - ptr[index] : ptr[index]
                let pixel = (value * 255).toUInt8
                pixels[index] = pixel
            }
        }
        return (pixels, width, height)
    }
    
    private func toCGImageGeneric<T: MultiArrayType>(multiArray: MLMultiArray,
                                                            invert: Bool,
                                                            min: T,
                                                            max: T) -> CGImage? {
        if let (b, w, h) = toRawBytes(multiArray: multiArray, invert: invert, min: min, max: max) {
            return CGImage.fromByteArrayGray(b, width: w, height: h)
        }
        return nil
    }
    
    func toCGImage(multiArray: MLMultiArray,
                          invert: Bool,
                          min: Double = 0,
                          max: Double = 255,
                          channel: Int? = nil,
                          axes: (Int, Int, Int)? = nil) -> CGImage? {
        switch multiArray.dataType {
        case .double:
            return toCGImageGeneric(multiArray: multiArray, invert: invert, min: min, max: max)
        case .float32:
            return toCGImageGeneric(multiArray: multiArray, invert: invert, min: Float(min), max: Float(max))
        case .int32:
            return toCGImageGeneric(multiArray: multiArray, invert: invert, min: Int32(min), max: Int32(max))
        default:
            fatalError("[Segmentator] Unsupported data type \(multiArray.dataType.rawValue)")
        }
    }
    
    func toCIImage(multiArray: MLMultiArray, invert: Bool) -> CIImage? {
        guard let (b, w, h) = toRawBytes(multiArray: multiArray, invert: invert, min: 0, max: 255) else {
            return nil
        }
        
        let data = Data(b)
        let size = CGSize(width: w, height: h)
        let colorSpace = CGColorSpaceCreateDeviceGray()
        return CIImage(bitmapData: data, bytesPerRow: w, size: size, format: .R8, colorSpace: colorSpace)
    }
    
    func toUIImage(multiArray: MLMultiArray,
                          invert: Bool,
                          min: Double = 0,
                          max: Double = 255) -> UIImage? {
        let cgImg = toCGImage(multiArray: multiArray, invert: invert, min: min, max: max)
        return cgImg.map { UIImage(cgImage: $0) }
    }
    
    func width(multiArray: MLMultiArray) -> Int {
        return multiArray.shape[widthAxis].intValue
    }
    
    func height(multiArray: MLMultiArray) -> Int {
        return multiArray.shape[heightAxis].intValue
    }

    func toFloats(multiArray: MLMultiArray, floats: UnsafeMutablePointer<Float>, floatsPerRow: Int, focus: CGPoint) {
        let height = self.width(multiArray: multiArray)
        let width = self.height(multiArray: multiArray)
        let size = width * height
        let map = UnsafeMutablePointer<Int32>.allocate(capacity: size)
        memcpy(map, multiArray.dataPointer, size * MemoryLayout<Int32>.size)

        let focusX = Int(focus.x * CGFloat(width))
        let focusY = Int(focus.y * CGFloat(height))
        let focusIndex = focusY * width + focusX
        let focusValue = map[focusIndex]

        for row in 0..<height {
            for column in 0..<width {
                let floatIndex = row * floatsPerRow + column
                let mapIndex = row * width + column
                let mapValue = map[mapIndex]
                floats[floatIndex] = mapValue == focusValue ? 1 : 0
            }
        }
        
        map.deallocate()
    }

    func toFloats(multiArray: MLMultiArray, floats: UnsafeMutablePointer<Float>, floatsPerRow: Int) {
        let height = self.width(multiArray: multiArray)
        let width = self.height(multiArray: multiArray)
        let size = width * height
        let map = UnsafeMutablePointer<Int32>.allocate(capacity: size)
        memcpy(map, multiArray.dataPointer, size * MemoryLayout<Int32>.size)

        for row in 0..<height {
            for column in 0..<width {
                let floatIndex = row * floatsPerRow + column
                let mapIndex = row * width + column
                let mapValue = map[mapIndex]
                floats[floatIndex] = mapValue > 0 ? 1 : 0
            }
        }
        
        map.deallocate()
    }
}
