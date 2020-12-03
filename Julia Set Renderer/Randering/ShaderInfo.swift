//
//  ShaderInfo.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 12/2/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import Foundation

struct ShaderInfo {
	var rayMarchingSettings: RayMarchingSettings = .init()
	var camera: Camera = .init()
	var realIndex: SIMD4<UInt32> = .init()
	var randomSeed: SIMD3<UInt32> = .init()
	var voxelsLength: UInt32 = .init()
	var isJulia: UInt32 = .init()
	var lightsLength: UInt32 = .init()
	var exposure: UInt32 = 0
}
