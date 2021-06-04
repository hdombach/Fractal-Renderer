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
	
	var ambient: Float = 0.995
	var angleShading: Float = 1
	
	var backgroundColor: Float3 = Float3(135 / 255, 206 / 255, 235 / 255)
	var depthColor: Float3 = Float3(repeating: 0);
	var depthStrength: Float = 0;
	var emissionStrength: Float = 0
	
	var atmosphere: AtmosphereSettings {
		get {
			var result = AtmosphereSettings()
			result.backgroundColor = backgroundColor
			result.depthColor = depthColor
			result.depthStrength = depthStrength
			result.emissionStrength = emissionStrength
			return result
		}
		set {
			backgroundColor = newValue.backgroundColor
			depthColor = newValue.depthColor
			depthStrength = newValue.depthStrength
			emissionStrength = newValue.emissionStrength
		}
	}
}

struct AtmosphereSettings: Codable {
	var backgroundColor: Float3 = Float3(135 / 255, 206 / 255, 235 / 255)
	var depthColor: Float3 = Float3(repeating: 0);
	var depthStrength: Float = 0;
	var emissionStrength: Float = 0
}
