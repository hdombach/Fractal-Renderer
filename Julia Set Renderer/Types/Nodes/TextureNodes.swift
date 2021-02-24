//
//  TextureNodes.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 1/29/21.
//  Copyright © 2021 Hezekiah Dombach. All rights reserved.
//

import SwiftUI

struct PerlinNode: Node {
	var name: String = "Perlin"
	var functionName: String = "perlin"
	var color: Color = .nodeTexture
	var id: UUID = UUID()
	var position: CGPoint = .init()
	
	var inputs: [NodeValue] = [NodeFloat3(Float3(), name: "position")]
	var outputs: [NodeValue] = [NodeFloat(0, name: "value")]
	
	func update() {
		return
	}
	
	func new() -> Node {
		PerlinNode()
	}
	
}

struct PerlinNode3: Node {
	var name: String = "Color Perlin"
	var functionName: String = "perlin3"
	var color: Color = .nodeTexture
	var id: UUID = UUID()
	var position: CGPoint = .init()
	
	var inputs: [NodeValue] = [NodeFloat3(Float3(), name: "position")]
	var outputs: [NodeValue] = [NodeFloat3(Float3(), name: "color")]
	
	func update() {
		return
	}
	
	func new() -> Node {
		PerlinNode3()
	}
	
}
