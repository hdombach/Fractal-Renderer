//
//  Types.swift
//  Game Engine
//
//  Created by Hezekiah Dombach on 5/23/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import simd
import Foundation
import SwiftUI

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

typealias Float3 = SIMD3<Float>

extension CGPoint {
	static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
		return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
	}
	static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
		return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
	}
	func scale(_ factor: CGFloat) -> CGPoint {
		return CGPoint(x: self.x * factor, y: self.y * factor)
	}
	func distanceTo(point: CGPoint) -> CGFloat {
		return sqrt((point.x - x) * (point.x - x) + (point.y - y) * (point.y - y))
	}
}

extension CGRect {
	var midPoint: CGPoint {
		get {
			return CGPoint(x: self.midX, y: self.midY)
		}
	}
}

extension SIMD4 {
	var xyz: SIMD3<Scalar> {
		get {
			return SIMD3.init(self.x, self.y, self.z)
		}
		set { (newValue)
			self.x = newValue.x
			self.y = newValue.y
			self.z = newValue.z
		}
	}
}


struct Vertex: sizeable {
	var position: SIMD4<Float>
	var color: SIMD4<Float>
	var texCoord: SIMD2<Float>
}

struct Camera: Equatable {
	var position: SIMD4<Float> = .init()
	var deriction: SIMD4<Float>  = .init() {
		didSet {
			self.updateRotationMatrix()
		}
	}
	///
	var zoom: Float = .init()
	var cameraDepth: Float = .init()
	var rotateMatrix: matrix_float4x4 = .init()
	var resolution: SIMD2<Float> = .init()

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
