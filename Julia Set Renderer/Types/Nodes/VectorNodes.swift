//
//  Vector.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 1/28/21.
//  Copyright © 2021 Hezekiah Dombach. All rights reserved.
//

import SwiftUI

func VectorAddNode() -> Node {
	var result = Node()
	result.type = .vectorAdd
	result.name = "Vector Add"
	result.functionName = "vectorAdd"
	result.color = .nodeVector
	
	result.inputs = [NodeFloat3(0, 0, 0, name: "float3"), NodeFloat3(0, 0, 0, name: "float3")]
	result.outputs = [NodeFloat3(0, 0, 0, name: "float3")]
	
	return result
}

func VectorLengthNode() -> Node {
	var result = Node()
	result.type = .vectorLength
	result.name = "Vector Length"
	result.functionName = "vectorLength"
	result.color = .nodeVector
	
	result.inputs = [NodeFloat3(0, 0, 0, name: "float3")]
	result.outputs = [NodeFloat(0, name: "length")]
	
	return result
}

func VectorScaleNode() -> Node {
	var result = Node()
	result.type = .vectorScale
	result.name = "Vector Scale"
	result.functionName = "vectorScale"
	result.color = .nodeVector
	
	result.inputs = [NodeFloat3(0, 0, 0, name: "float3"), NodeFloat(1, name: "scale")]
	result.outputs = [NodeFloat3(0, 0, 0, name: "float3")]
	
	return result
}

func VectorMapNode() -> Node {
	var result = Node()
	result.type = .vectorMap
	result.name = "Vector Map"
	result.functionName = "vectorMap"
	result.color = .nodeVector
	
	result.inputs = [NodeFloat3(0, 0, 0, name: "vector"), NodeFloat(-1, name: "from min"), NodeFloat(1, name: "from max"), NodeFloat(0, name: "to min"), NodeFloat(1, name: "to max")]
	result.outputs = [NodeFloat3(0, 0, 0, name: "vector")]
	
	return result
}

func DotProductNode() -> Node {
	var result = Node()
	result.type = .dotProduct
	result.name = "Dot Product"
	result.functionName = "dotProduct"
	result.color = .nodeVector
	
	result.inputs = [NodeFloat3(0, 0, 0, name: "vector"), NodeFloat3(0, 0, 0, name: "vector")]
	result.outputs = [NodeFloat(0, name: "value")]
	
	return result
}

func CrossProductNode() -> Node {
	var result = Node()
	result.type = .crossProduct
	result.name = "Cross Product"
	result.functionName = "crossProduct"
	result.color = .nodeVector
	
	result.inputs = [NodeFloat3(0, 0, 0, name: "vector"), NodeFloat3(0, 0, 0, name: "vector")]
	result.outputs = [NodeFloat3(0, 0, 0, name: "vector")]
	
	return result
}

func VectorMultiplyNode() -> Node {
	var result = Node()
	result.type = .vectorMultiply
	result.name = "Vector Multiply Node"
	result.functionName = "vectorMultiply"
	result.color = .nodeVector
	
	result.inputs = [NodeFloat3(0, 0, 0, name: "vector"), NodeFloat3(0, 0, 0, name: "vector")]
	result.outputs = [NodeFloat3(0, 0, 0, name: "vector")]
	
	return result
}

func VectorClampNode() -> Node {
	var result = Node()
	result.type = .vectorClamp
	result.name = "Vector Clamp Node"
	result.functionName = "vectorClamp"
	result.color = .nodeVector
	
	result.inputs = [NodeFloat3(0, 0, 0, name: "vector"), NodeFloat(0, name: "min"), NodeFloat(1, name: "max")]
	result.outputs = [NodeFloat3(0, 0, 0, name: "vector")]
	
	return result
}
