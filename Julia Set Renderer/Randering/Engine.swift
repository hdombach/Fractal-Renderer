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
	public static var Library = LibraryManager()
	public static var PixelFormat = (MTLPixelFormat.rgba16Float, MTLPixelFormat.r32Float)
	public static var View: MTKView!
	//public static var SceneCamera: Camera {
		//return Engine.Settings.camera
	//}
	//public static var SceneCamera = Camera(position: SIMD4<Float>(0, 0, -1, 0), deriction: SIMD4<Float>(0, 0, 0, 0), zoom: 1 / 2000, cameraDepth: 1, rotateMatrix: matrix_identity_float4x4, resolution: SIMD2<Float>(1920, 1080))
	public static var Container: VoxelContainer!
	public static var MainTexture = Texture.init("yeet")
	public static var Settings = JoinedRenderSettings()
	public static var MaxThreadsPerGroup: Int!
	//public static var MainJuliaSet = JuliaSet()
	//public static var MainPointGen = linearComGen(rSlope: 1, rIntercept: 0.1, iSlope: 1, iIntercept: -0.3)
    public static var JuliaSetSettings = LinearJuliaSet()

	static var computeIndex: Int = 0
    
    public static var isRendering = false

	public static func ResetRender() {
		computeIndex = 0
	}

	private static var countdown: Int = 0

	public static func ResetTexture() {
		DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 0.1) {
			let commandBuffer = ComputeQueue.makeCommandBuffer()
			let computeCommandEncoder = commandBuffer?.makeComputeCommandEncoder()
			computeCommandEncoder?.setComputePipelineState(Library[LibraryManager.ComputePipelineState.reset])
			computeCommandEncoder?.setTexture(MainTexture.texture, index: 0)

			let threadsPerGrid = MTLSize.init(width: MainTexture.texture.width, height: MainTexture.texture.height, depth: 1)
			let maxThreadsPerThreadgroup = Library[LibraryManager.ComputePipelineState.render].maxTotalThreadsPerThreadgroup
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
				computeCommandEncoder?.setComputePipelineState(Library[LibraryManager.ComputePipelineState.render])
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
				shaderInfo.realIndex = SIMD4<UInt32>.init(UInt32(computeIndex), UInt32(Settings.imageSize.0), UInt32(Settings.imageSize.1), UInt32(stop))
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

                computeIndex += groupSize * groups
                while computeIndex > Settings.imageSize.0 * Settings.imageSize.1 {
                    Settings.exposure += 1
                    computeIndex -= Settings.imageSize.0 * Settings.imageSize.1
                }
				var progress: String = ""
				if Engine.Settings.samples == 0 {
					progress = "0%"
				} else {
					progress = "\(100 * Engine.Settings.exposure / Engine.Settings.samples)% (\(Engine.Settings.exposure) / \(Engine.Settings.samples))"
				}
				if progress != Engine.Settings.progress {
					DispatchQueue.main.async {
						Engine.Settings.progress = progress
					}
				}
            }
            isRendering = false
        }
	}

	public static func LoadJuliaSet(quality: Float) {
        Container.loadQuality = quality
		Engine.Settings.savedCamera = Engine.Settings.camera
		Container.load(passSize: 10000)
	}

	public static func ResetJuliaSet() {
		Container.reset()
	}
	
	public static func Init(device: MTLDevice) {

		self.Device = device
		self.CommandQueue = device.makeCommandQueue()
		self.ComputeQueue = device.makeCommandQueue()

		let defaultLibrary = Device.makeDefaultLibrary()

		assert(defaultLibrary != nil, "could not get default library")

		Library.setUp(library: Device.makeDefaultLibrary())

		Container = VoxelContainer()
		ResetJuliaSet()
	}
}
