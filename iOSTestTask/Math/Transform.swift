//
//  Transform.swift
//  iOSTestTask
//
//  Created by Viacheslav Khakhulin on 13.02.2023.
//

import Foundation

struct Transform {
    var position = vector_float3()
    var rotation = vector_float3() // TODO: Quaternion
    var scale = vector_float3(1, 1, 1)
}
