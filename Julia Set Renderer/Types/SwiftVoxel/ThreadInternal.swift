//
//  ThreadInternal.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 12/24/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import Foundation
import simd
import MetalKit

extension VoxelContainerThread {
	
	///Returns the size of the voxel on the screen
	func voxelSize(index: Int, voxelBuffer: UnsafeMutableBufferPointer<Voxel>) -> Float {
		let width = pow(0.5, Float(voxelBuffer[index].layer + 1))
		let position = voxelBuffer[index].position
		var voxelSize = (Engine.Settings.savedCamera.cameraDepth * width / distance(Engine.Settings.savedCamera.position, SIMD4<Float>(position, 0))) / Engine.Settings.savedCamera.zoom
		if 0 > dot(SIMD4<Float>(0, 0, 1, 0) * Engine.Settings.savedCamera.rotateMatrix, SIMD4<Float>(position, 0) - Engine.Settings.savedCamera.position) {
			voxelSize = voxelSize / 2
		}
		return voxelSize
	}
	
	///Returns then layer depth at a point
	func layerDepth(position: SIMD3<Float>) -> Int {
		var depth = Int(ceil(container.loadQuality * distance(Engine.Settings.savedCamera.position, SIMD4<Float>(position, 0)) * Engine.Settings.savedCamera.zoom / Engine.Settings.savedCamera.cameraDepth))
		if depth > maxLayer {
			depth = maxLayer
		}
		return depth
	}
	
	///Returns the offset of the child in the parent from the childs index
	func voxelChildOffset(index: Float) -> SIMD3<Float> {
		let z = floor(index / 4)
		let y = floor(fmod(index, 4) / 2)
		let x = fmod(index, 2)
		
		return .init(x, y, z)
	}
	
	///Returns the child index at the offset in parent
	func voxelChildId(position: (Bool, Bool, Bool)) -> Int {
		var index = 0
		if position.0 {
			index += 1
		}
		if position.1 {
			index += 2
		}
		if position.2 {
			index += 4
		}
		
		return index
	}
	
	///Returns the child index at the global position
	func voxelChildId(voxel: VoxelAddress, globalPosition: SIMD3<Float>, voxelBuffer: UnsafeMutableBufferPointer<Voxel>) -> Int {
		let voxel = voxelBuffer[voxel]
		var offset = (false, false, false)
		let width = voxel.width / 2
		offset.0 = globalPosition.x >= voxel.position.x + width
		offset.1 = globalPosition.y >= voxel.position.y + width
		offset.2 = globalPosition.z >= voxel.position.z + width
		return voxelChildId(position: offset)
	}
	
	///searches through tree to find voxel at global position
	func voxelAtPoint(rootVoxel: VoxelAddress, position: SIMD3<Float>, voxelBuffer: UnsafeMutableBufferPointer<Voxel>) -> VoxelAddress {
		var currentVoxel = rootVoxel
		while (!voxelBuffer[currentVoxel].isEnd) {
			currentVoxel = voxelChildIndex(voxel: currentVoxel, position: position, voxelBuffer: voxelBuffer)
		}
		return currentVoxel
	}
	
	///Returns the address of the child at a position
	func voxelChildIndex(voxel: VoxelAddress, position: SIMD3<Float>, voxelBuffer: UnsafeMutableBufferPointer<Voxel>) -> VoxelAddress {
		return voxelBuffer[voxel].childAddress(voxelChildId(voxel: voxel, globalPosition: position, voxelBuffer: voxelBuffer))
	}
	
	
	func voxelContainsPoint(voxel voxelAddress: VoxelAddress, position: SIMD3<Float>, voxelBuffer: UnsafeMutableBufferPointer<Voxel>) -> Bool {
		let voxel = voxelBuffer[voxelAddress]
		if position.x > voxel.position.x && position.x < voxel.position.x + voxel.width {
			if position.y > voxel.position.y && position.y < voxel.position.y + voxel.width {
				if position.z > voxel.position.z && position.z < voxel.position.z + voxel.width {
					return true
				}
			}
		}
		return false
	}
	
	
	func removeChildren(index: Int, voxelBuffer: UnsafeMutableBufferPointer<Voxel>) {
		for c in 0...7 {
			removeChild(index: index, child: c, voxelBuffer: voxelBuffer)
		}
		voxelBuffer[index].isEnd = true
	}
	func removeChild(index: Int, child: Int, voxelBuffer: UnsafeMutableBufferPointer<Voxel>) {
		let childIndex = voxelBuffer[index].childAddress(child)
		deletedIndexes.append(Int(childIndex))
		voxelBuffer[index].setChildAddress(child, to: VoxelAddress.init())
	}
	
	func addVoxel(parentIndex: Int, childIndex: Int, voxelBuffer: UnsafeMutableBufferPointer<Voxel>) -> VoxelAddress {
		var returnAddress: VoxelAddress = VoxelAddress.init()
		var index: Int!
		if deletedIndexes.count > 0 {
			index = deletedIndexes[0]
			deletedIndexes.removeFirst()
		} else {
			container.containerSemaphore.wait()
			index = container.voxelCount
			container.voxelCount += 1
			container.containerSemaphore.signal()
		}
		returnAddress = index!
		self.id += UInt32(containerThreads)
		
		if parentIndex > 0 {
			let parent = voxelBuffer[parentIndex]
			
			voxelBuffer[index]._p = UInt32(parentIndex)
			voxelBuffer[index].layer = parent.layer + 1
			voxelBuffer[index].position = parent.position + voxelBuffer[index].width * voxelChildOffset(index: Float(childIndex))
		}
		
		self.voxelsMade += 1
		
		return returnAddress
	}
	
	func divideVoxel(index: Int, voxelBuffer: UnsafeMutableBufferPointer<Voxel>) {
		voxelBuffer[index].isEnd = false
		for c in 0...7 {
			let child = addVoxel(parentIndex: index, childIndex: c, voxelBuffer: voxelBuffer)
			updateVoxelOpacity(index: Int(child), voxelBuffer: voxelBuffer)
		}
	}
}
