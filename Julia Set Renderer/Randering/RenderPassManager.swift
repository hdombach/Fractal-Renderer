//
//  RenderPassManager.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 4/14/21.
//  Copyright © 2021 Hezekiah Dombach. All rights reserved.
//

import Foundation
import MetalKit

class RenderPassManager: ObservableObject {
	var document: Document
	var graphics: Graphics
	var commandQueue: MTLCommandQueue
	
	var result: Texture
	
	var isRendering = false
	var samplesCurrent: Int = 1
	var samplesGoal: Int = 0
	@Published var progress: String = "0% (0 / 0)"
	
	private var computeIndex: Int = 0
	private var content: Content { document.content }
	
	init(doc: Document) {
		self.document = doc
		self.graphics = doc.graphics
		commandQueue = graphics.device.makeCommandQueue()!
		result = Texture("yeet", doc: document)
	}
	
	func resetRender() {
		computeIndex = 0
		samplesCurrent = 1
		samplesGoal = 0
		resetTexture()
	}
	
	func startRender(samplesCount: Int) {
		result.updateTexture()
		samplesGoal += samplesCount
		isRendering = true
		
	}
	
	private func resetTexture() {
		
		
		DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 0.1) {
			var computeState = self.graphics.library[LibraryManager.ComputePipelineState.reset]
			
			if let computeState = computeState {
				let commandBuffer = self.commandQueue.makeCommandBuffer()
				let computeCommandEncoder = commandBuffer?.makeComputeCommandEncoder()
				computeCommandEncoder?.setComputePipelineState(computeState)
				computeCommandEncoder?.setTexture(self.result.texture, index: 0)
				
				let threadsPerGrid = MTLSize(width: self.result.texture.width, height: self.result.texture.height, depth: 1)
				let maxThreadsPerThreadgroup = computeState.maxTotalThreadsPerThreadgroup
				let groupSize = Int(floor(sqrt(Float(maxThreadsPerThreadgroup))))
				let threadsPerThreadgroup = MTLSize(width: groupSize, height: groupSize, depth: 1)
				
				var shaderInfo = ShaderInfo()
				shaderInfo.channelsLength = self.result.currentChannelCount
				
				computeCommandEncoder?.setBytes(&shaderInfo, length: MemoryLayout<ShaderInfo>.stride, index: 0)
				
				computeCommandEncoder?.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
				
				computeCommandEncoder?.endEncoding()
				commandBuffer?.commit()
			}
		}
	}
	
	func renderPass(commandBuffer: MTLCommandBuffer, mode: ViewportMode) {
		//This function is called every frame so it has to return if it isn't supposed to be rendering.
		if (mode != .rendering) {
			return;
		}
		
		if samplesCurrent >= samplesGoal && samplesCurrent > 0 {
			isRendering = false
			return;
		}
		
		var computeState = graphics.library[LibraryManager.ComputePipelineState.render]
		
		if let computeState = computeState {
			//set up compute encoder
			let groupSize = document.content.kernelGroupSize
			let groups = document.content.kernelGroups
			
			let computeCommandEncoder = commandBuffer.makeComputeCommandEncoder(dispatchType: .concurrent)
			computeCommandEncoder?.setComputePipelineState(computeState)
			computeCommandEncoder?.setTexture(result.texture, index: 0)
			computeCommandEncoder?.setTexture(result.texture, index: 1)
			
			let threadsPerThreadgroup = MTLSize(width: groupSize, height: 1, depth: 1)
			let threadsPerGrid = MTLSize(width: groupSize * groups, height: 1, depth: 1)
			
			var stop = groupSize * groups + content.imageSize.x * content.imageSize.y
			if (samplesCurrent + 1 >= samplesGoal) {
				stop = content.imageSize.x * content.imageSize.y
			}
			
			var shaderInfo = ShaderInfo()
			shaderInfo.camera = content.camera
			shaderInfo.realIndex = SIMD4<UInt32>.init(UInt32(computeIndex), UInt32(content.imageSize.x), UInt32(content.imageSize.y), UInt32(stop))
			shaderInfo.randomSeed = SIMD3<UInt32>.random(in: 0...1000000)
			shaderInfo.voxelsLength = UInt32(document.container.voxelCount)
			shaderInfo.isJulia = graphics.renderMode.rawValue
			shaderInfo.lightsLength = UInt32(content.skyBox.count)
			shaderInfo.rayMarchingSettings = content.rayMarchingSettings
			shaderInfo.channelsLength = UInt32(content.channels.count)
			shaderInfo.atmosphere = content.atmosphereSettings
			
			computeCommandEncoder?.setBytes(&shaderInfo, length: MemoryLayout<ShaderInfo>.stride, index: 0)
			computeCommandEncoder?.setBuffer(document.container.voxelBuffer, offset: 0, index: 1)
			computeCommandEncoder?.setBytes(&content.skyBox, length: MemoryLayout<LightInfo>.stride * Int(shaderInfo.lightsLength), index: 2)
			computeCommandEncoder?.setBytes(content.materialNodeContainer.constants, length: MemoryLayout<Float>.stride * content.materialNodeContainer.constants.count, index: 4)
			computeCommandEncoder?.setBytes(content.deNodeContainer.constants, length: MemoryLayout<Float>.stride * content.deNodeContainer.constants.count, index: 5)
			
			computeCommandEncoder?.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
			computeCommandEncoder?.endEncoding()
			
			computeIndex += groupSize * groups
			while computeIndex > content.imageSize.x * content.imageSize.y {
				samplesCurrent += 1
				computeIndex -= content.imageSize.x * content.imageSize.y
			}
			
			//update progress ui
			var newProgress: String = ""
			if (samplesGoal == 0) {
				newProgress = "0%"
			} else {
				newProgress = "\(100 * samplesCurrent / samplesGoal)% (\(samplesCurrent) / \(samplesGoal))"
			}
			if (newProgress != progress) {
				progress = newProgress
			}
		}
	}
	
}
