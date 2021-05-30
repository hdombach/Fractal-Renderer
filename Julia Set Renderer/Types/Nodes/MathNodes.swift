//
//  MathNodes.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 12/31/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import Foundation
import SwiftUI


func AddNode() -> Node {
	var result = Node()
	result.type = .add
	result.name = "Add"
	result.functionName = "add"
	result.color = .nodeMath
	
	result.inputs = [NodeFloat(0, name: "value"), NodeFloat(0, name: "value")]
	result.outputs = [NodeFloat(0, name: "value")]
	
	return result
}

func SubtractNode() -> Node {
	var result = Node()
	result.type = .subtract
	result.name = "Subtract"
	result.functionName = "subtract"
	result.color = .nodeMath
	
	result.inputs = [NodeFloat(0, name: "value"), NodeFloat(0, name: "value")]
	result.outputs = [NodeFloat(0, name: "value")]
	
	return result
}

func MultiplyNode() -> Node {
	var result = Node()
	result.type = .multiply
	result.name = "Multiply"
	result.functionName = "multiply"
	result.color = .nodeMath
	
	result.inputs = [NodeFloat(0, name: "value"), NodeFloat(0, name: "value")]
	result.outputs = [NodeFloat(0, name: "value")]
	
	return result
}

func DivideNode() -> Node {
	var result = Node()
	result.type = .divide
	result.name = "Divide"
	result.functionName = "divide"
	result.color = .nodeMath
	
	result.inputs = [NodeFloat(1, name: "numberator"), NodeFloat(1, name: "denominator")]
	result.outputs = [NodeFloat(1, name: "value")]
	
	return result
}

func IsGreaterNode() -> Node {
	var result = Node()
	result.type = .isGreater
	result.name = "Is Greater"
	result.functionName = "isGreater"
	result.color = .nodeMath
	
	result.inputs = [NodeFloat(1, name: "value"), NodeFloat(0.5, name: "threshold")]
	result.outputs = [NodeFloat(1, name: "value")]
	
	return result
}

func CombineNode() -> Node {
	var result = Node()
	result.type = .combine
	result.name = "Combine"
	result.functionName = "combine"
	result.color = .nodeMath
	
	result.inputs = [NodeFloat(0, name: "x"), NodeFloat(0, name: "y"), NodeFloat(0, name: "z")]
	result.outputs = [NodeFloat3(0, 0, 0, name: "float3")]
	
	return result
}

func SeperateNode() -> Node {
	var result = Node()
	result.type = .seperate
	result.name = "Seperate"
	result.functionName = "seperate"
	result.color = .nodeMath
	
	result.inputs = [NodeFloat3(0, 0, 0, name: "float3")]
	result.outputs = [NodeFloat(0, name: "x"), NodeFloat(0, name: "y"), NodeFloat(0, name: "z")]
	
	return result
}

func ClampNode() -> Node {
	var result = Node()
	result.type = .clamp
	result.name = "Clamp"
	result.functionName = "nodeClamp"
	result.color = .nodeMath
	
	result.inputs = [NodeFloat(0, name: "value"), NodeFloat(0, name: "min"), NodeFloat(0, name: "max")]
	result.outputs = [NodeFloat(0, name: "value")]
	
	return result
}

func SinNode() -> Node {
	var result = Node()
	result.type = .sin
	result.name = "Sin"
	result.functionName = "nodeSin"
	result.color = .nodeMath
	
	result.inputs = [NodeFloat(0, name: "value")]
	result.outputs = [NodeFloat(0, name: "value")]
	
	return result
}

func CosNode() -> Node {
	var result = Node()
	result.type = .cos
	result.name = "Cos"
	result.functionName = "nodeCos"
	result.color = .nodeMath
	
	result.inputs = [NodeFloat(0, name: "value")]
	result.outputs = [NodeFloat(0, name: "value")]
	
	return result
}

func AbsNode() -> Node {
	var result = Node()
	result.type = .abs
	result.name = "Abs"
	result.functionName = "abs"
	result.color = .nodeMath
	
	result.inputs = [NodeFloat(0, name: "value")]
	result.outputs = [NodeFloat(0, name: "value")]
	
	return result
}

func MapNode() -> Node {
	var result = Node()
	result.type = .map
	result.name = "Map"
	result.functionName = "map"
	result.color = .nodeMath
	
	result.inputs = [NodeFloat(0, name: "value"), NodeFloat(-1, name: "from min"), NodeFloat(1, name: "from max"), NodeFloat(0, name: "to min"), NodeFloat(1, name: "to max")]
	result.outputs = [NodeFloat(0, name: "value")]
	
	return result
}

func ModNode() -> Node {
	var result = Node()
	result.type = .mod
	result.name = "Modulo"
	result.functionName = "mod"
	result.color = .nodeMath
	
	result.inputs = [NodeFloat("Value"), NodeFloat(1, name: "Value")]
	result.outputs = [NodeFloat("Value")]
	return result
}
