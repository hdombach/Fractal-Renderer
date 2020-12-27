//
//  Voxel.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 12/24/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import Foundation


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
	
	func description() -> String {
		return "Voxel. Layer: \(layer), Opacity: \(opacity), Width: \(width), isEnd: \(isEnd), parent: \(_p), children: \(_0), \(_1), \(_2), \(_3), \(_4), \(_5), \(_6), \(_7)"
	}
	
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
