//
//  matrixTransformations.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 7/5/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import MetalKit

extension matrix_float4x4 {
	mutating func translate(direction: SIMD3<Float>) {
		var result = matrix_identity_float4x4

		let x: Float = direction.x
		let y: Float = direction.y
		let z: Float = direction.z

		result.columns = (
			SIMD4<Float>(1, 0, 0, 0),
			SIMD4<Float>(0, 1, 0, 0),
			SIMD4<Float>(0, 0, 1, 0),
			SIMD4<Float>(x, y, z, 1)
		)

		self = matrix_multiply(self, result)
	}

	mutating func scale(axis: SIMD3<Float>) {
		var result = matrix_identity_float4x4

		let x: Float = axis.x
		let y: Float = axis.y
		let z: Float = axis.z

		result.columns = (
			SIMD4<Float>(x, 0, 0, 0),
			SIMD4<Float>(0, y, 0, 0),
			SIMD4<Float>(0, 0, z, 0),
			SIMD4<Float>(0, 0, 0, 1)
		)

		self = matrix_multiply(self, result)
	}

	mutating func rotate(angle: SIMD4<Float>) {
		var yaw = matrix_identity_float4x4 // z
		var pitch = matrix_identity_float4x4 // y
		var roll = matrix_identity_float4x4 // x

		let a = angle.z
		let b = angle.y
		let c = angle.x

		yaw.columns = (
			SIMD4<Float>(cos(a), 	-sin(a), 	0,			0),
			SIMD4<Float>(sin(a),	cos(a), 	0,			0),
			SIMD4<Float>(0, 		0, 			1,			0),
			SIMD4<Float>(0, 		0, 			0,			1)
		)

		pitch.columns = (
			SIMD4<Float>(cos(b), 	0, 			sin(b),		0),
			SIMD4<Float>(0,			1, 			0,			0),
			SIMD4<Float>(-sin(b), 	0, 			cos(b),		0),
			SIMD4<Float>(0, 		0, 			0,			1)
		)
		roll.columns = (
			SIMD4<Float>(1,			0,			0,			0),
			SIMD4<Float>(0,			cos(c),		-sin(c),	0),
			SIMD4<Float>(0,			sin(c),		cos(c),		0),
			SIMD4<Float>(0,			0,			0,			1)
		)

		self = self * roll * pitch * yaw
	}
}

extension matrix_float3x3 {
	mutating func rotate(angle: SIMD4<Float>) {
		var yaw = matrix_identity_float3x3
		var pitch = matrix_identity_float3x3
		var roll = matrix_identity_float3x3

		let a = angle.z
		let b = angle.y
		let c = angle.x
		yaw.columns = (
			SIMD3<Float>(cos(a),	-sin(a),	0),
			SIMD3<Float>(sin(a),	cos(a),		0),
			SIMD3<Float>(0,			0,			1)
		)

		pitch.columns = (
			SIMD3<Float>(cos(b),	0,			sin(b)),
			SIMD3<Float>(0,			1,			0),
			SIMD3<Float>(-sin(b),	0,			cos(b))
		)

		roll.columns = (
			SIMD3<Float>(1,			0,			0),
			SIMD3<Float>(0,			cos(c),		-sin(c)),
			SIMD3<Float>(0,			sin(c),		cos(c))
		)

		self = self * yaw * pitch * roll
	}
}
