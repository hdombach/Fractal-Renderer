//
//  SwiftVoxel.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 8/31/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import Foundation
import simd
import MetalKit

class VoxelContainer {
	var voxels: [Voxel] = [] /*{
		didSet {
			if voxels.count > 0 {
				let voxel = voxels[0]
				var sum: UInt32 = 0
				for c in UInt32(0)...7 {
					sum += voxel.childAddress(c).id
				}
				if sum > 0 {
					print("oh dear")
				}
			}
		}
	}*/
	var queue: [VoxelAddress] = []
	var id: UInt32 = 1
	var activeAddress: VoxelAddress = .init()
	var shrinkQueue: [VoxelAddress] = []
	var deleteQueue: [Int] = []
    var loadQuality: Float = 10

	/*func getVoxel(address: inout VoxelAddress) -> Voxel {
		if voxels[Int(address.index)].id != address.id {
			let index = voxels.firstIndex { (voxel) -> Bool in
				voxel.id == address.id
			}
			address.index = UInt32(index!)
		}
		return voxels[Int(address.index)]
	}*/

	func getIndex(address: inout VoxelAddress) -> Int {
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
	}

	func getVoxel(address: inout VoxelAddress) -> Voxel {
		let voxel = voxels[getIndex(address: &address)]
		if voxel.isDeleted {
			return voxels[0]
		} else {
			return voxel
		}
	}

	func useVoxel(address: inout VoxelAddress, action: (inout Voxel) -> ()) {
		let index = getIndex(address: &address)
		action(&voxels[index])
	}

	func loadBegin() {
		voxels.removeAll()
        deleteQueue.removeAll()
        shrinkQueue.removeAll()
		voxels.append(Voxel.init())
		id = 1
		voxels[0].isEnd = true
		voxels[0].isDeleted = false
		voxels[0].opacity = -1
		voxels.append(Voxel.init(container: self))
		activeAddress = VoxelAddress.init(voxel: voxels[1])
		updateVoxelBuffer()
	}

	func load(passCount: Int) {
        queue.removeAll()
		if !activeAddress.isDefault() {
			//shrinkQueue.append(activeAddress)
			for _ in 1...passCount {
				update()
				if activeAddress.isDefault() || activeAddress.id == 0 { break }
			}
        }
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

	func update() {
		if activeAddress.isDefault() || activeAddress.id == 0 { return }
		var newVoxel: Voxel?
		var newActiveAddress: VoxelAddress?
		let voxelsCount = voxels.count
		var shouldShrink: Bool = false
		useVoxel(address: &activeAddress) { (voxel) in
			let childrenCompleted = voxel.childrenCompleted()
		//	print(childrenCompleted)
            
			if 8 > childrenCompleted && !voxel.isDeleted {
				let v = voxel
				voxel.isEnd = false
				voxel.useAddress(Int(childrenCompleted)) { (address) in
					newVoxel = Voxel.init(parent: v, container: self, childIndex: childrenCompleted, address: &address)
					address.index = UInt32(voxelsCount)
					newVoxel?.isEnd = true
					newActiveAddress = address
                    queue.append(newActiveAddress!)
				}
                voxel.setChildAddress(childrenCompleted, to: newActiveAddress!)
                if getVoxelSize(position: voxel.position, size: 1, width: voxel.width) < loadQuality * 2 && voxel.layer < 12{
                    newActiveAddress = newVoxel!._p
                }
			} else {
				//shouldShrink = (voxel.width > pow(0.5, 4))
				shouldShrink = true
				newActiveAddress = voxel._p
			}
		}
        if newActiveAddress == nil {
            newActiveAddress = activeAddress
        }
		if newVoxel != nil {
			voxels.append(newVoxel!)
		}
		if shouldShrink && activeAddress.id != 0 {
			shrinkQueue.append(activeAddress)
		}
        activeAddress = newActiveAddress!
	}

	func shrink(address: VoxelAddress) {
		if address.id == 0 {
			return
		}
		var a = address
		var indexes: [Int] = []
		var voxel = getVoxel(address: &a)
		/*if voxel.isDeleted || voxel.isEnd || voxel.id == 0 || voxel.childrenCompleted() != 8{
			return
		}*/
		//print(voxel.id)
		let child0 = getVoxel(address: &voxel._0)
		for c in UInt32(0)...7 {
			var currentChildAddress = voxel.childAddress(c)
			let currentChildIndex = getIndex(address: &currentChildAddress)
			let currentChild = voxels[currentChildIndex]
			if currentChild.id == 0 {
				return
			}

			if !currentChild.isEnd || currentChild.opacity != child0.opacity || currentChild.opacity == -1 || currentChild.isDeleted{
				return
			}
			//print(currentChildAddress.id, activeAddress.id)
			indexes.append(currentChildIndex)
		}
		deleteQueue += indexes
		useVoxel(address: &a) { (voxel) in
			voxel.isEnd = true
			voxel.resetChildren()

			//voxel.isDeleted = true
			//print("remove", voxel)
		}

	}

	func shrinkVoxels() {
		for address in shrinkQueue {
			shrink(address: address)
		}
		shrinkQueue.removeAll()
	}

	func deleteVoxels() {
		deleteQueue = deleteQueue.sorted(by: { (l, r) -> Bool in
			l > r
		})
		for index in deleteQueue {
			voxels.remove(at: index)
		}
		deleteQueue.removeAll()

	}

	//MARK: Buffers
	var voxelBuffer: MTLBuffer?
	var queueBuffer: MTLBuffer?

	func updateVoxelBuffer() {
		if voxels.count > 0 {
			voxelBuffer = Engine.Device.makeBuffer(bytes: voxels, length: MemoryLayout<Voxel>.stride * voxels.count, options: [])
		}
	}
	func updateQueueBuffer() {
		if queue.count > 0 {
			queueBuffer = Engine.Device.makeBuffer(bytes: queue, length: MemoryLayout<VoxelAddress>.stride * queue.count, options: [])
		}
	}
	func updateFromBuffer() {
		voxels = Array(UnsafeBufferPointer(start: voxelBuffer?.contents().bindMemory(to: Voxel.self, capacity: voxels.count), count: voxels.count))
	}
}

struct Voxel {
	var id: UInt32 = 0
	var opacity: Float = 0
	var isEnd: Bool = false
	var isDeleted: Bool = false
	var position: SIMD3<Float> = .init(0, 0, 0)
	var layer: UInt32 = 0
	var width: Float {
		pow(0.5, Float(layer))
	}

