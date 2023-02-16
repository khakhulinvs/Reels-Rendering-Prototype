//
//  Renderable.swift
//  iOSTestTask
//
//  Created by Viacheslav Khakhulin on 13.02.2023.
//

import Metal

protocol Drawable {
    func draw(renderCommandEncoder: MTLRenderCommandEncoder)
}
