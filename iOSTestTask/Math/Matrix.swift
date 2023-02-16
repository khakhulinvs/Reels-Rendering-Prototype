//
//  matrix_float4x4+.swift
//  iOSTestTask
//
//  Created by Viacheslav Khakhulin on 13.02.2023.
//

import Foundation

final class Matrix {
    static func translation(_ x: Float, _ y: Float, _ z: Float) -> matrix_float4x4 {
        return matrix_float4x4.init(columns:(vector_float4(1, 0, 0, 0),
                                             vector_float4(0, 1, 0, 0),
                                             vector_float4(0, 0, 1, 0),
                                             vector_float4(x, y, z, 1)))
    }
    
    static func rotation(radians: Float, axis: SIMD3<Float>) -> matrix_float4x4 {
        let unitAxis = normalize(axis)
        let ct = cosf(radians)
        let st = sinf(radians)
        let ci = 1 - ct
        let x = unitAxis.x, y = unitAxis.y, z = unitAxis.z
        return matrix_float4x4.init(columns:(vector_float4(    ct + x * x * ci, y * x * ci + z * st, z * x * ci - y * st, 0),
                                             vector_float4(x * y * ci - z * st,     ct + y * y * ci, z * y * ci + x * st, 0),
                                             vector_float4(x * z * ci + y * st, y * z * ci - x * st,     ct + z * z * ci, 0),
                                             vector_float4(                  0,                   0,                   0, 1)))
    }
    
    static func rotation(pitch: Float, yaw: Float, roll: Float) -> matrix_float4x4 {
        let matPitch = rotation(radians: pitch, axis: vector_float3(1, 0, 0))
        let matYaw = rotation(radians: yaw, axis: vector_float3(0, 1, 0))
        let matRoll = rotation(radians: roll, axis: vector_float3(0, 0, 1))
        return simd_mul(simd_mul(matPitch, matYaw), matRoll)
    }

    static func scaling(_ x: Float, _ y: Float, _ z: Float) -> matrix_float4x4 {
        return matrix_float4x4.init(columns:(vector_float4(x, 0, 0, 0),
                                             vector_float4(0, y, 0, 0),
                                             vector_float4(0, 0, z, 0),
                                             vector_float4(0, 0, 0, 1)))
    }

    static func identity() -> matrix_float4x4 {
        return matrix_float4x4.init(columns:(vector_float4(1, 0, 0, 0),
                                             vector_float4(0, 1, 0, 0),
                                             vector_float4(0, 0, 1, 0),
                                             vector_float4(0, 0, 0, 1)))
    }

    static func perspective(fovyRadians fovy: Float, aspectRatio: Float, nearZ: Float, farZ: Float) -> matrix_float4x4 {
        let ys = 1 / tanf(fovy * 0.5)
        let xs = ys / aspectRatio
        let zs = farZ / (nearZ - farZ)
        return matrix_float4x4.init(columns:(vector_float4(xs,  0, 0,   0),
                                             vector_float4( 0, ys, 0,   0),
                                             vector_float4( 0,  0, zs, -1),
                                             vector_float4( 0,  0, zs * nearZ, 0)))
    }
    
    static func ortho(left: Float, right: Float, bottom: Float, top: Float) -> matrix_float4x4 {
        return matrix_float4x4.init(columns:(vector_float4(2.0 / (right - left), 0.0, 0.0, 0.0),
                                             vector_float4(0.0, 2.0 / (top - bottom), 0.0, 0.0),
                                             vector_float4(0.0, 0.0, 1, 0.0),
                                             vector_float4(-(right + left) / (right - left),
                                                            -(top + bottom) / (top - bottom),
                                                            0, 1.0)))
    }
    
    // Point (0, 0) is center of screen.
    // Point (0.5, 0) is on right edge of screen on it's center
    static func unitWidthOrtho(width: Float, height: Float) -> matrix_float4x4 {
        let aspect = height / width
        return ortho(left: -0.5, right: 0.5,
                     bottom: -aspect * 0.5, top: aspect * 0.5)
    }

    static func ortho(left: Float, right: Float, bottom: Float, top: Float, zNear: Float, zFar: Float) -> matrix_float4x4 {
        return matrix_float4x4.init(columns:(vector_float4(2.0 / (right - left), 0.0, 0.0, 0.0),
                                             vector_float4(0.0, 2.0 / (top - bottom), 0.0, 0.0),
                                             vector_float4(0.0, 0.0, -2.0 / (zFar - zNear), 0.0),
                                             vector_float4(-(right + left) / (right - left),
                                                            -(top + bottom) / (top - bottom),
                                                            -(zFar + zNear) / (zFar - zNear), 1.0)))
    }
}
