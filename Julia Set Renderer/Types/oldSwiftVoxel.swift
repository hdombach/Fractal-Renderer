//
//  Swift Voxel.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 8/19/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import Foundation
import simd


/*struct old_jSetQueueItem {
	var position: SIMD3<Float>
	var currentLayer: Int32
	var finalSize: Float
	var voxelIndex: Int32
	var voxelSegmentLength: Int32
	var voxel: old_LoadVoxel
}


class old_VoxelContainer {
	var voxels: [old_Voxel] = []
	var queueVoxels: [old_Voxel] = []
	var queue: [old_jSetQueueItem] = []
	var root: old_LoadVoxel = old_LoadVoxel()
	let queueLimit = 100
	var isQueueOpen: Bool {
		return queueLimit > queue.count
	}
	var activeVoxel: (old_LoadVoxel, UInt, Float)?
	//var yeet = Yeet()

	//mutating func load()

	//Voxel Loading Life cycle
	//Backtrack with voxels from compute shader
	//Contintue with last loaded voxel while adding todo
	//Set off another compute shader

	func updateFromQueue() {
		/*if let qBuffer = Engine.QueueBuffer, let qvBuffer = Engine.QueueVoxelBuffer, queue.count > 0 {
			let queueBuffer = UnsafeBufferPointer.init(start: qBuffer.contents().bindMemory(to: old_jSetQueueItem.self, capacity: queue.count), count: queue.count)
			let queueVoxelBuffer = UnsafeBufferPointer.init(start: qvBuffer.contents().bindMemory(to: old_Voxel.self, capacity: queueVoxels.count), count: queueVoxels.count)

			for c in 0...queue.count - 1 {
				queue[c].voxel.loadFromQueue(index: Int(queueBuffer[c].voxelIndex), voxelBuffer: queueVoxelBuffer)
			}

			queue.removeAll()
			queueVoxels.removeAll()
		}*/
	}

	func loadPattern(size: Float) {
		root = old_LoadVoxel()
		queue.removeAll()
		queueVoxels.removeAll()
		voxels.removeAll()
		activeVoxel = (root, 0, size)
		//root.addJuliaSet(currentSize: 0, finalSize: size, container: self, progressTracker: { })
	}
	func continueLoading() {
		while activeVoxel != nil && isQueueOpen {
			activeVoxel?.0.addJuliaSet(currentLayer: activeVoxel!.1, finalSize: activeVoxel!.2, container: self, progressTracker: { })
		}
	}

	func loadIntoVoxelBuffer() {
		self.voxels.removeAll()
		voxels.append(old_Voxel.init(opacity: 0, isEnd: true, _0: 0, _1: 0, _2: 0, _3: 0, _4: 0, _5: 0, _6: 0, _7: 0))
		addVoxel(voxel: root)
	}

	func addVoxel(voxel: old_LoadVoxel) -> UInt {
		let index = UInt(voxels.count)
		voxel.index = index

		var newVoxel = old_Voxel()
		newVoxel.opacity = voxel.opacity
		if voxel.children[0] == nil {
			newVoxel.isEnd = true
			voxels.append(newVoxel)
		} else {
			newVoxel.isEnd = false
			voxels.append(newVoxel)
			for childNumber in 0...(voxel.children.count - 1) {
				if voxel.children[childNumber] != nil {
					let childIndex = self.addVoxel(voxel: voxel.children[childNumber]!)
					voxels[Int(index)].setChild(childNumber, to: UInt32(childIndex))
				}
			}
		}

		return index
	}
}

struct Yeet {
	func doStuff() -> Bool {
		return true
	}
}

class old_LoadVoxel: Equatable {
	static func == (lhs: old_LoadVoxel, rhs: old_LoadVoxel) -> Bool {
		return lhs.id == rhs.id
	}

	weak var parent: old_LoadVoxel?
	var id = Float.random(in: -10000...10000)
	var children: [old_LoadVoxel?] = Array.init(repeating: nil, count: 8)
	var index: UInt?
	var opacity: Float = -1
	var isRoot: Bool = true
	var position: SIMD3<Float> = .init(0, 0, 0)
	var childrenCompleted: Int = 0
	var getIndexInParent: Int {
		if parent == nil {
			return 0
		}  else {
			return parent!.children.firstIndex(where: { (voxel) -> Bool in
				return voxel == self
			})!
		}
	}

