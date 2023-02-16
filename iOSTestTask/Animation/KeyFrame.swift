//
//  KeyFrame.swift
//  iOSTestTask
//
//  Created by Viacheslav Khakhulin on 14.02.2023.
//

import Foundation

struct KeyFrame: Transformable, Visible {
    var transform = Transform()
    var isVisible = true
    var time: Float = 0.0
    var interpolation = Interpolation.none
}
