//
//  Engine.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 7/2/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import MetalKit

class Engine {
	public static var Device: MTLDevice!
	public static var CommandQueue: MTLCommandQueue!
	public static var ComputeQueue: MTLCommandQueue!
	public static var PreviewPipelineState: MTLRenderPipelineState!
	public static var RenderPipelineState: MTLRenderPipelineState!
	public static var ComputePipelineState: MTLComputePipelineState!
	public static var ResetComputePipelineState: MTLComputePipelineState!
	public static var SamplerState: MTLSamplerState!
	public static var PixelFormat = (MTLPixelFormat.rgba16Float, MTLPixelFormat.r32Float)
	public static var View: MTKView!
	//public static var SceneCamera: Camera {
		//return Engine.Settings.camera
	//}
	//public static var SceneCamera = Camera(position: SIMD4<Float>(0, 0, -1, 0), deriction: SIMD4<Float>(0, 0, 0, 0), zoom: 1 / 2000, cameraDepth: 1, rotateMatrix: matrix_identity_float4x4, resolution: SIMD2<Float>(1920, 1080))
	public static var Container: VoxelContainer!
	public static var MainTexture = Texture.init("yeet")
	public static var Settings = RenderSettings()
	public static var MaxThreadsPerGroup: Int!
	//public static var MainJuliaSet = JuliaSet()
	//public static var MainPointGen = linearComGen(rSlope: 1, rIntercept: 0.1, iSlope: 1, iIntercept: -0.3)
    public static var JuliaSetSettings = LinearJuliaSet.init(rSlope: 0.5, rIntercept: 0.1, iSlope: 1, iIntercept: -0.3)

	static var index: Int = 0
	//public static var obversedSettings = RenderSettings()

	private static var lastPassTime = 1.0
    private static var lastUpdate = false
    
    public static var isRendering = false

	public static func ResetRender() {
		index = 0
	}

	private static var countdown: Int = 0

	public static func ResetTexture() {
		DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 0.1) {
			//print("reset")
			let commandBuffer = ComputeQueue.makeCommandBuffer()
			let computeCommandEncoder = commandBuffer?.makeComputeCommandEncoder()
			computeCommandEncoder?.setComputePipelineState(ResetComputePipelineState)
			computeCommandEncoder?.setTexture(MainTexture.texture, index: 0)

			let threadsPerGrid = MTLSize.init(width: MainTexture.texture.width, height: MainTexture.texture.height, depth: 1)
			let maxThreadsPerThreadgroup = ComputePipelineState.maxTotalThreadsPerThreadgroup
			let groupSize = Int(floor(sqrt(Float(maxThreadsPerThreadgroup))))
			let threadsPerThreadgroup = MTLSize(width: groupSize, height: groupSize, depth: 1)

			var shaderInfo = ShaderInfo()
			shaderInfo.channelsLength = Engine.MainTexture.currentChannelCount;
			
			computeCommandEncoder?.setBytes(&shaderInfo, length: MemoryLayout<ShaderInfo>.stride, index: 0)
			
			computeCommandEncoder?.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)

