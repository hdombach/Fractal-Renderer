//
//  Input and Output Nodes.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 12/31/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import Foundation
import SwiftUI

struct CoordinateNode: Node {
	var name = "Coordinate"
	var functionName: String = "coordinate"
	var color: Color = .nodeInput
	var size: CGSize = CGSize(width: 200, height: 100)
	var id = UUID()
	var position = CGPoint()
	
	var inputs: [NodeValue] = []
	var outputs: [NodeValue] = [NodeFloat3(Float3(0, 0, 0), name: "position"), NodeFloat3(Float3(0, 0, 0), name: "orbit"), NodeFloat(0, name: "iterations")]
	var paths: [NodePath] = []
	
	mutating func update() {
		return
	}
	
	func new() -> Node {
		CoordinateNode()
	}
	
	func generateCommand(outputs: [String], inputs: [String], unique: String) -> String {
		
		var code = ""
		
		/*code.append("\(outputs[0]) = position.x;\n")
		code.append("\(outputs[1]) = position.y;\n")
		code.append("\(outputs[2]) = position.z;\n")
		code.append("\(outputs[3]) = orbit.x;\n")
		code.append("\(outputs[4]) = orbit.y;\n")
		code.append("\(outputs[5]) = orbit.z;\n")
		code.append("\(outputs[6]) = iterations;\n")*/
		
		code.append("\(outputs[0]) = position;\n")
		code.append("\(outputs[1]) = orbit;\n")
		code.append("\(outputs[2]) = iterations;\n")
		
		return code
		
	}
	
}

struct OrbitNode: Node {
	var name: String = "Orbit"
	var functionName: String = "orbit"
	var color: Color = .nodeInput
	var id = UUID()
	var position: CGPoint = CGPoint()
	
	var inputs: [NodeValue] = []
	var outputs: [NodeValue] = [NodeFloat(0, name: "orbit")]
	
	func update() {
		return
	}
	
	func new() -> Node {
		OrbitNode()
	}
}

struct MaterialNode: Node {
	var name: String = "Material"
	var functionName: String = "material"
	var color: Color = .nodeOutput
	var size: CGSize = CGSize(width: 200, height: 150)
	var id = UUID()
	var position = CGPoint()
	
	var inputs: [NodeValue] = [NodeColor(Float3(0.5, 0.5, 0.5), name: "Surface Color")]
	var outputs: [NodeValue] = []
	var paths: [NodePath] = []
	
	mutating func update() {
		return
	}
	
	func new() -> Node {
		MaterialNode()
	}
	func generateCommand(outputs: [String], inputs: [String], unique: String) -> String {
		var code: String = ""
		//code.append("rgbAbsorption.xyz = clamp(float3(\(inputs[0]), \(inputs[1]), \(inputs[2])), float3(0), float3(1));\n")
		code.append("rgbAbsorption.xyz = clamp(\(inputs[0]), float3(0), float3(1));\n")
		code.append("rgbEmitted = float3(0, 0, 0); \n")
		code.append("return;\n")
		return code
	}
}

struct ColorNode: Node {
	var name: String = "Color"
	var functionName: String = "color"
	var color: Color = .nodeInput
	var id: UUID = UUID()
	var position: CGPoint = .init()
	
	var inputs: [NodeValue] = [NodeColor(Float3(0.5, 0.5, 0.5), name: "color")]
	var outputs: [NodeValue] = [NodeColor(Float3(), name: "color")]
	
	func update() {
		return
	}
	
	func new() -> Node {
		ColorNode()
	}
}

struct DENode: Node {
	var name: String = "DE"
	var functionName: String = "de"
	var color: Color = .nodeOutput
	var size: CGSize = CGSize(width: 200, height: 100)
	var id = UUID()
	var position: CGPoint = CGPoint()
	
	var inputs: [NodeValue] = [NodeFloat(1, name: "Distance")]
	var outputs: [NodeValue] = []
	var paths: [NodePath] = []
	mutating func update() {
		return
	}
	
	func new() -> Node {
		DENode()
	}
}