	func updateOpacity(_ newOpacity: Float) {
		opacity = newOpacity
		parent?.shrink()
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

	func shrink() {
		if !children.contains(nil) {
			for child in children {
				if child!.opacity == -1 || !child!.isRoot || child?.opacity != children[0]!.opacity {
					return
				}
			}
			opacity = children[0]!.opacity
			deleteChildren()
			parent?.shrink()
		}
	}

	func addToQueue(currentLayer: Int, finalSize: Float, container: old_VoxelContainer) {
		let queueItem = old_jSetQueueItem.init(position: position, currentLayer: Int32(currentLayer), finalSize: finalSize, voxelIndex: Int32(container.queueVoxels.count), voxelSegmentLength: 0, voxel: self)
		container.queue.append(queueItem)

		//This will be inaccurate if camera is inside.
		let size = getVoxelSize(position: position, size: currentLayer, width: nil)
		let levels = Int(log2(size / finalSize))

		let startIndex = container.queueVoxels.count
		var currentIndex: Int = 0
		var segmentLength: Int = 1
		for level in 0...levels {
			for _ in 1...Int(pow(8, Float(level))) {
				let voxelIndex = startIndex + currentIndex
				container.queueVoxels.append(old_Voxel())
				if level == levels {
					container.queueVoxels[voxelIndex].isEnd = true
				} else {
					for child in 0...7 {
						let childIndex = startIndex + currentIndex * 8 + child + 1
						container.queueVoxels[voxelIndex].setChild(child, to: UInt32(childIndex))
						segmentLength += 1
					}
				}
				currentIndex += 1
			}
		}
		container.queue[container.queue.count - 1].voxelSegmentLength = Int32(segmentLength)
	}

	func loadFromQueue(index: Int, voxelBuffer: UnsafeBufferPointer<old_Voxel>) {
		let voxel = voxelBuffer[index]
		if voxel.isEnd {
			self.opacity = voxel.opacity
		} else {
			for childIndex in 0...7 {
				let newVoxel = old_LoadVoxel()
				self.addChild(voxel: newVoxel, position: childIndex)
				newVoxel.loadFromQueue(index: Int(voxel.child(childIndex)), voxelBuffer: voxelBuffer)
			}
		}
	}

	//This function needs to be able to restart from anywhere inside it.
	//Needs to be able to activate both its children and parent

	func addJuliaSet(currentLayer: UInt, finalSize: Float, container: old_VoxelContainer, progressTracker: () -> ()) {
		if !container.isQueueOpen {//Happens when the queue for compute function is full and so the loading process pauses until the next frame
			container.activeVoxel = (self, currentLayer, finalSize)
			return
		}
		if childrenCompleted > 7 { //If this voxel is done then everything below it is done and so it tells its parent to finish
			if parent == nil {
				container.activeVoxel = nil
				return
			}
			container.activeVoxel = (parent!, currentLayer - 1, finalSize)
			//parent?.addJuliaSet(currentSize: currentSize - 1, finalSize: finalSize, container: container, progressTracker: progressTracker)
			return
		}

		let width = pow(0.5, Float(currentLayer + 1))
		let newVoxel = old_LoadVoxel()

		let z: Float = floor(Float(childrenCompleted) / 4)
		let y: Float = floor(fmod(Float(childrenCompleted), 4) / 2)
		let x: Float = fmod(Float(childrenCompleted), 2)

		newVoxel.position.x = self.position.x + width * x
		newVoxel.position.y = self.position.y + width * y
		newVoxel.position.z = self.position.z + width * z

		self.addChild(voxel: newVoxel, position: childrenCompleted)

		childrenCompleted += 1

		let voxelSize = getVoxelSize(position: newVoxel.position, size: Int(currentLayer), width: width)

		//print(container.queue.count)

		if finalSize * 8 < voxelSize && currentLayer < 16 {//Makes the newly created voxel active
			//print(currentSize)
			container.activeVoxel = (newVoxel, currentLayer + 1, finalSize)
			return
			//newVoxel.addJuliaSet(currentSize: currentSize + 1, finalSize: finalSize, container: container, progressTracker: progressTracker)
		} else {//Adds a root child to queue and the reactivates itself
			//container.queue.append(.init(position: newVoxel.position, voxel: newVoxel))
			//MARK: Add to Queue
			addToQueue(currentLayer: Int(currentLayer), finalSize: finalSize, container: container)
			container.activeVoxel = (self, currentLayer, finalSize)
			return
			//self.addJuliaSet(currentSize: currentSize, finalSize: finalSize, container: container, progressTracker: progressTracker)
		}
	}

	func addRandomChildren(currentSize: UInt, finalSize: UInt) {
		for c in 0...7 {
			let newVoxel = old_LoadVoxel()
			newVoxel.opacity = Float.random(in: 0...1)
			addChild(voxel: newVoxel, position: c)
			if finalSize > currentSize {
				newVoxel.addRandomChildren(currentSize: currentSize + 1, finalSize: finalSize)
			}
		}
	}

	func getColorAt(position: SIMD3<Float>) -> Float {
		return Float(Int.random(in: 0...1))
	}

	func addChild(voxel: old_LoadVoxel, position: Int) {
		children[position] = voxel
		voxel.parent = self
		self.isRoot = false
	}

	func deleteChildren() {
		for c in 0..<children.count {
			//children[c]?.parent = nil
			children[c]?.deleteChildren()
			children[c] = nil
		}
		self.isRoot = true
	}
}


struct old_Voxel {
	//var children = UnsafeMutableBufferPointer<UInt>.allocate(capacity: 8)
	//var children: [UInt] = Array.init(repeating: 0, count: 8)
	var opacity: Float = 0
	var isEnd: Bool = false

	var _0: UInt32 = 0
	var _1: UInt32 = 0
	var _2: UInt32 = 0
	var _3: UInt32 = 0
	var _4: UInt32 = 0
	var _5: UInt32 = 0
	var _6: UInt32 = 0
	var _7: UInt32 = 0

	func child(_ number: Int) -> UInt32 {
		switch number {
		case 0:
			return _0
		case 1:
			return _1
		case 2:
			return _2
		case 3:
			return _3
		case 4:
			return _4
		case 5:
			return _5
		case 6:
			return _6
		case 7:
			return _7
		default:
			printError("Voxel Child index above 7")
			return 0
		}
	}

	mutating func setChild(_ number: Int, to newNumber: UInt32) {
		switch number {
		case 0:
			_0 = newNumber
		case 1:
			_1 = newNumber
		case 2:
			_2 = newNumber
		case 3:
			_3 = newNumber
		case 4:
			_4 = newNumber
		case 5:
			_5 = newNumber
		case 6:
			_6 = newNumber
		case 7:
			_7 = newNumber
		default:
			return;
		}
	}
}
*/
