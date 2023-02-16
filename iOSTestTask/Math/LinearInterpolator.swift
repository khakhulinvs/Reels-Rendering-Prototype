//
//  LinearInterpolator.swift
//  iOSTestTask
//
//  Created by Viacheslav Khakhulin on 14.02.2023.
//

import Foundation

class LinearInterpolator {
    static func interpolate(start: Float, end: Float, factor: Float) -> Float {
        return start + (end - start) * factor
    }
    
    static func interpolate(start: vector_float3, end: vector_float3, factor: Float) -> vector_float3 {
        return vector_float3(interpolate(start: start.x, end: end.x, factor: factor),
                             interpolate(start: start.y, end: end.y, factor: factor),
                             interpolate(start: start.z, end: end.z, factor: factor))
    }
    
    // TODO: Interpolate for quaternion
}
