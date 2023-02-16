//
//  Mesh.swift
//  iOSTestTask
//
//  Created by Viacheslav Khakhulin on 13.02.2023.
//

import MetalKit

final class Mesh: Drawable, Transformable, Visible {
    var isVisible = true
    var transform = Transform()
    var colorMap: MTLTexture?

    private var mtkMesh: MTKMesh
    
    init(mtkMesh: MTKMesh) {
        self.mtkMesh = mtkMesh
    }
        
    func draw(renderCommandEncoder: MTLRenderCommandEncoder) {
        for (index, element) in mtkMesh.vertexDescriptor.layouts.enumerated() {
            guard let layout = element as? MDLVertexBufferLayout else {
                return
            }
            
            if layout.stride != 0 {
                let buffer = mtkMesh.vertexBuffers[index]
                renderCommandEncoder.setVertexBuffer(buffer.buffer, offset:buffer.offset, index: index)
            }
        }
        
        renderCommandEncoder.setFragmentTexture(colorMap, index: TextureIndex.color.rawValue)
        
        for submesh in mtkMesh.submeshes {
            renderCommandEncoder.drawIndexedPrimitives(type: submesh.primitiveType,
                                                indexCount: submesh.indexCount,
                                                indexType: submesh.indexType,
                                                indexBuffer: submesh.indexBuffer.buffer,
                                                indexBufferOffset: submesh.indexBuffer.offset)
            
        }
    }
}
