//
//  ColorNodes.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 1/30/21.
//  Copyright © 2021 Hezekiah Dombach. All rights reserved.
//

import SwiftUI

struct ColorBlendNode: Node {
	var name: String = "Color Blend"
	var functionName: String = "colorBlend"
	var color: Color = .nodeColor
	var id: UUID = UUID()
	var position: CGPoint = CGPoint()
	
	var inputs: [NodeValue] = [NodeFloat(0, name: "factor"), NodeColor(Float3(), name: nil), NodeColor(Float3(), name: nil)]
	var outputs: [NodeValue] = [NodeFloat3(Float3(), name: nil)]
	
	func update() {
		return
	}
	
	func new() -> Node {
		ColorBlendNode()
	}
}
