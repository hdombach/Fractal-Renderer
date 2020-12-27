//
//  JuliaSetSettings.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 12/22/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import Foundation

struct JuliaSetSettings {
	var realSlope: Float = 1
	var realIntercept: Float = 0
	var imaginarySlope: Float = 1
	var imaginaryIntercept: Float = 0
	var iterations: Int = 20
	
	var quickMode: Bool = false
}
