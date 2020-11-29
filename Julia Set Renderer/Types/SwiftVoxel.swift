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
        loadThreads = 1
        let thread = VoxelContainerThread.init(container: self, root: 1, thread: 1)
        thread.maxLayer = 2
        
        voxels.withUnsafeMutableBufferPointer { (buffer) -> () in
            DispatchQueue.global().sync {
                //thread.pass(length: 100, voxelBuffer: buffer)
            }
            thread.pass(length: 1000, voxelBuffer: buffer)
        }
        
        loadThreads = 4
        
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

class VoxelContainerThread {
	
	struct ActiveItem: Equatable {
		var isEdge: Bool
		var position: SIMD3<Float>
		
		init(position: SIMD3<Float>, isEdge edge: Bool = false) {
			self.isEdge = edge
			self.position = position
		}
		
		static func == (lhs: Self, rhs: Self) -> Bool {
			return lhs.position == rhs.position
		}
	}
	
    var container: VoxelContainer
    var activeAddress: VoxelAddress
    var deletedIndexes: [Int] = []
    var rootVoxel: VoxelAddress
    var isDone: Bool = false
    var maxLayer = 12
    var smallStep: Float
    var activatedVoxels: [ActiveItem] = []
	
	var voxelsMade: UInt = 0
	
	var isNewMethod: Bool = false
    
    
    private var containerThreads: Int
    var thread: Int
    private var id: UInt32
    
    init(container: VoxelContainer, root: VoxelAddress, thread: Int) {
        self.container = container
        self.thread = thread
        self.containerThreads = container.loadThreads
        self.id = UInt32(thread) + UInt32(container.voxelCount)
        self.rootVoxel = root
        
        smallStep = pow(0.5, Float(maxLayer + 1))
        activeAddress = rootVoxel
    }
    
    func reset(root: Int) {
        isDone = false
        self.rootVoxel = root
        activeAddress = root
    }
    
    /*func getIndex(address: VoxelAddress, voxelBuffer: UnsafeMutableBufferPointer<Voxel>) -> Int {
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
    }*/
    
    func voxelSize(index: Int, voxelBuffer: UnsafeMutableBufferPointer<Voxel>) -> Float {
        let width = pow(0.5, Float(voxelBuffer[index].layer + 1))
        let position = voxelBuffer[index].position
        var voxelSize = (Engine.Settings.savedCamera.cameraDepth * width / distance(Engine.Settings.savedCamera.position, SIMD4<Float>(position, 0))) / Engine.Settings.savedCamera.zoom
        if 0 > dot(SIMD4<Float>(0, 0, 1, 0) * Engine.Settings.savedCamera.rotateMatrix, SIMD4<Float>(position, 0) - Engine.Settings.savedCamera.position) {
            voxelSize = voxelSize / 2
        }
        return voxelSize
    }
    
    func layerDepth(position: SIMD3<Float>) -> Int {
        var depth = Int(ceil(container.loadQuality * distance(Engine.Settings.savedCamera.position, SIMD4<Float>(position, 0)) * Engine.Settings.savedCamera.zoom / Engine.Settings.savedCamera.cameraDepth))
        if depth > maxLayer {
            depth = maxLayer
        }
        return depth
    }
    
    func voxelChildOffset(index: Float) -> SIMD3<Float> {
        let z = floor(index / 4)
        let y = floor(fmod(index, 4) / 2)
        let x = fmod(index, 2)

        return .init(x, y, z)
    }
    
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
    
    func voxelChildId(voxel: VoxelAddress, position: SIMD3<Float>, voxelBuffer: UnsafeMutableBufferPointer<Voxel>) -> Int {
        let voxel = voxelBuffer[voxel]
        var offset = (false, false, false)
        let width = voxel.width / 2
        offset.0 = position.x >= voxel.position.x + width
        offset.1 = position.y >= voxel.position.y + width
        offset.2 = position.z >= voxel.position.z + width
        return voxelChildId(position: offset)
    }
    
    func voxelChildIndex(voxel: VoxelAddress, position: SIMD3<Float>, voxelBuffer: UnsafeMutableBufferPointer<Voxel>) -> VoxelAddress {
        return voxelBuffer[voxel].childAddress(voxelChildId(voxel: voxel, position: position, voxelBuffer: voxelBuffer))
    }
    
