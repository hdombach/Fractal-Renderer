//
//  RayMarchingSettings.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 12/3/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import Foundation

struct RayMarchingSettings {
	var mandelbulbPower: Float = 12
	var bundleSize: UInt32 = 1
	var quality: Float = 50000
	var iterations: UInt32 = 50
	var bailout: Float = 3
	var colorBase: float3 = .init(0.2, 0.2, 0.8);
	var colorVariation: float3 = .init(0.2, 0.2, 0.2);
	var colorFrequency: float3 = .init(50, 50, 50)
	var colorOffset: float3 = .init(0, 0, 0)
}
