//
//  MeshFactory.swift
//  iOSTestTask
//
//  Created by Viacheslav Khakhulin on 13.02.2023.
//

import MetalKit

enum MeshFactoryError: Error {
    case badVertexDescriptor
}

class MeshFactory {
    var renderer: Renderer
    
    private let mdlVertexDescriptor: MDLVertexDescriptor
    
    init(renderer: Renderer) throws {
        self.renderer = renderer
        
        mdlVertexDescriptor = MTKModelIOVertexDescriptorFromMetal(renderer.vertexDescriptor)
        
        guard let attributes = mdlVertexDescriptor.attributes as? [MDLVertexAttribute] else {
            throw MeshFactoryError.badVertexDescriptor
        }
        attributes[VertexAttribute.position.rawValue].name = MDLVertexAttributePosition
        attributes[VertexAttribute.texcoord.rawValue].name = MDLVertexAttributeTextureCoordinate
    }
    
    func create(mdlMesh: MDLMesh) throws -> Mesh {
        mdlMesh.vertexDescriptor = mdlVertexDescriptor
        
        let mtkMesh = try MTKMesh(mesh:mdlMesh, device:renderer.device)
        
        return Mesh(mtkMesh: mtkMesh)
    }
    
    func createBox(dimesions: SIMD3<Float> = SIMD3<Float>(1, 1, 1),
                   segments: SIMD3<UInt32> = SIMD3<UInt32>(1, 1, 1)) throws -> Mesh {
        let mdlMesh = MDLMesh.newBox(withDimensions: dimesions,
                                     segments: segments,
                                     geometryType: MDLGeometryType.triangles,
                                     inwardNormals:false,
                                     allocator: MTKMeshBufferAllocator(device: renderer.device))
        
        return try create(mdlMesh: mdlMesh)
    }
    
    func createXZPlane(dimesions: SIMD2<Float> = SIMD2<Float>(1, 1),
                       segments: SIMD2<UInt32> = SIMD2<UInt32>(1, 1)) throws -> Mesh {
        let mdlMesh = MDLMesh.newPlane(withDimensions: dimesions,
                                       segments: segments,
                                       geometryType: MDLGeometryType.triangles,
                                       allocator: MTKMeshBufferAllocator(device: renderer.device))
        
        return try create(mdlMesh: mdlMesh)
    }
    
    func createXYPlane(dimesions: SIMD2<Float> = SIMD2<Float>(1, 1)) throws -> Mesh {
        let allocator = MTKMeshBufferAllocator(device: renderer.device)
        
        let halfSizeX: Float = dimesions.x * 0.5
        let halfSizeY: Float = dimesions.y * 0.5
        
        let vertexCount = 4
        
        var vertexBuffers = [MDLMeshBuffer]()
        var submeshes = [MDLSubmesh]()

        // Vertices
        let vertices: [Float] = [
            -halfSizeX, -halfSizeY, 0,
             -halfSizeX, halfSizeY, 0,
             halfSizeX, halfSizeY, 0,
             halfSizeX, -halfSizeY, 0,
        ]
        vertices.withUnsafeBufferPointer { pointer in
            let data = Data(buffer: pointer)
            let buffer = allocator.newBuffer(with: data, type: MDLMeshBufferType.vertex)
            vertexBuffers.append(buffer)
        }

        // TexCoords
        let texCoords: [Float] = [
            0, 1,
            0, 0,
            1, 0,
            1, 1,
        ]
        texCoords.withUnsafeBufferPointer { pointer in
            let data = Data(buffer: pointer)
            let buffer = allocator.newBuffer(with: data, type: MDLMeshBufferType.vertex)
            vertexBuffers.append(buffer)
        }

        // Indices
        let indices: [UInt16] = [
            0, 1, 2,
            0, 2, 3
        ]
        indices.withUnsafeBufferPointer { pointer in
            let data = Data(buffer: pointer)
            let buffer = allocator.newBuffer(with: data, type: MDLMeshBufferType.index)
            let submesh = MDLSubmesh(indexBuffer: buffer, indexCount: indices.count, indexType: .uInt16, geometryType: .triangles, material: nil)
            submeshes.append(submesh)
        }

        let mdlMesh = MDLMesh(vertexBuffers: vertexBuffers,
                              vertexCount: vertexCount,
                              descriptor: mdlVertexDescriptor,
                              submeshes: submeshes)
        
        return try create(mdlMesh: mdlMesh)
    }
    
    func createNdcFullscreenPlane() throws -> Mesh {
        return try createXYPlane(dimesions: SIMD2(x: 2, y: 2))
    }
}
