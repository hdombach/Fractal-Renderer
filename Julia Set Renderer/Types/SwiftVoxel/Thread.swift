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
    var activeAddress: VoxelAddress = 0
    var deletedIndexes: [Int] = []
    var rootVoxel: VoxelAddress = 0
    var isDone: Bool = false
    var maxLayer = 12
    var smallStep: Float
    var activatedVoxels: [ActiveItem] = []
	var shouldShrink = true
	
	var voxelsMade: UInt = 0
	
	var isNewMethod: Bool = true
    
    
	var containerThreads: Int
    var thread: Int
	var id: UInt32
    
	init(container: VoxelContainer, root: VoxelAddress, thread: Int, shouldShrink: Bool = true) {
        self.container = container
        self.thread = thread
        self.containerThreads = container.loadThreads
        self.id = UInt32(thread) + UInt32(container.voxelCount)
		smallStep = pow(0.5, Float(maxLayer + 1))
		
		reset(root: root, shouldShrink: shouldShrink)
    }
    
	func reset(root: Int, shouldShrink: Bool = true) {
        isDone = false
        self.rootVoxel = root
        activeAddress = root
		self.shouldShrink = shouldShrink
		//print(root)
		
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
			if Engine.Settings.juliaSetSettings.quickMode {
				if activatedVoxels.count == 0 {
					
				}
				updateNeighbor(voxelBuffer: voxelBuffer)
				if activatedVoxels.count == 0 {
					isDone = true
					return true
				}
			} else {
				//old method
				update(voxelBuffer: voxelBuffer)
				if activeAddress == rootVoxel {
					if voxelBuffer[Int(rootVoxel)].childrenCompleted() == 8 {
						isDone = true
						if shouldShrink {
							shrinkPing(index: rootVoxel, voxelBuffer: voxelBuffer, depth: 0)
						}
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
    
	//MARK: New Method
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
    
	//MARK: Old Method
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
			if voxelBuffer[index].layer > voxelBuffer[rootVoxel].layer && shouldShrink {
				shrink(index: Int(index), voxelBuffer: voxelBuffer)
			}
			//print(index, voxelBuffer[index].description())
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
    
    func shrink(index: Int, voxelBuffer: UnsafeMutableBufferPointer<Voxel>) -> Bool {
		if voxelBuffer[index].isEnd {
			return false
		}
        let child0Address = voxelBuffer[index].childAddress(0)
        let child0Index = child0Address
        let child0 = voxelBuffer[Int(child0Index)]
        for c in 0...7 {
            let currentChildAddress = voxelBuffer[index].childAddress(c)
            let currentChildIndex = currentChildAddress
            let currentChild = voxelBuffer[Int(currentChildIndex)]
            
            if !currentChild.isEnd || currentChild.opacity != child0.opacity || currentChild.opacity == -1 {
                return false
            }
        }
        removeChildren(index: index, voxelBuffer: voxelBuffer)
        return true
    }
    
	func shrinkPing(index: Int, voxelBuffer: UnsafeMutableBufferPointer<Voxel>, depth: Int) {
		if index != 0 && 10 > depth {
			//print(depth, index, voxelBuffer[index].description())
			if !voxelBuffer[index].isEnd {
				for c in 0...7 {
					shrinkPing(index: Int(voxelBuffer[index].childAddress(c)), voxelBuffer: voxelBuffer, depth: depth + 1)
				}
			}
			if voxelBuffer[index].layer > container.startingsLayer {
				if shrink(index: index, voxelBuffer: voxelBuffer) {
					print("deleted \(index), \(voxelBuffer[index].description())")
				}
			}
			return
		}
    }
    
}
