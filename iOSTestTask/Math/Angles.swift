//
//  Angles.swift
//  iOSTestTask
//
//  Created by Viacheslav Khakhulin on 13.02.2023.
//

import Foundation

final class Angles {
    static func radiansFrom(degrees: Float) -> Float {
        return (degrees / 180) * .pi
    }
}
