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
	private var voxels: [Voxel] = []
    var loadQuality: Float = 10
    var loadThreads: Int = 4
    var threads: [VoxelContainerThread] = []
    var voxelCount: Int = 0
    var isComplete = false
    var threadQueue: [VoxelAddress] = []
    
    var containerSemaphore = DispatchSemaphore.init(value: 1)
    var containerQueue: DispatchQueue = .init(label: "Append Thread")
    
    func addVoxel() -> Int {
        var index: Int!
        containerQueue.sync {
            index = voxelCount
            voxelCount += 1
        }
        return index
    }

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
        containerSemaphore = DispatchSemaphore.init(value: 1)
		voxels.removeAll()
        threadQueue.removeAll()
		voxels.append(Voxel.init())
		voxels[0].isEnd = true
		voxels[0].isDeleted = false
		voxels[0].opacity = -1
        
        isComplete = false
        
        voxels += Array.init(repeating: Voxel.init(), count: 9)
        
        voxels[1].id = 1
        
        voxelCount = 2
        loadThreads = 1
        let thread = VoxelContainerThread.init(container: self, root: VoxelAddress.init(index: 1, id: 1), thread: 1)
        thread.maxLayer = 1
        
        voxels.withUnsafeMutableBufferPointer { (buffer) -> () in
            DispatchQueue.global().sync {
                //thread.pass(length: 100, voxelBuffer: buffer)
            }
            thread.pass(length: 100, voxelBuffer: buffer)
        }
        
        loadThreads = 4
        
        threads.removeAll()
        for c in UInt32(2)...9 {
            threadQueue.append(VoxelAddress.init(index: c, id: voxels[Int(c)].id))
        }
        threadQueue.sort { (closer, farther) -> Bool in
            let position = Engine.Settings.camera.position
            let closerDistance = distance(position, SIMD4<Float>(voxels[Int(closer.index)].position, 1))
            let fartherDistance = distance(position, SIMD4<Float>(voxels[Int(farther.index)].position, 1))
            return closerDistance < fartherDistance
        }
        
        for c in 0...loadThreads - 1 {
            threads.append(VoxelContainerThread.init(container: self, root: threadQueue[0], thread: c))
            threadQueue.removeFirst()
        }
        
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
            print("load finished. \(self.voxels.count) voxels in \(deltaTime) seconds. \(Double(voxels.count) / deltaTime) voxels/second")
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
                threads[c] = VoxelContainerThread.init(container: self, root: threadQueue.first!, thread: threads[c].thread)
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

class VoxelContainerThread {
    var container: VoxelContainer
    var activeAddress: VoxelAddress
    var deletedIndexes: [Int] = []
    let rootVoxel: VoxelAddress
    var isDone: Bool = false
    var maxLayer = 12
    
    private var containerThreads: Int
    var thread: Int
    private var id: UInt32
    
    init(container: VoxelContainer, root: VoxelAddress, thread: Int) {
        self.container = container
        self.thread = thread
        self.containerThreads = container.loadThreads
        self.id = UInt32(thread) + UInt32(container.voxelCount)
        self.rootVoxel = root
        
        activeAddress = rootVoxel
        
    }
    
    func getIndex(address: VoxelAddress, voxelBuffer: UnsafeMutableBufferPointer<Voxel>) -> Int {
        if container.voxelCount <= address.index || voxelBuffer[Int(address.index)].id != address.id {
            printError("Incorrect address index")
            for c in 0...container.voxelCount - 1 {
                let diff = (c % 2) * 2 - 1
                var newIndex = (Int(ceil(Float(c) / 2)) * diff + Int(address.index)) % container.voxelCount
                if 0 > newIndex {
                    newIndex += container.voxelCount
                }
                if voxelBuffer[newIndex].id == address.id {
                    return newIndex
                }
            }
            return 0
        }
        return Int(address.index)
    }
    
    func voxelSize(index: Int, voxelBuffer: UnsafeMutableBufferPointer<Voxel>) -> Float {
        let width = pow(0.5, Float(voxelBuffer[index].layer + 1))
        let position = voxelBuffer[index].position
        var voxelSize = (Engine.Settings.savedCamera.cameraDepth * width / distance(Engine.Settings.savedCamera.position, SIMD4<Float>(position, 0))) / Engine.Settings.savedCamera.zoom
        if 0 > dot(SIMD4<Float>(0, 0, 1, 0) * Engine.Settings.savedCamera.rotateMatrix, SIMD4<Float>(position, 0) - Engine.Settings.savedCamera.position) {
            voxelSize = voxelSize / 2
        }
        return voxelSize
    }
    
    func voxelChildOffset(index: Float) -> SIMD3<Float> {
        let z = floor(index / 4)
        let y = floor(fmod(index, 4) / 2)
        let x = fmod(index, 2)

        return .init(x, y, z)
    }
    
