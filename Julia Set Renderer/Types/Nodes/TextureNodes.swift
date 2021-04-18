//
//  TextureNodes.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 1/29/21.
//  Copyright © 2021 Hezekiah Dombach. All rights reserved.
//

import SwiftUI

func PerlinNode() -> Node {
	var result = Node()
	result.type = .perlin
	result.name = "Perlin"
	result.functionName = "perlin"
	result.color = .nodeTexture
	
	result.inputs = [NodeFloat3(0, 0, 0, name: "position")]
	result.outputs = [NodeFloat(0, name: "value")]
	
	return result
}

func Perlin3Node() -> Node {
	var result = Node()
	result.type = .perlin3
	result.name = "Color Perlin"
	result.functionName = "perlin3"
	result.color = .nodeTexture
	
	result.inputs = [NodeFloat3(0, 0, 0, name: "position")]
	result.outputs = [NodeFloat3(0, 0, 0, name: "color")]
	
	return result
}
