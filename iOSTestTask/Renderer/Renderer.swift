//
//  Renderer.swift
//  iOSTestTask
//
//  Created by Viacheslav Khakhulin on 13.02.2023.
//

// Our platform independent renderer class

import Metal
import MetalKit
import simd

enum ProjectionMatrixMode {
    case ndc
    case unitWidthOrtho
    case perspective
}

final class Renderer: NSObject, MTKViewDelegate {
    let device: MTLDevice
    
    let vertexDescriptor: MTLVertexDescriptor
    
    private let commandQueue: MTLCommandQueue
    private var pipelineState: MTLRenderPipelineState
    private var depthState: MTLDepthStencilState
    
    private static let maxBuffersInFlight = 3
    private let inFlightSemaphore = DispatchSemaphore(value: maxBuffersInFlight)
    
    private(set) var drawableSize = CGSize(width: 0, height: 0)
    
    private var projectionMatrix: matrix_float4x4 = Matrix.identity()
    var projectionMatrixMode = ProjectionMatrixMode.unitWidthOrtho

    var viewMatrix = Matrix.identity()

    var entities = [Transformable & Visible & Drawable]()
    
    var willDraw: (()->Void)?
    var didDraw: ((MTLTexture)->Void)?
        
    init?(metalKitView: MTKView) {
        self.device = metalKitView.device!
        guard let queue = self.device.makeCommandQueue() else {
            return nil
        }
        self.commandQueue = queue
                        
        metalKitView.depthStencilPixelFormat = MTLPixelFormat.depth32Float_stencil8
        metalKitView.colorPixelFormat = MTLPixelFormat.bgra8Unorm
        metalKitView.sampleCount = 1
        
        vertexDescriptor = Renderer.buildVertexDescriptor()
        
        do {
            pipelineState = try Renderer.buildRenderPipelineWithDevice(device: device,
                                                                       metalKitView: metalKitView,
                                                                       mtlVertexDescriptor: vertexDescriptor)
        } catch {
            print("[Renderer] Unable to compile render pipeline state.  Error info: \(error)")
            return nil
        }
        
        let depthStateDescriptor = MTLDepthStencilDescriptor()
        depthStateDescriptor.depthCompareFunction = MTLCompareFunction.less
        depthStateDescriptor.isDepthWriteEnabled = true
        guard let state = device.makeDepthStencilState(descriptor:depthStateDescriptor) else {
            return nil            
        }
        depthState = state
                
        super.init()        
    }
    
    class func buildVertexDescriptor() -> MTLVertexDescriptor {
        // Create a Metal vertex descriptor specifying how vertices will by laid out for input into our render
        //   pipeline and how we'll layout our Model IO vertices
        
        let mtlVertexDescriptor = MTLVertexDescriptor()
        
        mtlVertexDescriptor.attributes[VertexAttribute.position.rawValue].format = MTLVertexFormat.float3
        mtlVertexDescriptor.attributes[VertexAttribute.position.rawValue].offset = 0
        mtlVertexDescriptor.attributes[VertexAttribute.position.rawValue].bufferIndex = BufferIndex.meshPositions.rawValue
        
        mtlVertexDescriptor.attributes[VertexAttribute.texcoord.rawValue].format = MTLVertexFormat.float2
        mtlVertexDescriptor.attributes[VertexAttribute.texcoord.rawValue].offset = 0
        mtlVertexDescriptor.attributes[VertexAttribute.texcoord.rawValue].bufferIndex = BufferIndex.meshGenerics.rawValue
        
        mtlVertexDescriptor.layouts[BufferIndex.meshPositions.rawValue].stride = 12
        mtlVertexDescriptor.layouts[BufferIndex.meshPositions.rawValue].stepRate = 1
        mtlVertexDescriptor.layouts[BufferIndex.meshPositions.rawValue].stepFunction = MTLVertexStepFunction.perVertex
        