    func pass(length: Int, voxelBuffer: UnsafeMutableBufferPointer<Voxel>) -> Bool {
        for _ in 1...length {
            update(voxelBuffer: voxelBuffer)
            if activeAddress == rootVoxel {
                if voxelBuffer[Int(rootVoxel.index)].childrenCompleted() == 8 {
                    isDone = true
                    return true
                }
            }
            if activeAddress.id == 0 {
                isDone = true
                return true
            }
        }
        return false
    }
    
    func update(voxelBuffer: UnsafeMutableBufferPointer<Voxel>) {
        let index = getIndex(address: activeAddress, voxelBuffer: voxelBuffer)
        
        let childrenCompleted = voxelBuffer[index].childrenCompleted()
        
        if 8 > childrenCompleted {
            let newAddress = addVoxel(parentIndex: index, childIndex: Int(childrenCompleted), voxelBuffer: voxelBuffer)
            voxelBuffer[index].setChildAddress(UInt32(childrenCompleted), to: newAddress)
            voxelBuffer[index].isEnd = false
            let newVoxelIndex = getIndex(address: newAddress, voxelBuffer: voxelBuffer)
            voxelBuffer[newVoxelIndex]._p = activeAddress
            updateVoxelOpacity(index: newVoxelIndex, voxelBuffer: voxelBuffer)
            if voxelSize(index: newVoxelIndex, voxelBuffer: voxelBuffer) > container.loadQuality * 2 && voxelBuffer[newVoxelIndex].layer < maxLayer {
                activeAddress = newAddress
            }
        } else {
            shrink(index: index, voxelBuffer: voxelBuffer)
            activeAddress = voxelBuffer[index]._p
        }
    }
    
    func updateVoxelOpacity(index: Int, voxelBuffer: UnsafeMutableBufferPointer<Voxel>) {
        /*if distance(voxelBuffer[index].position, SIMD3<Float>.init(0.5, 0.5, 0.5)) > 0.5 {
            voxelBuffer[index].opacity = 0
        } else {
            voxelBuffer[index].opacity = 1
        }*/
        let position = (voxelBuffer[index].position - SIMD3<Float>.init(0.5, 0.5, 0.5)) * 3
        if Engine.JuliaSetSettings.getLinear(point: Complex(position.x, position.y), z: position.z) {
            voxelBuffer[index].opacity = 1
        } else {
            voxelBuffer[index].opacity = 0
        }
    }
    
    func shrink(index: Int, voxelBuffer: UnsafeMutableBufferPointer<Voxel>) {
        let child0Address = voxelBuffer[index].childAddress(0)
        let child0Index = getIndex(address: child0Address, voxelBuffer: voxelBuffer)
        let child0 = voxelBuffer[child0Index]
        for c in UInt32(0)...7 {
            let currentChildAddress = voxelBuffer[index].childAddress(c)
            let currentChildIndex = getIndex(address: currentChildAddress, voxelBuffer: voxelBuffer)
            let currentChild = voxelBuffer[currentChildIndex]
            
            if !currentChild.isEnd || currentChild.opacity != child0.opacity || currentChild.opacity == -1 {
                return
            }
        }
        removeChildren(index: index, voxelBuffer: voxelBuffer)
        
    }
    
    func removeChildren(index: Int, voxelBuffer: UnsafeMutableBufferPointer<Voxel>) {
        for c in UInt32(0)...7 {
            removeChild(index: index, child: c, voxelBuffer: voxelBuffer)
        }
        voxelBuffer[index].isEnd = true
    }
    func removeChild(index: Int, child: UInt32, voxelBuffer: UnsafeMutableBufferPointer<Voxel>) {
        let childIndex = voxelBuffer[index].childAddress(child)
        deletedIndexes.append(getIndex(address: childIndex, voxelBuffer: voxelBuffer))
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
        returnAddress.index = UInt32(index!)
        voxelBuffer[index].id = self.id
        returnAddress.id = self.id
        self.id += UInt32(containerThreads)
        
        if parentIndex > 0 {
            let parent = voxelBuffer[parentIndex]
            
            voxelBuffer[index]._p.index = UInt32(parentIndex)
            voxelBuffer[index]._p.id = parent.id
            voxelBuffer[index].layer = parent.layer + 1
            voxelBuffer[index].position = parent.position + voxelBuffer[index].width * voxelChildOffset(index: Float(childIndex))
        }
        
        
        return returnAddress
    }
    
    
    
}

struct Voxel {
	var id: UInt32 = 0
	var opacity: Float = 0
	var isEnd: Bool = true
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

	init(parent: Voxel, childIndex: UInt32) {
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
    
    static func == (lhs: VoxelAddress, rhs: VoxelAddress) -> Bool {
        return lhs.id == rhs.index
    }

	init() {

	}

	init(voxel: Voxel) {
		self.id = voxel.id
	}
    
    init(index: UInt32, id: UInt32) {
        self.index = index
        self.id = id
    }
}