			computeCommandEncoder?.endEncoding()
			commandBuffer?.commit()
		}
		ResetRender()
		Settings.exposure = 1
		Settings.samples = 0
	}

	public static func RenderPass() {
        if isRendering {
            return
        }
        if Engine.Settings.window != .rendering || Engine.Settings.samples <= Engine.Settings.exposure{
            return
        }
        DispatchQueue.global().async {
            isRendering = true
            while Engine.Settings.exposure < Engine.Settings.samples {
                if Engine.Settings.window == .preview {
                    MainTexture = Texture.init("yeet")
                    isRendering = false
                    return;
                }
                if Engine.Settings.window == .paused {
                    isRendering = false
                    return;
                }
                if Engine.Settings.exposure >= Engine.Settings.samples {
                    Engine.Settings.window = .paused
                    isRendering = false
                    return;
                }
                let groupSize = Engine.Settings.kernelSize.groupSize
                let groups = Engine.Settings.kernelSize.groups
                
                let commandBuffer = ComputeQueue.makeCommandBuffer()
                let computeCommandEncoder = commandBuffer?.makeComputeCommandEncoder(dispatchType: .concurrent)
                computeCommandEncoder?.setComputePipelineState(ComputePipelineState)
                computeCommandEncoder?.setTexture(MainTexture.texture, index: 0)
                computeCommandEncoder?.setTexture(MainTexture.texture, index: 1)

                let threadsPerThreadgroup = MTLSize(width: groupSize, height: 1, depth: 1)
                let threadsPerGrid = MTLSize.init(width: groupSize * groups, height: 1, depth: 1)

                //let containerLength = MemoryLayout<VoxelContainer>.stride + MemoryLayout<Voxel>.stride * Container.voxels.count

                /**
                x: starting index
                y: image width
                z: image height
                w: stop index
                */
                var stop = groupSize * groups + Settings.imageSize.0 * Settings.imageSize.1
                if Settings.exposure + 1 >= Settings.samples {
                    stop = Settings.imageSize.0 * Settings.imageSize.1
                }
				
				var shaderInfo = ShaderInfo()
				shaderInfo.camera = Settings.camera
				shaderInfo.realIndex = SIMD4<UInt32>.init(UInt32(index), UInt32(Settings.imageSize.0), UInt32(Settings.imageSize.1), UInt32(stop))
				shaderInfo.randomSeed = SIMD3<UInt32>.init(UInt32.random(in: 0...10000), UInt32.random(in: 0...10000), UInt32.random(in: 0...10000))
				shaderInfo.voxelsLength = UInt32(Container.voxelCount)
				shaderInfo.isJulia = Settings.renderMode.rawValue
				shaderInfo.lightsLength = UInt32(Settings.skyBox.count)
				shaderInfo.rayMarchingSettings = Settings.rayMarchingSettings
				shaderInfo.channelsLength = UInt32(Settings.channels.count)

				computeCommandEncoder?.setBytes(&shaderInfo, length: MemoryLayout<ShaderInfo>.stride, index: 0)
                computeCommandEncoder?.setBuffer(Container.voxelBuffer, offset: 0, index: 1)
				computeCommandEncoder?.setBytes(&Settings.skyBox, length: MemoryLayout<LightInfo>.stride * Settings.skyBox.count, index: 2)
                computeCommandEncoder?.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)

                computeCommandEncoder?.endEncoding()

                commandBuffer?.commit()
                let currentTime = CACurrentMediaTime()
                commandBuffer?.waitUntilCompleted()
                //print(CACurrentMediaTime() - currentTime)

                index += groupSize * groups
                while index > Settings.imageSize.0 * Settings.imageSize.1 {
                    Settings.exposure += 1
                    index -= Settings.imageSize.0 * Settings.imageSize.1
                }
                if Engine.Settings.samples == 0 {
                    Engine.Settings.progress = "0%"
                } else {
                    Engine.Settings.progress = "\(100 * Engine.Settings.exposure / Engine.Settings.samples)% (\(Engine.Settings.exposure) / \(Engine.Settings.samples))"
                }
                lastUpdate = false
            }
            isRendering = false
        }
		//print(Settings.exposure)

		//commandBuffer?.waitUntilCompleted()
	}

	public static func LoadJuliaSet(quality: Float) {
        Container.loadQuality = quality
		Engine.Settings.savedCamera = Engine.Settings.camera
		Container.load(passSize: 10000)
	}


	public static func Init(device: MTLDevice) {

		self.Device = device
		self.CommandQueue = device.makeCommandQueue()
		self.ComputeQueue = device.makeCommandQueue()

		let defaultLibrary = Device.makeDefaultLibrary()

		assert(defaultLibrary != nil, "could not get default library")

		//MARK: Render
		let vertexShader = defaultLibrary?.makeFunction(name: "basic_vertex_shader")
		//let previewFragmentShader = defaultLibrary?.makeFunction(name: "sample_fragment_shader")
        let previewFragmentShader = defaultLibrary?.makeFunction(name: "depth_fragment_shader")
		let renderFragmentShader = defaultLibrary?.makeFunction(name: "basic_fragment_shader")


		let vertexDescriptor = MTLVertexDescriptor()

		//Position
		vertexDescriptor.attributes[0].format = .float3
		vertexDescriptor.attributes[0].bufferIndex = 0
		vertexDescriptor.attributes[0].offset = 0

		//Color
		vertexDescriptor.attributes[1].format = .float4
		vertexDescriptor.attributes[1].bufferIndex = 0
		vertexDescriptor.attributes[1].offset = SIMD3<Float>.size

		//Texture Coordinate
		vertexDescriptor.attributes[2].format = .float2
		vertexDescriptor.attributes[2].bufferIndex = 0
		vertexDescriptor.attributes[2].offset = SIMD3<Float>.size + SIMD4<Float>.size

		vertexDescriptor.layouts[0].stride = Vertex.stride


		//MARK: PreviewState
		let PreviewPipelineDescriptor = MTLRenderPipelineDescriptor()

		PreviewPipelineDescriptor.colorAttachments[0].pixelFormat = PixelFormat.0
		PreviewPipelineDescriptor.vertexFunction = vertexShader
		PreviewPipelineDescriptor.fragmentFunction = previewFragmentShader
		PreviewPipelineDescriptor.vertexDescriptor = vertexDescriptor

		do {
			PreviewPipelineState = try device.makeRenderPipelineState(descriptor: PreviewPipelineDescriptor)
		} catch {
			print(error)
		}

		//MARK: RenderState
		let RenderPipelineDescriptor = MTLRenderPipelineDescriptor()

		RenderPipelineDescriptor.colorAttachments[0].pixelFormat = PixelFormat.0
		RenderPipelineDescriptor.vertexFunction = vertexShader
		RenderPipelineDescriptor.fragmentFunction = renderFragmentShader
		RenderPipelineDescriptor.vertexDescriptor = vertexDescriptor

		do {
			RenderPipelineState = try device.makeRenderPipelineState(descriptor: RenderPipelineDescriptor)
		} catch {
			print(error)
		}

		//MARK: Sampler
		let samplerDescriptor = MTLSamplerDescriptor()
		samplerDescriptor.minFilter = .linear
		samplerDescriptor.magFilter = .linear
		samplerDescriptor.label = "basic"
		SamplerState = Device.makeSamplerState(descriptor: samplerDescriptor)

		//MARK: Compute
		let computeFunction = defaultLibrary?.makeFunction(name: "ray_compute_shader")

		do {
			ComputePipelineState = try device.makeComputePipelineState(function: computeFunction!)
		} catch {
			print(error)
		}
		MaxThreadsPerGroup = ComputePipelineState.maxTotalThreadsPerThreadgroup

		//MARK: Reset Compute
		let resetFunction = defaultLibrary?.makeFunction(name: "reset_compute_shader")

		do {
			ResetComputePipelineState = try device.makeComputePipelineState(function: resetFunction!)
		} catch {
			print(error)
		}
		print("finished creating pipelines")

		Container = VoxelContainer()
		LoadJuliaSet(quality: 50)
	}
}
