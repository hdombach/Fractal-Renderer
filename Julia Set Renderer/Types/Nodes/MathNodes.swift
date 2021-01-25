//
//  MathNodes.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 12/31/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import Foundation
import SwiftUI

struct AddNode: Node {
	var name: String = "Add"
	var type: String = "Add Node"
	var color: Color = .nodeMath
	var size: CGSize = CGSize(width: 200, height: 150)
	var id = UUID()
	var position: CGPoint = .init()
	
	var inputs: [NodeValue] = [NodeFloat(0, name: "value"), NodeFloat(0, name: "value")]
	var outputs: [NodeValue] = [NodeFloat(0, name: "value")]
	var paths: [NodePath] = []
	
	mutating func update() {
		outputs[0].float = inputs[0].float + inputs[1].float
	}
	
	func new() -> Node {
		AddNode()
	}
}

struct MultiplyNode: Node {
	var name: String = "Multiply"
	var type: String = "Multiply Node"
	var color: Color = .nodeMath
	var size: CGSize = CGSize(width: 200, height: 150)
	var id = UUID()
	var position = CGPoint()
	
	var inputs: [NodeValue] = [NodeFloat(0, name: "value"), NodeFloat(0, name: "value")]
	var outputs: [NodeValue] = [NodeFloat(0, name: "value")]
	var paths: [NodePath] = []
	
	mutating func update() {
		outputs[0].float = inputs[0].float * inputs[1].float
	}
	
	func new() -> Node {
		MultiplyNode()
	}
}

struct DivideNode: Node {
	var name: String = "Divide"
	var type: String = "Divide Node"
	var color: Color = .nodeMath
	var size: CGSize = CGSize(width: 200, height: 150)
	var id = UUID()
	var position = CGPoint()
	
	var inputs: [NodeValue] = [NodeFloat(1, name: "Numerator"), NodeFloat(1, name: "Denominator")]
	var outputs: [NodeValue] = [NodeFloat(1, name: "value")]
	var paths: [NodePath] = []
	
	mutating func update() {
		outputs[0].float = inputs[0].float / inputs[1].float
	}
	
	func new() -> Node {
		DivideNode()
	}
}

struct IsGreaterNode: Node {
	var name: String = "Is Greater"
	var type: String = "Is Greater Node"
	var color: Color = .nodeMath
	var size = CGSize(width: 200, height: 150)
	var id = UUID()
	var position = CGPoint()
	
	var inputs: [NodeValue] = [NodeFloat(1, name: "vlaue"), NodeFloat(0.5, name: "Threshold")]
	var outputs: [NodeValue] = [NodeFloat(1, name: "value")]
	var paths: [NodePath] = []
	
	mutating func update() {
		if inputs[0].float > inputs[1].float {
			outputs[0].float = 1
		} else {
			outputs[0].float = 0
		}
	}
	
	func new() -> Node {
		IsGreaterNode()
	}
}

struct CombineNode: Node {
	var name: String = "Combine"
	var type: String = "Combine Node"
	var color: Color = .nodeMath
	var size = CGSize(width: 200, height: 200)
	var id = UUID()
	var position = CGPoint()
	
	var inputs: [NodeValue] = [NodeFloat(0, name: "x"), NodeFloat(0, name: "y"), NodeFloat(0, name: "z")]
	var outputs: [NodeValue] = [NodeFloat3(Float3(0, 0, 0), name: "float3")]
	var paths: [NodePath] = []
	
	mutating func update() {
		outputs[0].float3 = Float3(inputs[0].float, inputs[1].float, inputs[2].float)
	}
	
	func new() -> Node {
		CombineNode()
	}
}

struct SeperateNode: Node {
	var name: String = "Seperate"
	var type: String = "Seperate Node"
	var color: Color = .nodeMath
	var size = CGSize(width: 200, height: 200)
	var id = UUID()
	var position = CGPoint()
	
	var inputs: [NodeValue] = [NodeFloat3(Float3(0, 0, 0), name: "float3")]
	var outputs: [NodeValue] = [NodeFloat(0, name: "x"), NodeFloat(0, name: "y"), NodeFloat(0, name: "z")]
	var paths: [NodePath] = []
	
	mutating func update() {
		return
	}
	
	func new() -> Node {
		SeperateNode()
	}
}
