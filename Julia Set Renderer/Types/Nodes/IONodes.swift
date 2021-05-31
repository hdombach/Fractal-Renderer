//
//  Input and Output Nodes.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 12/31/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import Foundation
import SwiftUI

func CoordinateNode() -> Node {
	var result = Node()
	result.type = .coordinate
	result.name = "Coordinate"
	result.functionName = "coordinate"
	result.color = .nodeInput
	
	result.outputs = [NodeFloat3(Float3(repeating: 0), name: "position"), NodeFloat3(0, 0, 0, name: "orbit"), NodeFloat(0, name: "iterations")]
	
	result._generateCommand = {outputs, inputs, unique, node in
		var code = ""
		
		code.append("\(outputs[0]) = position;\n")
		code.append("\(outputs[1]) = orbit;\n")
		code.append("\(outputs[2]) = iterations;\n")
		
		return code
	}
	
	return result
}

func OrbitNode() -> Node {
	var result = Node()
	result.type = .orbit
	result.name = "Orbit"
	result.functionName = "orbit"
	result.color = .nodeInput
	
	result.outputs = [NodeFloat(0, name: "orbit")]
	
	return result
}

func MaterialNode() -> Node {
	var result = Node()
	result.type = .material
	result.name = "Material"
	result.functionName = "material"
	result.color = .nodeOutput
	
	result.inputs = [NodeColor(Float3(repeating: 0.5), name: "Surface Color"), NodeColor(Float3(repeating: 0), name: "Emission"), NodeFloat("Emmision Strength"), NodeFloat("Metality"), NodeFloat("Diffuse")]
	
	result._generateCommand = {outputs, inputs, unique, node in
		var code: String = ""
		
		code += "rgbAbsorption.xyz = clamp(\(inputs[0]), float3(0), float3(1));\n"
		code += "rgbEmitted = clamp(\(inputs[1]), float3(0), float3(1)) * \(inputs[2]); \n"
		code += "metality = \(inputs[3]);\n"
		code += "diffuse = clamp(\(inputs[4]), 0.0, 1.0);\n"
		code += "return;\n"
		
		return code
	}
	
	return result
}

func ColorNode() -> Node {
	var result = Node()
	
	result.type = .color
	result.name = "Color"
	result.functionName = "color"
	result.color = .nodeInput
	
	result.inputs = [NodeColor(Float3(repeating: 0.5), name: "color")]
	result.outputs = [NodeColor(Float3(repeating: 0.5), name: "color")]
	
	return result
}

func DENode() -> Node {
	var result = Node()
	
	result.type = .de
	result.name = "DE"
	result.functionName = "de"
	result.color = .nodeOutput
	result.inputs = [NodeFloat(1, name: "Distance"), NodeFloat(0, name: "Orbit Life"), NodeFloat3(0, 0, 0, name: "Orbit")]
	
	result._generateCommand = {outputs, inputs, unique, node in
		var code: String = ""
		
		code += "RayMarchInfo result;\n"
		code += "result.d = \(inputs[0]);\n"
		code += "result.orbitLife = \(inputs[1]);\n"
		code += "result.orbit = \(inputs[2]);\n"
		
		code += "return result;\n"
		
		return code
	}
	
	return result
}

func Float3Node() -> Node {
	var result = Node()
	
	result.type = .float3
	result.name = "Float3"
	result.functionName = "float3"
	result.color = .nodeInput
	
	result.inputs = [NodeFloat3("value")]
	result.outputs = [NodeFloat3("value")]
	
	result._generateCommand = { outputs, inputs, unique, node in
		"\(outputs[0]) = \(inputs[0]);\n"
	}
	return result
}

func FloatNode() -> Node {
	var result = Node()
	
	result.type = .float
	result.name = "Float"
	result.functionName = "float"
	result.color = .nodeInput
	
	result.inputs = [NodeFloat("value")]
	result.outputs = [NodeFloat("value")]
	
	result._generateCommand = {outputs, inputs, unique, node in
		"\(outputs[0]) = \(inputs[0]);\n"
	}
	return result
}
