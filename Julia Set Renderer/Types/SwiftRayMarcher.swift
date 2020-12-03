//
//  SwiftRayMarcher.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 12/2/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import Foundation
import simd

class RayMarcher {
	var settings: RayMarchingSettings {
		Engine.Settings.rayMarchingSettings
	}
	
	var iterations: Int = 50
	var bailout: Float = 3
	
	func DE(pos: SIMD3<Float>) -> Float {
		return mandelbulb(pos: pos)
	}
	
	func mandelbulb(pos: SIMD3<Float>) -> Float {
		var z = pos
		var dr: Float = 1
		var r: Float = 0
		let power = settings.mandelbulbPower
		for _ in 0...iterations - 1 {
			r = length(z)
			if r > bailout {
				break
			}
			
			var theta = acos(z.z / r)
			var phi = atan(z.y / z.x)
			dr = pow(r, power - 1) * power * dr + 1
			
			var zr = pow(r, power)
			theta = theta * power
			phi = phi * power
			
			z = zr * SIMD3<Float>.init(sin(theta) * cos(phi), sin(phi) * sin(theta), cos(theta))
			z += pos
		}
		return 0.5 * log(r) * r / dr
	}
}