	var _p: VoxelAddress = .init()
	var _0: VoxelAddress = .init()
	var _1: VoxelAddress = .init()
	var _2: VoxelAddress = .init()
	var _3: VoxelAddress = .init()
	var _4: VoxelAddress = .init()
	var _5: VoxelAddress = .init()
	var _6: VoxelAddress = .init()
	var _7: VoxelAddress = .init()

	init() {

	}

	init(container: VoxelContainer) {
		self.id = container.id
		container.id += 1
	}

	init(parent: Voxel, container: VoxelContainer, childIndex: UInt32, address: inout VoxelAddress) {
		self.init(container: container)

		address.id = self.id

		_p.id = parent.id
		layer = parent.layer + 1
		position = parent.position + width * getOffset(index: Float(childIndex))
	}

	private func getOffset(index: Float) -> SIMD3<Float> {
		let z = floor(index / 4)
		let y = floor(fmod(index, 4) / 2)
		let x = fmod(index, 2)

		return .init(x, y, z)
	}


	mutating func useAddress(_ index: Int, action: (inout VoxelAddress) -> ()) {
		switch index {
		case -1: action(&_p)
		case 0: action(&_0)
		case 1: action(&_1)
		case 2: action(&_2)
		case 3: action(&_3)
		case 4: action(&_4)
		case 5: action(&_5)
		case 6: action(&_6)
		case 7: action(&_7)
		default: printError("Voxxel child index above 7."); return
		}
	}


	func childAddress(_ index: UInt32) -> VoxelAddress {
		switch index {
		case 0: return _0
		case 1: return _1
		case 2: return _2
		case 3: return _3
		case 4: return _4
		case 5: return _5
		case 6: return _6
		case 7: return _7
		default: return _p
		}
	}

	mutating func setChildAddress(_ index: UInt32, to newAddress: VoxelAddress) {
		switch index {
		case 0: _0 = newAddress
		case 1: _1 = newAddress
		case 2: _2 = newAddress
		case 3: _3 = newAddress
		case 4: _4 = newAddress
		case 5: _5 = newAddress
		case 6: _6 = newAddress
		case 7: _7 = newAddress
		default: printError("Voxeel child index above 7."); return
		}
	}

	func childrenCompleted() -> UInt32 {
		if _0.isDefault() {
			return 0
		} else if _1.isDefault() {
			return 1
		} else if _2.isDefault() {
			return 2
		} else if _3.isDefault() {
			return 3
		} else if _4.isDefault() {
			return 4
		} else if _5.isDefault() {
			return 5
		} else if _6.isDefault() {
			return 6
		} else if _7.isDefault() {
			return 7
		} else {
			return 8
		}
	}

	mutating func updateAddresses(container: VoxelContainer) {
		let _ = container.getIndex(address: &_0)
		let _ = container.getIndex(address: &_1)
		let _ = container.getIndex(address: &_2)
		let _ = container.getIndex(address: &_3)
		let _ = container.getIndex(address: &_4)
		let _ = container.getIndex(address: &_5)
		let _ = container.getIndex(address: &_6)
		let _ = container.getIndex(address: &_7)
		let _ = container.getIndex(address: &_p)
	}

	mutating func resetChildren() {
		_0 = .init()
		_1 = .init()
		_2 = .init()
		_3 = .init()
		_4 = .init()
		_5 = .init()
		_6 = .init()
		_7 = .init()
	}
}

struct VoxelAddress {
	///Index of voxel
	var index: UInt32 = 0

	///id of voxel in case index is incorrect
	var id: UInt32 = 0

	func isDefault() -> Bool {
		id == 0
	}

	init() {

	}

	init(voxel: Voxel) {
		self.id = voxel.id
	}
}
