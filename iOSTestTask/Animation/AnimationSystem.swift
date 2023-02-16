//
//  AnimationSystem.swift
//  iOSTestTask
//
//  Created by Viacheslav Khakhulin on 14.02.2023.
//

import Foundation

class AnimationSystem {
    private(set) var animations = [Animation]()
        
    func createAnimation(target: (Transformable & Visible)?) -> Animation {
        let animation = Animation(target: target)
        animations.append(animation)
        return animation
    }
    
    func animate(time: Float) {
        for animation in animations {
            animation.animate(time: time)
        }
    }

    func maxLengthAnimation() -> Animation? {
        animations.max { animation0, animation1 in
            animation0.length < animation1.length
        }
    }
}