    func voxelAtPoint(rootVoxel: VoxelAddress, position: SIMD3<Float>, voxelBuffer: UnsafeMutableBufferPointer<Voxel>) -> VoxelAddress {
        var currentVoxel = rootVoxel
        while (!voxelBuffer[currentVoxel].isEnd) {
            currentVoxel = voxelChildIndex(voxel: currentVoxel, position: position, voxelBuffer: voxelBuffer)
        }
        return currentVoxel
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
    
    func activateVoxel(position: SIMD3<Float>) {
        if activatedVoxels.contains(ActiveItem(position: position)) {
            activatedVoxels.append(ActiveItem(position: position))
        }
    }
    
    //return new Voxel and true if had to create new voxels
    func updateOpacityAtPoint(position: SIMD3<Float>, voxelBuffer: UnsafeMutableBufferPointer<Voxel>) -> (VoxelAddress, Bool) {
        let requiredLayer = layerDepth(position: position)
        var currentVoxel = voxelAtPoint(rootVoxel: rootVoxel, position: position, voxelBuffer: voxelBuffer)
        if !(voxelBuffer[currentVoxel].layer < requiredLayer) {
            return (currentVoxel, false)
        }
        while voxelBuffer[currentVoxel].layer < requiredLayer {
            divideVoxel(index: currentVoxel, voxelBuffer: voxelBuffer)
            currentVoxel = voxelChildIndex(voxel: currentVoxel, position: position, voxelBuffer: voxelBuffer)
        }
        return (currentVoxel, true)
    }
    
    func pass(length: Int, voxelBuffer: UnsafeMutableBufferPointer<Voxel>) -> Bool {
        for _ in 1...length {
			if isNewMethod {
				if activatedVoxels.count == 0 {
					
				}
				updateNeighbor(voxelBuffer: voxelBuffer)
				if activatedVoxels.count == 0 {
					isDone = true
					return true
				}
			} else {
				update(voxelBuffer: voxelBuffer)
				if activeAddress == rootVoxel {
					if voxelBuffer[Int(rootVoxel)].childrenCompleted() == 8 {
						isDone = true
						//shrinkPing(index: rootVoxel, voxelBuffer: voxelBuffer)
						return true
					}
				}
				if activeAddress == 0 {
					isDone = true
					//shrinkPing(index: rootVoxel, voxelBuffer: voxelBuffer)
					return true
				}
			}
        }
        return false
    }
    
    //A hopefully faster update function
	
	func setUpNeighborMethod(voxelBuffer: UnsafeMutableBufferPointer<Voxel>) {
		let voxel = voxelBuffer[rootVoxel]
		
		func fillPlane(planeX: Bool, planeY: Bool, planeZ: Bool) {
			var isCameraInside = true
			let camera = Engine.Settings.savedCamera!
			if !planeX {
				if camera.position.x < voxel.position.x || camera.position.x > voxel.position.x + voxel.width {
					isCameraInside = false
				}
			}
			if !planeY {
				if camera.position.y < voxel.position.y || camera.position.y > voxel.position.y + voxel.width {
					isCameraInside = false
				}
			}
			if !planeZ {
				if camera.position.z < voxel.position.z || camera.position.z > voxel.position.z + voxel.width {
					isCameraInside = false
				}
			}
			var negativeSize: Float!
			var positiviteSize: Float!
			if isCameraInside {
				var position = SIMD3<Float>.init(planeX ? voxel.position.x : camera.position.x, planeY ? voxel.position.y : camera.position.y, planeZ ? voxel.position.z : camera.position.z)
				negativeSize = pow(Float(0.5), Float(layerDepth(position: position)))
				position += SIMD3<Float>.init(planeX ? voxel.width : 0, planeY ? voxel.width : 0, planeZ ? voxel.width : 0)
				positiviteSize = pow(Float(0.5), Float(layerDepth(position: position)))
			} else {
				
			}
		}
		
		fillPlane(planeX: true, planeY: false, planeZ: false)
		fillPlane(planeX: false, planeY: true, planeZ: false)
		fillPlane(planeX: false, planeY: false, planeZ: true)
	}
	
    func updateNeighbor(voxelBuffer: UnsafeMutableBufferPointer<Voxel>) {
        func compare(lhs: VoxelAddress, rhs: VoxelAddress) -> VoxelAddress? {
            if voxelBuffer[lhs].opacity != voxelBuffer[rhs].opacity {
                if voxelBuffer[lhs].opacity == 0 {
                    return lhs
                }
                if voxelBuffer[rhs].opacity == 0 {
                    return rhs
                }
            }
            return nil
        }
        
		//imagine a 3x3x3 grid surrounding a voxel. algorithm test outwards from the center and queues new updates based off whether theres a difference in neigbhoring voxels.
        func testNeighbors(item: ActiveItem) {
			var voxelAddress: VoxelAddress!
			if item.isEdge {
				let result = updateOpacityAtPoint(position: item.position, voxelBuffer: voxelBuffer)
				if result.1 {
					voxelAddress = voxelAtPoint(rootVoxel: rootVoxel, position: item.position, voxelBuffer: voxelBuffer)
				}
			} else {
				voxelAddress = voxelAtPoint(rootVoxel: rootVoxel, position: item.position, voxelBuffer: voxelBuffer)
			}
			let voxel = voxelBuffer[voxelAddress]
            let positive = voxel.width + smallStep
            let negative = 0 - smallStep
            
            //test two voxels and activate if different opacities (activate voxel)
            //xyz are offsets from first input false = negativeOffset, true = positiveOffset, nil = noOffset
			enum Offset {
                case negative
                case positive
                case center
				
				///swaps center with other
				func inverse(_ v: Offset) -> Offset {
					if self == .center {
						return v
					} else {
						return .center
					}
				}
				
				func isCenter() -> Bool {
					return self == .center
				}
				
				//swaps negative with positive
				func opposite() -> Offset {
					if self == .negative {
						return .positive
					} else if self == .positive {
						return .negative
					} else {
						return .center
					}
				}
            }
			
			func offsetValue(_ v: Offset) -> Float {
				switch v {
				case .negative:
					return negative
				case .positive:
					return positive
				case .center:
					return 0
				}
			}
			
			//comapre and activate node
            func av(_ nAddress: VoxelAddress, _ x: Offset, _ y: Offset, _ z: Offset) {
                let currentVoxel = voxelBuffer[nAddress]
                var position = currentVoxel.position
                let newPositive = currentVoxel.width + smallStep
                
                if x == .negative {
                    position.x += negative
                } else if x == .positive {
                    position.x += newPositive
                }
                
                if y == .negative {
                    position.y += negative
                } else if y == .positive {
                    position.y += newPositive
                }
                
                if z == .negative {
                    position.z += negative
                } else if z == .positive {
                    position.z += newPositive
                }
                
				let test = compare(lhs: voxelAddress, rhs: voxelAtPoint(rootVoxel: rootVoxel, position: position, voxelBuffer: voxelBuffer))
                if test != nil && voxelContainsPoint(voxel: rootVoxel, position: position, voxelBuffer: voxelBuffer) {
					activateVoxel(position: position)
                }
            }
            
            // updates a voxel and return true if gave a newValue
            func uv(_ x: Offset, _ y: Offset, _ z: Offset) -> (VoxelAddress, Bool) {
				
				let newX = offsetValue(x)
				let newY = offsetValue(y)
				let newZ = offsetValue(z)
				
				let neighborPositioon = item.position + SIMD3<Float>.init(newX, newY, newZ)
                return updateOpacityAtPoint(position: neighborPositioon, voxelBuffer: voxelBuffer)
            }
			
			//update and test a corner
			func uc(_ x: Offset, _ y: Offset, _ z: Offset) {
				let r = uv(x, y, z) //result
				if r.1 {
					av(r.0, x, .center, .center)
					av(r.0, .center, y, .center)
					av(r.0, .center, .center, z)
				}
			}
			
			//update and test an edge
			func ue(_ x: Offset, _ y: Offset, _ z: Offset) {
				let r = uv(x, y, z) //result
				if r.1 {
					if !x.isCenter() {
						av(r.0, x, .center, .center)
					}
					if !y.isCenter() {
						av(r.0, .center, y, .center)
					}
					if !z.isCenter() {
						av(r.0, .center, .center, z)
					}
				}
				av(r.0, x.inverse(.negative), y.inverse(.negative), z.inverse(.negative))
				av(r.0, x.inverse(.positive), y.inverse(.positive), z.inverse(.positive))
			}
			
			//update and test a face
			func uf(_ x: Offset, _ y: Offset, _ z: Offset) {
				let r = uv(x, y, z)
				if r.1 {
					av(r.0, x, y, z)
					av(r.0, x.opposite(), y.opposite(), z.opposite())
				}
				av(r.0, x.inverse(.negative), .center, .center)
				av(r.0, x.inverse(.positive), .center, .center)
				av(r.0, .center, y.inverse(.negative), .center)
				av(r.0, .center, y.inverse(.positive), .center)
				av(r.0, .center, .center, z.inverse(.negative))
				av(r.0, .center, .center, z.inverse(.positive))
			}
			
			if item.isEdge {
				av(voxelAddress, .negative, .center, .center)
				av(voxelAddress, .positive, .center, .center)
				av(voxelAddress, .center, .negative, .center)
				av(voxelAddress, .center, .positive, .center)
				av(voxelAddress, .center, .center, .negative)
				av(voxelAddress, .center, .center, .positive)
			} else {
				uc(.negative, .negative, .negative)
				uc(.positive, .negative, .negative)
				uc(.negative, .positive, .negative)
				uc(.positive, .positive, .negative)
				uc(.negative, .negative, .positive)
				uc(.positive, .negative, .positive)
				uc(.negative, .positive, .positive)
				uc(.positive, .positive, .positive)
				
				ue(.center, .negative, .negative)
				ue(.center, .positive, .negative)
				ue(.center, .negative, .positive)
				ue(.center, .positive, .positive)
				ue(.negative, .center, .negative)
				ue(.positive, .center, .negative)
				ue(.negative, .center, .positive)
				ue(.positive, .center, .positive)
				ue(.negative, .negative, .center)
				ue(.positive, .negative, .center)
				ue(.negative, .positive, .center)
				ue(.positive, .positive, .center)
				
				uf(.negative, .center, .center)
				uf(.positive, .center, .center)
				uf(.center, .negative, .center)
				uf(.center, .positive, .center)
				uf(.center, .center, .negative)
				uf(.center, .center, .positive)
			}
        }
        
		if activatedVoxels.count > 0 {
			testNeighbors(item: activatedVoxels.removeLast())
		}
        
    }
    
    func update(voxelBuffer: UnsafeMutableBufferPointer<Voxel>) {
        let index = activeAddress
        
        let childrenCompleted = voxelBuffer[index].childrenCompleted()
        
        if 8 > childrenCompleted {
            let newAddress = addVoxel(parentIndex: Int(index), childIndex: Int(childrenCompleted), voxelBuffer: voxelBuffer)
            voxelBuffer[index].setChildAddress(childrenCompleted, to: newAddress)
            voxelBuffer[Int(index)].isEnd = false
            let newVoxelIndex = newAddress
            voxelBuffer[Int(newVoxelIndex)].ap = activeAddress
            updateVoxelOpacity(index: Int(newVoxelIndex), voxelBuffer: voxelBuffer)
            if voxelSize(index: Int(newVoxelIndex), voxelBuffer: voxelBuffer) > container.loadQuality && voxelBuffer[Int(newVoxelIndex)].layer < maxLayer {
                activeAddress = newAddress
            }
        } else {
			if voxelBuffer[index].layer > voxelBuffer[rootVoxel].layer {
				shrink(index: Int(index), voxelBuffer: voxelBuffer)
			}
            activeAddress = voxelBuffer[Int(index)].ap
        }
    }
    
    func updateVoxelOpacity(index: Int, voxelBuffer: UnsafeMutableBufferPointer<Voxel>) {
        //first one is for testing purposes
        if false {
            if distance(voxelBuffer[index].position, SIMD3<Float>.init(0.5, 0.5, 0.5)) > 0.5 {
                voxelBuffer[index].opacity = 0
            } else {
                voxelBuffer[index].opacity = 1
            }
        } else {
            let position = (voxelBuffer[index].position - SIMD3<Float>.init(0.5, 0.5, 0.5)) * 3
            if Engine.JuliaSetSettings.getLinear(point: Complex(position.x, position.y), z: position.z) {
                voxelBuffer[index].opacity = 1
            } else {
                voxelBuffer[index].opacity = 0
            }
        }
    }
    
    func shrink(index: Int, voxelBuffer: UnsafeMutableBufferPointer<Voxel>) {
        let child0Address = voxelBuffer[index].childAddress(0)
        let child0Index = child0Address
        let child0 = voxelBuffer[Int(child0Index)]
        for c in 0...7 {
            let currentChildAddress = voxelBuffer[index].childAddress(c)
            let currentChildIndex = currentChildAddress
            let currentChild = voxelBuffer[Int(currentChildIndex)]
            
            if !currentChild.isEnd || currentChild.opacity != child0.opacity || currentChild.opacity == -1 {
                return
            }
        }
        removeChildren(index: index, voxelBuffer: voxelBuffer)
        
    }
    
    func shrinkPing(index: Int, voxelBuffer: UnsafeMutableBufferPointer<Voxel>) {
        for c in 0...7 {
            if !voxelBuffer[index].isEnd {
                shrinkPing(index: Int(voxelBuffer[index].childAddress(c)), voxelBuffer: voxelBuffer)
            }
        }
        shrink(index: index, voxelBuffer: voxelBuffer)
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


//MARK: Voxel
struct Voxel {
	//var id: UInt32 = 0
	var opacity: Float = 0
	var isEnd: Bool = true
	var position: SIMD3<Float> = .init(0, 0, 0)
	var layer: UInt32 = 0
	var width: Float {
		pow(0.5, Float(layer)) * 1
	}

	var _p: GPUVoxelAddress = .init()
	var _0: GPUVoxelAddress = .init()
	var _1: GPUVoxelAddress = .init()
	var _2: GPUVoxelAddress = .init()
	var _3: GPUVoxelAddress = .init()
	var _4: GPUVoxelAddress = .init()
	var _5: GPUVoxelAddress = .init()
	var _6: GPUVoxelAddress = .init()
	var _7: GPUVoxelAddress = .init()
    
    var ap: Int {
        get {
            return Int(_p)
        }
        set(newValue) {
            _p = UInt32(newValue)
        }
    }
    var a0: Int {
        get {
            return Int(_0)
        }
        set(newValue) {
            _0 = UInt32(newValue)
        }
    }
    var a1: Int {
        get {
            return Int(_1)
        }
        set(newValue) {
            _1 = UInt32(newValue)
        }
    }
    var a2: Int {
        get {
            return Int(_2)
        }
        set(newValue) {
            _2 = UInt32(newValue)
        }
    }
    var a3: Int {
        get {
            return Int(_3)
        }
        set(newValue) {
            _3 = UInt32(newValue)
        }
    }
    var a4: Int {
        get {
            return Int(_4)
        }
        set(newValue) {
            _4 = UInt32(newValue)
        }
    }
    var a5: Int {
        get {
            return Int(_5)
        }
        set(newValue) {
            _5 = UInt32(newValue)
        }
    }
    var a6: Int {
        get {
            return Int(_6)
        }
        set(newValue) {
            _6 = UInt32(newValue)
        }
    }
    var a7: Int {
        get {
            return Int(_7)
        }
        set(newValue) {
            _7 = UInt32(newValue)
        }
    }

	init() {

	}

	init(parent: Voxel, childIndex: UInt32) {
		layer = parent.layer + 1
		position = parent.position + width * getOffset(index: Float(childIndex))
	}

	private func getOffset(index: Float) -> SIMD3<Float> {
		let z = floor(index / 4)
		let y = floor(fmod(index, 4) / 2)
		let x = fmod(index, 2)

		return .init(x, y, z)
	}


	mutating func useAddress(_ index: VoxelAddress, action: (inout GPUVoxelAddress) -> ()) {
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


	func childAddress(_ id: Int) -> VoxelAddress {
		switch id {
		case 0: return a0
		case 1: return a1
		case 2: return a2
		case 3: return a3
		case 4: return a4
		case 5: return a5
		case 6: return a6
		case 7: return a7
		default: return ap
		}
	}

	mutating func setChildAddress(_ id: Int, to newAddress: VoxelAddress) {
		switch id {
		case 0: a0 = newAddress
		case 1: a1 = newAddress
		case 2: a2 = newAddress
		case 3: a3 = newAddress
		case 4: a4 = newAddress
		case 5: a5 = newAddress
		case 6: a6 = newAddress
		case 7: a7 = newAddress
		default: printError("Voxeel child index above 7."); return
		}
	}

	func childrenCompleted() -> Int {
		if _0 == 0{
			return 0
		} else if _1 == 0 {
			return 1
		} else if _2 == 0 {
			return 2
		} else if _3 == 0 {
			return 3
		} else if _4 == 0 {
			return 4
		} else if _5 == 0 {
			return 5
		} else if _6 == 0 {
			return 6
		} else if _7 == 0 {
			return 7
		} else {
			return 8
		}
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

typealias GPUVoxelAddress = UInt32

typealias VoxelAddress = Int
