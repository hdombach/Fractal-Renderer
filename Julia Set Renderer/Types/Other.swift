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
extension Float: sizeable {
	var double: Double {
		get {
			return Double(self)
		}
	}
	
	var cgFloat: CGFloat {
		get {
			return CGFloat(self)
		}
	}
	
	var int: Int {
		get {
			return Int(self)
		}
	}
}
extension SIMD3: sizeable { }
extension SIMD4: sizeable { }



typealias Float2 = SIMD2<Float>
typealias Float3 = SIMD3<Float>
typealias Float4 = SIMD4<Float>
typealias Int2 = SIMD2<Int>
typealias Int3 = SIMD3<Int>
typealias Int4 = SIMD4<Int>
extension Float3 {
	var color: Color {
		return .init(red: x.double, green: y.double, blue: z.double)
	}
}
extension Float2 {
	var int2: Int2 {
		get {
			return Int2(self.x.int, self.y.int)
		}
	}
}

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

extension Int {
	var int32: Int32 {
		get {
			return Int32(self)
		}
		set {
			self = Int(newValue)
		}
	}
	
	var uint32: UInt32 {
		get {
			return UInt32(self)
		}
	}
	
	var cgfloat: CGFloat {
		get {return CGFloat(self)}
	}
	
	var float: Float {
		get { return Float(self)}
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
