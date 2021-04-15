//
//  ShaderInfo.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 12/2/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import Foundation

struct ShaderInfo: Codable {
	var rayMarchingSettings: RayMarchingSettings = .init()
	var camera: Camera = Camera(setup: false)
	var realIndex: SIMD4<UInt32> = .init()
	var randomSeed: SIMD3<UInt32> = .init()
	var voxelsLength: UInt32 = .init()
	var isJulia: UInt32 = 2
	var lightsLength: UInt32 = .init()
	var exposure: UInt32 = 0
	var channelsLength: UInt32 = .init()
	
	//0: is linear
	//1: starting depth;
	//2: depth multiplier
	var depthSettings: SIMD3<Float> = .init(0, 0, 1)
}
