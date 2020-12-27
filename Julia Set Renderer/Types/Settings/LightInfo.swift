//
//  LightInfo.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 12/3/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import Foundation


struct LightInfo: Hashable, Identifiable {
	var color: SIMD3<Float>
	var strength: Float
	var size: Float
	var position: SIMD3<Float>
	var channel: UInt32
	var id: UInt32 = generateID()
}
