//
//  VoxelContainer.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 12/24/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import Foundation
import simd
import MetalKit

class VoxelContainer {
	private var voxels: [Voxel] = []
	var loadQuality: Float = 10
	var loadThreads: Int = 4
	var startingsLayer: Int = 2
	var threads: [VoxelContainerThread] = []
	var voxelCount: Int = 0
	var isComplete = false
	var threadQueue: [Int] = []
	
	var containerSemaphore = DispatchSemaphore.init(value: 1)
	var containerQueue: DispatchQueue = .init(label: "Append Thread")
	
	/*func getIndex(address: inout VoxelAddress) -> Int {
	if voxels.count <= address.index || voxels[Int(address.index)].id != address.id {
	for c in 0...voxels.count - 1 {
	let diff = (c % 2) * 2 - 1
	var newIndex = (Int(ceil(Float(c) / 2)) * diff + Int(address.index)) % voxels.count
	if 0 > newIndex {
	newIndex += voxels.count
	}
	if voxels[newIndex].id == address.id {
	return newIndex
	}
	}
	return 0
	}
	return Int(address.index)
	}*/
	
	func reset() {
		threads.removeAll()
		containerSemaphore = DispatchSemaphore.init(value: 1)
		voxels.removeAll()
		threadQueue.removeAll()
		voxels.append(Voxel.init())
		voxels[0].isEnd = true
		voxels[0].opacity = -1
		
		isComplete = true
		print("reset")
		updateVoxelBuffer()
	}
	
	func loadBegin() {
		containerSemaphore = DispatchSemaphore.init(value: 1)
		voxels.removeAll()
		threadQueue.removeAll()
		voxels.append(Voxel.init())
		voxels[0].isEnd = true
		voxels[0].opacity = -1
		
		isComplete = false
		
		voxels += Array.init(repeating: Voxel.init(), count: 73)
		
		voxelCount = 2
		let originalLoadThreads = loadThreads
		loadThreads = 1
		let thread = VoxelContainerThread.init(container: self, root: 1, thread: 1, shouldShrink: false)
		thread.maxLayer = 2
		
		voxels.withUnsafeMutableBufferPointer { (buffer) -> () in
			DispatchQueue.global().sync {
				//thread.pass(length: 100, voxelBuffer: buffer)
			}
			thread.pass(length: 1000, voxelBuffer: buffer)
		}
		//print(1, voxels[1].description())
		print(voxelCount)
		loadThreads = originalLoadThreads
		
		threads.removeAll()
		for c in 2...73 {
			threadQueue.append(c)
		}
		threadQueue.sort { (closer, farther) -> Bool in
			let position = Engine.Settings.camera.position
			let closerDistance = distance(position, SIMD4<Float>(voxels[Int(closer)].position, 1))
			let fartherDistance = distance(position, SIMD4<Float>(voxels[Int(farther)].position, 1))
			return closerDistance < fartherDistance
		}
		
		for c in 0...loadThreads - 1 {
			threads.append(VoxelContainerThread.init(container: self, root: threadQueue[0], thread: c, shouldShrink: true))
			threadQueue.removeFirst()
		}
		print("finished begging")
		
		updateVoxelBuffer()
	}
	
	func getVoxelSize(position: SIMD3<Float>, size: Int, width: Float?) -> Float {
		var uWidth: Float!
		if width == nil {
			uWidth = pow(0.5, Float(size + 1))
		} else {
			uWidth = width!
		}
		var voxelSize = (Engine.Settings.savedCamera.cameraDepth * uWidth / distance(Engine.Settings.savedCamera.position, SIMD4<Float>(position, 0))) / Engine.Settings.savedCamera.zoom
		if 0 > dot(SIMD4<Float>(0, 0, 1, 0) * Engine.Settings.savedCamera.rotateMatrix, SIMD4<Float>(position, 0) - Engine.Settings.savedCamera.position) {
			voxelSize = voxelSize / 4
		}
		
		return voxelSize
	}
	
	func load(passSize: Int) {
		containerQueue.async { [self] in
			print("load begin")
			let startTime = CACurrentMediaTime()
			self.loadBegin()
			while !self.isComplete {
				self.update(passCount: passSize)
			}
			let deltaTime = CACurrentMediaTime() - startTime
			var voxelsCreated: UInt = 0
			for thread in threads {
				voxelsCreated += thread.voxelsMade
			}
			print("load finished. \(voxelsCreated) voxels in \(deltaTime) seconds. \(Double(voxelsCreated) / deltaTime) voxels/second")
		}
	}
	
	func update(passCount: Int) {
		let group = DispatchGroup.init()
		
		voxels += Array.init(repeating: Voxel.init(), count: passCount * threads.count)
		voxels.withUnsafeMutableBufferPointer { (voxelBuffer) -> () in
			let voxelBufferCopy = voxelBuffer
			for thread in threads {
				if !thread.isDone {
					group.enter()
					DispatchQueue.global().async {
						thread.pass(length: passCount, voxelBuffer: voxelBufferCopy)
						group.leave()
					}
				}
			}
			group.wait()
			voxelBuffer = voxelBufferCopy
		}
		if voxels.count > voxelCount {
			voxels.removeSubrange(voxelCount...voxels.count - 1)
		}
		updateVoxelBuffer()
		
		isComplete = true
		
		for c in 0...threads.count - 1 {
			if !threads[c].isDone {
				isComplete = false
			} else if threadQueue.count > 0 {
				isComplete = false
				threads[c].reset(root: threadQueue.first!)
				threadQueue.removeFirst()
			}
		}
	}
	
	//MARK: Buffers
	var voxelBuffer: MTLBuffer?
	
	func updateVoxelBuffer() {
		if voxels.count > 0 {
			voxelBuffer = Engine.Device.makeBuffer(bytes: voxels, length: MemoryLayout<Voxel>.stride * voxels.count, options: [])
		}
	}
}
