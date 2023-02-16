//
//  ProcessedPhoto.swift
//  iOSTestTask
//
//  Created by Viacheslav Khakhulin on 15.02.2023.
//

import UIKit
import CoreImage

class ProcessedPhoto {
    var original: UIImage?
    var masked: CIImage?
    var edges: CIImage?
    
    init(original: UIImage? = nil, masked: CIImage? = nil, edges: CIImage? = nil) {
        self.original = original
        self.masked = masked
        self.edges = edges
    }
}
