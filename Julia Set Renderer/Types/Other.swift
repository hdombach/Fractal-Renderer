//
//  Types.swift
//  Game Engine
//
//  Created by Hezekiah Dombach on 5/23/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import simd
import Foundation

func printError(_ message: String) {
	let date = Date()
	let calendar = Calendar.current
	let hour = calendar.component(.hour, from: date)
	let minute = calendar.component(.minute, from: date)
	let second = calendar.component(.second, from: date)
	let nanosecond = calendar.component(.nanosecond, from: date)
	print("ERROR \(hour):\(minute):\(second).\(nanosecond), \(message)")
}

protocol sizeable {
	static func size(_ count: Int) -> Int
	static func stride(_ count: Int) -> Int
}

extension sizeable {
	static var size: Int {
		return MemoryLayout<Self>.size
	}
	static var stride: Int {
		return MemoryLayout<Self>.stride
	}
	static func size(_ count: Int) -> Int {
		return MemoryLayout<Self>.size * count
	}
	static func stride(_ count: Int) -> Int {
		return MemoryLayout<Self>.stride * count
	}
}
extension Float: sizeable { }
extension SIMD3: sizeable { }
extension SIMD4: sizeable { }


struct Vertex: sizeable {
	var position: SIMD4<Float>
	var color: SIMD4<Float>
	var texCoord: SIMD2<Float>
}

struct Camera: Equatable {
	var position: SIMD4<Float>
	var deriction: SIMD4<Float> {
		didSet {
			self.updateRotationMatrix()
		}
	}
	///
	var zoom: Float
	var cameraDepth: Float
	var rotateMatrix: matrix_float4x4
	var resolution: SIMD2<Float>

	mutating func pointInDeriction(angle: SIMD4<Float>) {
		deriction = angle
		var transformMatrix = matrix_identity_float4x4
		transformMatrix.rotate(angle: deriction)
		rotateMatrix = transformMatrix
	}

	mutating func updateRotationMatrix() {
		var transformMatrix = matrix_identity_float4x4
		transformMatrix.rotate(angle: deriction)
		rotateMatrix = transformMatrix
	}
}
