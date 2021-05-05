//
//  Renderer.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 7/2/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import MetalKit

//Updates the render window.
class Renderer: NSObject, MTKViewDelegate {

	var imageRatio: Float = 16 / 9

	var squareMesh: Mesh!
	
	var exp: Float = 0

	var screenRatio: Float = 0
    var isComputingPass: Bool = false
	
	var rayMarcher: RayMarcher!
	
	var document: Document!
	var graphics: Graphics { document.graphics }
	var state: ViewSate { document.viewState }
	var content: Content { document.content }
	
	var commandQueue: MTLCommandQueue!
	

	//var camera = Camera(position: SIMD4<Float>(0, 0, -1, 0), deriction: SIMD4<Float>(0, 0, 0, 0), zoom: 1 / 2000, cameraDepth: 1, rotateMatrix: matrix_identity_float4x4, resolution: SIMD2<Float>(1920, 1080))

	override init() {
		super.init()
	}
	
	convenience init(doc: Document) {
		self.init()
		document = doc
		self.updateMesh()
		self.rayMarcher = RayMarcher(document.content)
		self.commandQueue = graphics.device.makeCommandQueue()
	}

	var time: Float = 0

	func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
		screenRatio = Float(size.width / size.height)
	}

	func draw(in view: MTKView) {
		
		var commandBuffer: MTLCommandBuffer!
		if let buffer = commandQueue.makeCommandBuffer() {
			commandBuffer = buffer
		} else {
			printError("Could not create command buffer")
			return
		}
		
		//adds a compute pipeline that does the raymarching
		document.viewState.renderPassManager.renderPass(commandBuffer: commandBuffer, mode: state.viewportMode)


		//post compute commands
		/*let computeCommandEncoder = commandBuffer?.makeComputeCommandEncoder()
		computeCommandEncoder?.setComputePipelineState(Engine.ComputePipelineState)
		computeCommandEncoder?.setTexture(self.defaultTexture.texture, index: 0)
		computeCommandEncoder?.setTexture(self.defaultTexture.texture, index: 1)*/

		//print(Engine.SceneCamera.rotateMatrix)

		
		//move camera
		var update = false
		
		var speed: Float = document.viewState.cameraSpeed
		
		/*if state.renderMode == .Mandelbulb && true {
			speed = simd_clamp(rayMarcher.DE(pos: content.camera.position.xyz) / 4, 0, 0.01)
		}*/

		var offset = SIMD4<Float>(0, 0, 0, 0)

		if Keys.isPressed(char: "w") {
			offset.z += speed
			update = true
		}
		if Keys.isPressed(char: "s") {
			offset.z -= speed
			update = true
		}
		if Keys.isPressed(char: "a") {
			offset.x -= speed
			update = true
		}
		if Keys.isPressed(char: "d") {
			offset.x += speed
			update = true
		}
		if Keys.isPressed(char: "q") {
			offset.y -= speed
			update = true
		}
		if Keys.isPressed(char: "e") {
			offset.y += speed
			update = true
		}
		if update {
			offset = content.camera.transformMatrix * offset
			//print(offset)
			content.camera.position += offset
		}

		//post draw commands
		
		var pipeState: MTLRenderPipelineState?
		switch state.viewportMode {
		case .preview:
			pipeState = graphics.library[.preview]
		case .rendering:
			pipeState = graphics.library[.render]
		case .depth:
			pipeState = graphics.library[.depth]
		default:
			pipeState = graphics.library[.render]
		}
		
		if let pipeState = pipeState {
			guard let drawable = view.currentDrawable,
				  let renderPassDescriptor = view.currentRenderPassDescriptor
			else { print("could not get things"); return }
			let renderCommandEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
			renderCommandEncoder?.setRenderPipelineState(pipeState)
			
			renderCommandEncoder?.setVertexBuffer(squareMesh.vertexBuffer, offset: 0, index: 0)
			renderCommandEncoder?.setVertexBytes(&screenRatio, length: Float.stride, index: 1)
			renderCommandEncoder?.setVertexBytes(&imageRatio, length: Float.stride, index: 2)
			renderCommandEncoder?.setFragmentSamplerState(graphics.library.samplerState, index: 0)
			renderCommandEncoder?.setFragmentTexture(document.viewState.renderPassManager.result.texture, index: 0)
			
			var info = ShaderInfo.init()
			info.camera = content.camera
			info.voxelsLength = UInt32(document.container.voxelCount)
			info.isJulia = state.renderMode.rawValue
			info.lightsLength = UInt32(content.skyBox.count)
			info.exposure = UInt32(document.viewState.renderPassManager.samplesCurrent)
			info.rayMarchingSettings = content.rayMarchingSettings
			info.channelsLength = UInt32(content.channels.count)
			info.depthSettings = content.depthSettings
			info.randomSeed.x = UInt32.random(in: 0...10000)
			info.randomSeed.y = UInt32.random(in: 0...10000)
			info.randomSeed.z = UInt32.random(in: 0...10000)
			
			info.ambient = content.shadingSettings.x
			info.angleShading = content.shadingSettings.y
			
			renderCommandEncoder?.setFragmentBytes(&info, length: MemoryLayout<ShaderInfo>.stride, index: 0)
			renderCommandEncoder?.setFragmentBuffer(document.container.voxelBuffer, offset: 0, index: 1)
			renderCommandEncoder?.setFragmentBytes(&content.skyBox, length: MemoryLayout<LightInfo>.stride * content.skyBox.count, index: 2)
			renderCommandEncoder?.setFragmentBytes(&content.channels, length: MemoryLayout<ChannelInfo>.stride * content.channels.count, index: 3)
			renderCommandEncoder?.setFragmentBytes(content.materialNodeContainer.constants, length: MemoryLayout<Float>.stride * content.materialNodeContainer.constants.count, index: 4)
			renderCommandEncoder?.setFragmentBytes(content.deNodeContainer.constants, length: MemoryLayout<Float>.stride * content.deNodeContainer.constants.count, index: 5)
			
			renderCommandEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: squareMesh.vertices.count)
			
			renderCommandEncoder?.endEncoding()
			commandBuffer?.present(drawable)
			commandBuffer?.commit()
			commandBuffer?.waitUntilCompleted()
		}

		

		
	}

	func updateMesh() {
		squareMesh = Mesh.init(vertices: [
			//Vertex(position: .init(imageRatio / -1, 1, 0), color: .init(1, 0, 0, 1), texCoord: .init(0, 1)),
			Vertex(position: SIMD4<Float>(arrayLiteral: -1, 1, 0, 1), color: SIMD4<Float>(arrayLiteral: 0, 0, 0, 1), texCoord: SIMD2<Float>(arrayLiteral: 0, 1)),
			//Vertex(position: .init(imageRatio / -1, -1, 0), color: .init(0, 1, 0, 1), texCoord: .init(0, 0)),
			Vertex(position: SIMD4<Float>(arrayLiteral: -1, -1, 0, 1), color: SIMD4<Float>(arrayLiteral: 0, 0, 0, 1), texCoord: SIMD2<Float>(arrayLiteral: 0, 0)),
			//Vertex(position: .init(imageRatio / 1, -1, 0), color: .init(0, 0, 1, 1), texCoord: .init(1, 0)),
			Vertex(position: SIMD4<Float>(arrayLiteral: 1, -1, 0, 1), color: SIMD4<Float>(arrayLiteral: 0, 0, 0, 1), texCoord: SIMD2<Float>(arrayLiteral: 1, 0)),

			//Vertex(position: .init(imageRatio / 1, -1, 0), color: .init(0, 0, 1, 1), texCoord: .init(1, 0)),
			Vertex(position: SIMD4<Float>(arrayLiteral: 1, -1, 0, 1), color: SIMD4<Float>(arrayLiteral: 0, 0, 0, 0), texCoord: SIMD2<Float>(arrayLiteral: 1, 0)),
			//Vertex(position: .init(imageRatio / -1, 1, 0), color: .init(1, 0, 0, 1), texCoord: .init(0, 1)),
			Vertex(position: SIMD4<Float>(arrayLiteral: -1, 1, 0, 1), color: SIMD4<Float>(arrayLiteral: 0, 0, 0, 0), texCoord: SIMD2<Float>(arrayLiteral: 0, 1)),
			//Vertex(position: .init(imageRatio / 1, 1, 0), color: .init(0, 0, 0, 1), texCoord: .init(1, 1))
			Vertex(position: SIMD4<Float>(arrayLiteral: 1, 1, 0, 1), color: SIMD4<Float>(arrayLiteral: 0, 0, 0, 1), texCoord: SIMD2<Float>(arrayLiteral: 1, 1))
		], device: graphics.device)
	}
}

