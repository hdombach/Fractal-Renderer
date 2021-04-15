//
//  ChannelInfo.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 12/3/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import Foundation


struct ChannelInfo: Hashable, Codable {
	var index: UInt32
	var color: SIMD3<Float>
	var strength: Float
}
