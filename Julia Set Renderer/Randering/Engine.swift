//
//  Engine.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 7/2/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import MetalKit

class Engine {
    //new pull
	public static var Device: MTLDevice!
	public static var CommandQueue: MTLCommandQueue!
	public static var ComputeQueue: MTLCommandQueue!
	public static var PreviewPipelineState: MTLRenderPipelineState!
	public static var RenderPipelineState: MTLRenderPipelineState!
	public static var ComputePipelineState: MTLComputePipelineState!
	public static var ResetComputePipelineState: MTLComputePipelineState!
	public static var JuliaSetPipelineState: MTLComputePipelineState!
	public static var JuliaSetShrinkPipelineState: MTLComputePipelineState!
	public static var SamplerState: MTLSamplerState!
	public static var PixelFormat = (MTLPixelFormat.rgba16Float, MTLPixelFormat.r32Float)
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
	public static var JuliaSetComputeSettings = JuliaSetSettings(rSlope: 0.5, rIntercept: 0, iSlope: 0.5, iIntercept: 0, iterations: 100)

	static var index: Int = 0
	//public static var obversedSettings = RenderSettings()

	private static var lastPassTime = 1.0
    private static var lastUpdate = false

	public static func ResetRender() {
		index = 0
	}

	static var countdown: Int = 0

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


			
			computeCommandEncoder?.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)

			computeCommandEncoder?.endEncoding()
			commandBuffer?.commit()
		}
		ResetRender()
		Settings.exposure = 1
		Settings.samples = 0
	}

	public static func JuliaSetPass() {
		if !Container.activeAddress.isDefault() || lastUpdate {
            //print("update")
            print("—————————NEW FRAME——————————————")
			let startTime = CACurrentMediaTime()
            var lastTime = startTime
            func log(title: String) {
                let currentTime = CACurrentMediaTime()
                let deltaTime = currentTime - lastTime
                lastTime = currentTime
                print(title, deltaTime)
            }
			//print("————————————NEW FRAME————————————————")

			//Continue loading where last left off
			var currentPasses: Int = 0
			if 1 / 60 / lastPassTime > 100 {
				currentPasses = 100
			} else {
				currentPasses = Int(1 / 60 / lastPassTime)
			}
			if 10 > currentPasses {
				currentPasses = 10
			}
			//Container.load(passCount: currentPasses)
			Container.load(passCount: currentPasses)
			log(title: "load-100")
			/*print("newFrame____")
			for voxel in Container.voxels {
				print(voxel)
			}
			for index in Container.deleteQueue {
				print(index)
			}*/
			Container.deleteVoxels()
            log(title: "deleteVoxels")
            //print(Container.queue)

			Container.updateQueueBuffer()
			Container.updateVoxelBuffer()
            log(title: "updateBuffers")
            
            
            let commandBuffer = ComputeQueue.makeCommandBuffer()

            let maxWidth = 10
            let threadsPerThreadgroup = MTLSize(width: maxWidth, height: 1, depth: 1)
            let threadsPerGrid = MTLSize(width: Container.queue.count, height: 1, depth: 1)
            var voxelLength = UInt32(Container.voxels.count)
            
            countdown += 1
            if countdown > 50 || Container.activeAddress.isDefault() || lastUpdate {
                countdown = 0
                let shrinkCommandEncoder = commandBuffer?.makeComputeCommandEncoder()
                shrinkCommandEncoder?.setComputePipelineState(JuliaSetShrinkPipelineState)

                shrinkCommandEncoder?.setBuffer(Container.queueBuffer, offset: 0, index: 0)
                shrinkCommandEncoder?.setBytes(&JuliaSetComputeSettings, length: MemoryLayout<JuliaSetSettings>.stride, index: 1)
                shrinkCommandEncoder?.setBuffer(Container.voxelBuffer, offset: 0, index: 2)
                shrinkCommandEncoder?.setBytes(&voxelLength, length: MemoryLayout<UInt32>.stride, index: 4)
                let threadsPerPerShrinkGrade = MTLSize(width: Container.voxels.count, height: 1, depth: 1)

                shrinkCommandEncoder?.dispatchThreads(threadsPerPerShrinkGrade, threadsPerThreadgroup: threadsPerThreadgroup)

                shrinkCommandEncoder?.endEncoding()
            }


			if Container.queue.count > 0 {
                let computeCommandEncoder = commandBuffer?.makeComputeCommandEncoder()
				computeCommandEncoder?.setComputePipelineState(JuliaSetPipelineState)

				computeCommandEncoder?.setBuffer(Container.queueBuffer, offset: 0, index: 0)
				computeCommandEncoder?.setBytes(&JuliaSetComputeSettings, length: MemoryLayout<JuliaSetSettings>.stride, index: 1)
				computeCommandEncoder?.setBuffer(Container.voxelBuffer, offset: 0, index: 2)
				computeCommandEncoder?.setBytes(&Settings.savedCamera, length: MemoryLayout<Camera>.stride, index: 3)
				computeCommandEncoder?.setBytes(&voxelLength, length: MemoryLayout<UInt32>.stride, index: 4)

				computeCommandEncoder?.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)

				computeCommandEncoder?.endEncoding()

				commandBuffer?.commit()
				commandBuffer?.waitUntilCompleted()
                log(title: "computers")
				Container.updateFromBuffer()


				log(title: "loadFromBuffer")
                
			}
            
            Container.shrinkVoxels()
            log(title: "shrinking")

			lastPassTime = (CACurrentMediaTime() - startTime) / Double(currentPasses)
            
            if Container.activeAddress.isDefault() && !lastUpdate {
                print("finisehd")
                lastUpdate = true
            } else {
                if lastUpdate {
                    for voxel in Container.voxels {
                        for c in 0...8 {
                            if Container.voxels.count <= voxel.childAddress(UInt32(c)).index || (Container.voxels[Int(voxel.childAddress(UInt32(c)).index)].id != voxel.childAddress(UInt32(c)).id) {
                                print("mismatch", c, voxel)
                            }
                        }
                    }
                }
                lastUpdate = false
            }
			/*if Container.activeVoxel == nil || countdown > 50 {
				Container.loadIntoVoxelBuffer()
				UpdateVoxelBuffer()
				countdown = 0
				if Container.activeVoxel == nil {
					Container.root.deleteChildren()
					print("finished")
				}
			}*/
		}
	}

	public static func RenderPass(groupSize: Int, groups: Int) {
		if Engine.Settings.window == .preview {
			MainTexture = Texture.init("yeet")
			return;
		}
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
		var mutableIndex = SIMD4<UInt32>.init(UInt32(index), UInt32(Settings.imageSize.0), UInt32(Settings.imageSize.1), UInt32(stop))
		var voxelsLength = UInt32(Container.voxels.count)

		computeCommandEncoder?.setBytes(&Settings.camera, length: MemoryLayout<Camera>.stride, index: 0)
		computeCommandEncoder?.setBuffer(Container.voxelBuffer, offset: 0, index: 1)
		computeCommandEncoder?.setBytes(&mutableIndex, length: MemoryLayout<SIMD4<UInt32>>.stride, index: 2)
		var seed = SIMD3<Int32>.init(Int32.random(in: 0...10000), Int32.random(in: 0...10000), Int32.random(in: 0...10000))
		computeCommandEncoder?.setBytes(&seed, length: MemoryLayout<SIMD3<Int32>>.stride, index: 3)
		computeCommandEncoder?.setBytes(&voxelsLength, length: MemoryLayout<UInt32>.stride, index: 4)
		computeCommandEncoder?.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)

		computeCommandEncoder?.endEncoding()

		commandBuffer?.commit()
		commandBuffer?.waitUntilCompleted()

		index += groupSize * groups
		while index > Settings.imageSize.0 * Settings.imageSize.1 {
			Settings.exposure += 1
			index -= Settings.imageSize.0 * Settings.imageSize.1
		}
		//print(Settings.exposure)

		//commandBuffer?.waitUntilCompleted()
	}

	public static func Render(size: UInt32, depth: Int) {

		DispatchQueue.global().async {
			Settings.samples = 1
			for i in 0...1919 {
				//RenderPass(groupSize: 10, groups: 108, index: i * 1080)
			}
		}

	}

	public static func LoadJuliaSet(quality: Float) {
		/*Engine.Settings.savedCamera = Engine.Settings.camera
		DispatchQueue.global().async {
			let startTime = CACurrentMediaTime()
			let updateInterval: Double = 10
			var lastTime = CACurrentMediaTime()
			var counter = 200 //so u don'w get current time for every voxel
			let rootVoxel = LoadVoxel()

			func updateProgress() {
				counter -= 1
				if 0 > counter {
					let current = CACurrentMediaTime()
					if current - lastTime > updateInterval {
						Engine.Container.loadIntoBuffer(rootVoxel: rootVoxel)
						Engine.UpdateVoxelBuffer()
						lastTime = current
					}
					counter = 100
				}
			}

			rootVoxel.addJuliaSet(currentSize: 0, finalSize: quality, container: Container, progressTracker: updateProgress)

			Engine.Container.loadIntoBuffer(rootVoxel: rootVoxel)
			Engine.UpdateVoxelBuffer()

			print("julia set took \(CACurrentMediaTime() - startTime) seconds.")*/
        Container.loadQuality = quality
		Engine.Settings.savedCamera = Engine.Settings.camera
		Container.loadBegin()
	}


	public static func Init(device: MTLDevice) {

		self.Device = device
		self.CommandQueue = device.makeCommandQueue()
		self.ComputeQueue = device.makeCommandQueue()

		let defaultLibrary = Device.makeDefaultLibrary()

		assert(defaultLibrary != nil, "could not get default library")

		//MARK: Render
		let vertexShader = defaultLibrary?.makeFunction(name: "basic_vertex_shader")
		let previewFragmentShader = defaultLibrary?.makeFunction(name: "sample_fragment_shader")
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

		//MARK: Julia Set Compute
		let juliaSetFunction = defaultLibrary?.makeFunction(name: "julia_set_compute_shader")

		do {
			JuliaSetPipelineState = try device.makeComputePipelineState(function: juliaSetFunction!)
		} catch {
			print(error)
		}

		let juliaSetShrinkFunciton = defaultLibrary?.makeFunction(name: "julia_set_shrink_Shader")

		do {
			JuliaSetShrinkPipelineState = try device.makeComputePipelineState(function: juliaSetShrinkFunciton!)
		} catch {
			print(error)
		}

		Container = VoxelContainer()
		//Container.loadIntoVoxelBuffer()

		//print(Container ?? 2)
		LoadJuliaSet(quality: 100)


		/*let rootVoxel = LoadVoxel()
		let time = CACurrentMediaTime()
		rootVoxel.addJuliaSet(currentSize: 0, finalSize: 100, container: Container, progressTracker: {})
		let loadTime = CACurrentMediaTime()
		Container = VoxelContainer()
		Container.loadIntoBuffer(rootVoxel: rootVoxel)
		let compressTime = CACurrentMediaTime()

		print("load time: \(loadTime - time), compressTime: \(compressTime - loadTime)")

		UpdateVoxelBuffer()*/
	}
}