class Mesh {
	var vertices: [Vertex] = []
	var vertexBuffer: MTLBuffer!
	var device: MTLDevice

	init(device: MTLDevice) {
		self.device = device
		updateBuffer()
	}

	init(vertices newVertices: [Vertex], device: MTLDevice) {
		self.device = device
		self.vertices = newVertices
		updateBuffer()
	}

	func updateBuffer() {
		vertexBuffer = device.makeBuffer(bytes: vertices, length: Vertex.stride * vertices.count, options: [])
	}
}

class Texture {
	var texture: MTLTexture!
	
	var currentChannelCount: UInt32 = 1
	
	var document: Document

	private var _textureName: String!
	private var _textureExtension: String!
	private var _origin: MTKTextureLoader.Origin!

	init(_ textureName: String, ext: String = "png", origin: MTKTextureLoader.Origin = .bottomLeft, doc: Document) {
		self.document = doc
		self._textureName = textureName
		self._textureExtension = ext
		self._origin = origin
		self.texture = loadTextureFromBundle(size: 1)
	}

	private func oldLoadTextureFromBundle() -> MTLTexture {
		var result: MTLTexture!
		if let url = Bundle.main.url(forResource: _textureName, withExtension: _textureExtension) {
			let textureLoader = MTKTextureLoader.init(device: document.graphics.device)

			let options = [MTKTextureLoader.Option.origin : _origin]

			do {
                result = try textureLoader.newTexture(URL: url, options: options as [MTKTextureLoader.Option : Any])
				result.label = _textureName
			} catch let error as NSError {
				printError("Could not load texture : :\(error)")
			}
		} else {
			printError("Could not load texture")
		}
		return result
	}

	private func loadTextureFromBundle(size: UInt32) -> MTLTexture? {

		self.currentChannelCount = size
		
		//print(size)
		
		let textureDescriptor = MTLTextureDescriptor()
		textureDescriptor.textureType = .type2DArray
		textureDescriptor.arrayLength = Int(size) * 3
		textureDescriptor.pixelFormat = document.graphics.pixelFormat.1
		textureDescriptor.width = 1920
		textureDescriptor.height = 1080
		textureDescriptor.usage = .init([MTLTextureUsage.shaderRead, MTLTextureUsage.shaderWrite])
		return document.graphics.device.makeTexture(descriptor: textureDescriptor)
	}
	
	func updateTexture() {
		if currentChannelCount != document.content.channels.count {
			texture = loadTextureFromBundle(size: UInt32(document.content.channels.count))
		}
	}
}

public enum TextureOrigin {
	case TopLeft
}
