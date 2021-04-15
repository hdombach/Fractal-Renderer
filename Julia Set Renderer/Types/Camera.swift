//
//  Camera.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 3/10/21.
//  Copyright © 2021 Hezekiah Dombach. All rights reserved.
//

import simd
import Foundation
import SwiftUI

struct Camera: Equatable, Codable {
	var position: SIMD4<Float>
	var horizontal: SIMD4<Float> = .init()
	var vertical: SIMD4<Float> = .init()
	var u: SIMD4<Float> = .init()
	var v: SIMD4<Float> = .init()
	var w: SIMD4<Float> = .init()
	var lensRadius: Float
	
	var vfov: Float {
		didSet {
			updateRotationMatrix()
		}
	}
	var focusDistance: Float {
		didSet {
			updateRotationMatrix()
		}
	}
	var resolution: SIMD2<Float>
	var quaternionVec: SIMD4<Float> = simd_quatf(angle: 0, axis: Float3(0, 1, 0)).vector
	var quaternion: simd_quatf {
		get {
			return simd_quatf(vector: quaternionVec)
		}
		
		set {
			quaternionVec = newValue.vector
		}
	}
	
	init(position: Float4 = .init(0, 0.0001, -2, 0), lensRadius: Float = 0, vfov: Float = 30, focusDistance: Float = 1, resolution: SIMD2<Float> = .init(1920, 1080), setup: Bool = true) {
		self.position = position
		self.lensRadius = lensRadius
		self.vfov = vfov
		self.focusDistance = focusDistance
		self.resolution = resolution
		
		if (setup) {
			updateRotationMatrix()
		}
	}
	
	var transformMatrix: simd_float4x4 {
		get {
			return simd_float4x4.init(quaternion)
		}
	}
	
	mutating func rotate(deltaX: Float, deltaY: Float) {
		let rotationStart = Float3(0, 0, 1)
		var rotationEnd = Float3(deltaX, deltaY, 1)
		rotationEnd = normalize(rotationEnd)
		
		let angle = acos(dot(rotationStart, rotationEnd))
		
		let rotationAxis = normalize(cross(rotationStart, rotationEnd))
		
		if (!rotationAxis.x.isNaN) {
		
			let rotationQuat = simd_quatf.init(angle: angle, axis: rotationAxis)
			
			quaternion = (quaternion * rotationQuat).normalized
			
			updateRotationMatrix()
		}
	}
	
	mutating func updateRotationMatrix() {
		let matrix = transformMatrix
		
		u = matrix * Float4(1, 0, 0, 0)
		v = matrix * Float4(0, 1, 0, 0)
		w = matrix * Float4(0, 0, 1, 0)
		
		let height: Float = tan(vfov * Float.pi / 360) * 2
		let width = height * resolution.x / resolution.y
		
		horizontal = focusDistance * width * u
		vertical = focusDistance * height * v
		
		//print(u, v)
	}
}