        mtlVertexDescriptor.layouts[BufferIndex.meshGenerics.rawValue].stride = 8
        mtlVertexDescriptor.layouts[BufferIndex.meshGenerics.rawValue].stepRate = 1
        mtlVertexDescriptor.layouts[BufferIndex.meshGenerics.rawValue].stepFunction = MTLVertexStepFunction.perVertex
        
        return mtlVertexDescriptor
    }
    
    class func buildRenderPipelineWithDevice(device: MTLDevice,
                                             metalKitView: MTKView,
                                             mtlVertexDescriptor: MTLVertexDescriptor) throws -> MTLRenderPipelineState {
        let library = device.makeDefaultLibrary()
        
        let vertexFunction = library?.makeFunction(name: "vertexShader")
        let fragmentFunction = library?.makeFunction(name: "fragmentShader")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.label = "RenderPipeline"
        pipelineDescriptor.rasterSampleCount = metalKitView.sampleCount
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.vertexDescriptor = mtlVertexDescriptor
        
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalKitView.colorPixelFormat
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add;
        pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add;
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha;
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha;
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha;
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha;
        pipelineDescriptor.depthAttachmentPixelFormat = metalKitView.depthStencilPixelFormat
        pipelineDescriptor.stencilAttachmentPixelFormat = metalKitView.depthStencilPixelFormat
        
        return try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
                    
    func draw(in view: MTKView) {
        _ = inFlightSemaphore.wait(timeout: DispatchTime.distantFuture)
        
        willDraw?()
        
        if let commandBuffer = commandQueue.makeCommandBuffer() {
            let semaphore = inFlightSemaphore
            commandBuffer.addCompletedHandler { (_ commandBuffer)-> Swift.Void in
                semaphore.signal()
            }
            
            let renderPassDescriptor = view.currentRenderPassDescriptor
            if let renderPassDescriptor = renderPassDescriptor, let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
                renderEncoder.label = "Primary Render Encoder"
                renderEncoder.pushDebugGroup("Draw Entities")
                renderEncoder.setCullMode(.none)
                renderEncoder.setFrontFacing(.counterClockwise)
                renderEncoder.setRenderPipelineState(pipelineState)
                renderEncoder.setDepthStencilState(depthState)
                
                for entity in entities {
                    guard entity.isVisible else {
                        continue
                    }
                    
                    let transform = entity.transform
                    let translation = Matrix.translation(transform.position.x, transform.position.y, transform.position.z)
                    let rotation = Matrix.rotation(pitch: transform.rotation.x, yaw: transform.rotation.y, roll: transform.rotation.z)
                    let scaling = Matrix.scaling(transform.scale.x, transform.scale.y, transform.scale.z)
                    let modelMatrix = simd_mul(simd_mul(translation, rotation), scaling)
                    let modelViewMatrix = simd_mul(viewMatrix, modelMatrix)
                    
                    var uniforms = Uniforms(projectionMatrix: projectionMatrix,
                                            modelViewMatrix: modelViewMatrix)
                    renderEncoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.size, index: BufferIndex.uniforms.rawValue)
                    renderEncoder.setFragmentBytes(&uniforms, length: MemoryLayout<Uniforms>.size, index: BufferIndex.uniforms.rawValue)
                    
                    entity.draw(renderCommandEncoder: renderEncoder)
                }
                
                renderEncoder.popDebugGroup()
                
                renderEncoder.endEncoding()
                                
                if let drawable = view.currentDrawable {
                    commandBuffer.present(drawable)
                    didDraw?(drawable.texture)
                }
            }
            
            commandBuffer.commit()
        }
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        drawableSize = size
        
        switch projectionMatrixMode {
        case .ndc:
            projectionMatrix = Matrix.identity()
        case .unitWidthOrtho:
            projectionMatrix = Matrix.unitWidthOrtho(width: Float(size.width), height: Float(size.height))
        case .perspective:
            let aspect = Float(size.width) / Float(size.height)
            projectionMatrix = Matrix.perspective(fovyRadians: Angles.radiansFrom(degrees: 65),
                                                  aspectRatio:aspect,
                                                  nearZ: 0.1, farZ: 100.0)
        }
    }
}
