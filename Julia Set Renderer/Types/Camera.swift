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
	var focusDist: Float = 1
	var apature: Float = 0.1
	
	
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
