//
//  Renderer.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 7/2/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import MetalKit

class Renderer: NSObject, MTKViewDelegate {

	var imageRatio: Float = 16 / 9

	var squareMesh: Mesh!
	
	var exp: Float = 0

	var screenRatio: Float = 0
    var isComputingPass: Bool = false
	
	var rayMarcher = RayMarcher()

	//var camera = Camera(position: SIMD4<Float>(0, 0, -1, 0), deriction: SIMD4<Float>(0, 0, 0, 0), zoom: 1 / 2000, cameraDepth: 1, rotateMatrix: matrix_identity_float4x4, resolution: SIMD2<Float>(1920, 1080))

	override init() {
		super.init()
		self.updateMesh()
	}

	var time: Float = 0

	func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
		screenRatio = Float(size.width / size.height)
	}

	func draw(in view: MTKView) {
		
		

		let commandBuffer = Engine.CommandQueue.makeCommandBuffer()


		//post compute commands
		/*let computeCommandEncoder = commandBuffer?.makeComputeCommandEncoder()
		computeCommandEncoder?.setComputePipelineState(Engine.ComputePipelineState)
		computeCommandEncoder?.setTexture(self.defaultTexture.texture, index: 0)
		computeCommandEncoder?.setTexture(self.defaultTexture.texture, index: 1)*/

		//print(Engine.SceneCamera.rotateMatrix)

		var update = false
		
		var speed: Float = 0.01
		
		if Engine.Settings.renderMode == .Mandelbulb {
			speed = simd_clamp(rayMarcher.DE(pos: Engine.Settings.camera.position.xyz) / 4, 0, 0.01)
		}

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
			offset = offset * Engine.Settings.camera.rotateMatrix
			Engine.Settings.camera.position += offset
		}

		//post draw commands

		guard let drawable = view.currentDrawable,
			let renderPassDescriptor = view.currentRenderPassDescriptor
			else { print("could not get things"); return }

		let renderCommandEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
		switch Engine.Settings.window {
		case .preview:
			renderCommandEncoder?.setRenderPipelineState(Engine.PreviewPipelineState)
		case .rendering:
			renderCommandEncoder?.setRenderPipelineState(Engine.RenderPipelineState)
        default:
            renderCommandEncoder?.setRenderPipelineState(Engine.RenderPipelineState)
		}
		renderCommandEncoder?.setVertexBuffer(squareMesh.vertexBuffer, offset: 0, index: 0)
		renderCommandEncoder?.setVertexBytes(&screenRatio, length: Float.stride, index: 1)
		renderCommandEncoder?.setVertexBytes(&imageRatio, length: Float.stride, index: 2)
		renderCommandEncoder?.setFragmentSamplerState(Engine.SamplerState, index: 0)
		renderCommandEncoder?.setFragmentTexture(Engine.MainTexture.texture, index: 0)
		
		var info = ShaderInfo.init()
		info.camera = Engine.Settings.camera
		info.voxelsLength = UInt32(Engine.Container.voxelCount)
		info.isJulia = Engine.Settings.renderMode.rawValue
		info.lightsLength = UInt32(Engine.Settings.skyBox.count)
		info.exposure = UInt32(Engine.Settings.exposure)
		info.rayMarchingSettings = Engine.Settings.rayMarchingSettings
		info.channelsLength = UInt32(Engine.Settings.channels.count)

		renderCommandEncoder?.setFragmentBytes(&info, length: MemoryLayout<ShaderInfo>.stride, index: 0)
		renderCommandEncoder?.setFragmentBuffer(Engine.Container.voxelBuffer, offset: 0, index: 1)
		renderCommandEncoder?.setFragmentBytes(&Engine.Settings.skyBox, length: MemoryLayout<LightInfo>.stride * Engine.Settings.skyBox.count, index: 2)
		renderCommandEncoder?.setFragmentBytes(&Engine.Settings.channels, length: MemoryLayout<ChannelInfo>.stride * Engine.Settings.channels.count, index: 3)
		
		renderCommandEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: squareMesh.vertices.count)

		renderCommandEncoder?.endEncoding()
		commandBuffer?.present(drawable)
		commandBuffer?.commit()
		commandBuffer?.waitUntilCompleted()

       

		
        Engine.RenderPass()

		//Loading Pattern
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
		])
	}
}

class Mesh {
	var vertices: [Vertex] = []
	var vertexBuffer: MTLBuffer!

	init() {
		updateBuffer()
	}

	init(vertices newVertices: [Vertex]) {
		self.vertices = newVertices
		updateBuffer()
	}

	func updateBuffer() {
		vertexBuffer = Engine.Device.makeBuffer(bytes: vertices, length: Vertex.stride * vertices.count, options: [])
	}
}

class Texture {
	var texture: MTLTexture!
	
	var currentChannelCount: UInt32 = 1

	private var _textureName: String!
	private var _textureExtension: String!
	private var _origin: MTKTextureLoader.Origin!

	init(_ textureName: String, ext: String = "png", origin: MTKTextureLoader.Origin = .bottomLeft) {
		self._textureName = textureName
		self._textureExtension = ext
		self._origin = origin
		self.texture = loadTextureFromBundle(size: 1)
	}

	private func oldLoadTextureFromBundle() -> MTLTexture {
		var result: MTLTexture!
		if let url = Bundle.main.url(forResource: _textureName, withExtension: _textureExtension) {
			let textureLoader = MTKTextureLoader.init(device: Engine.Device)

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
		textureDescriptor.pixelFormat = Engine.PixelFormat.1
		textureDescriptor.width = 1920
		textureDescriptor.height = 1080
		textureDescriptor.usage = .init([MTLTextureUsage.shaderRead, MTLTextureUsage.shaderWrite])
		return Engine.Device.makeTexture(descriptor: textureDescriptor)
	}
	
	func updateTexture() {
		if currentChannelCount != Engine.Settings.channels.count {
			texture = loadTextureFromBundle(size: UInt32(Engine.Settings.channels.count))
		}
	}
}

public enum TextureOrigin {
	case TopLeft
}
