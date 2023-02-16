//
//  Animation.swift
//  iOSTestTask
//
//  Created by Viacheslav Khakhulin on 14.02.2023.
//

import Foundation

class Animation {
    private(set) var keyFrames = [KeyFrame]()
    private(set) var length: Float = 0
    
    var target: (Transformable & Visible)? = nil
    
    init(target: (Transformable & Visible)?) {
        self.target = target
    }
    
    func add(keyFrame: KeyFrame) {
        keyFrames.append(keyFrame)
        keyFrames.sort { keyFrame0, keyFrame1 in
            keyFrame0.time < keyFrame1.time
        }
        length = max(length, keyFrame.time)
    }
    
    func animate(time: Float) {
        guard let curKeyFrameIndex = keyFrames.lastIndex(where: { $0.time < time }) else {
            return
        }
        let curKeyFrame = keyFrames[curKeyFrameIndex]
        
        switch curKeyFrame.interpolation {
        case .none:
            target?.transform = curKeyFrame.transform
            target?.isVisible = curKeyFrame.isVisible
        case .linear:
            let nextKeyFrameIndex = curKeyFrameIndex + 1
            if nextKeyFrameIndex >= keyFrames.count {
                target?.transform = curKeyFrame.transform
                target?.isVisible = curKeyFrame.isVisible
            } else {
                let nextKeyFrame = keyFrames[nextKeyFrameIndex]
                
                // Compute interpolation factor
                let timeElapsed = time - curKeyFrame.time
                let timeDist = nextKeyFrame.time - curKeyFrame.time
                let factor = timeDist > 0 ? timeElapsed / timeDist : 0
                
                // Interpolate position
                let curPosition = curKeyFrame.transform.position
                let nextPosition = nextKeyFrame.transform.position
                let position = LinearInterpolator.interpolate(start: curPosition, end: nextPosition, factor: factor)
                
                // Interpolate position
                let curRotation = curKeyFrame.transform.rotation
                let nextRotation = nextKeyFrame.transform.rotation
                let rotation = LinearInterpolator.interpolate(start: curRotation, end: nextRotation, factor: factor)

                // Interpolate scale
                let curScale = curKeyFrame.transform.scale
                let nextScale = nextKeyFrame.transform.scale
                let scale = LinearInterpolator.interpolate(start: curScale, end: nextScale, factor: factor)

                // Set values to target
                target?.transform.position = position
                target?.transform.rotation = rotation
                target?.transform.scale = scale
                target?.isVisible = curKeyFrame.isVisible
            }
        }
    }
}
