//
//  Vector.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 1/28/21.
//  Copyright © 2021 Hezekiah Dombach. All rights reserved.
//

import SwiftUI

struct VectorAddNode: Node {
	var name: String = "Vector Add"
	var functionName: String = "vectorAdd"
	var color: Color = .nodeVector
	var id = UUID()
	var position: CGPoint = .init()
	
	var inputs: [NodeValue] = [NodeFloat3(.init(0, 0, 0), name: "value"), NodeFloat3(.init(0, 0, 0), name: "value")]
	var outputs: [NodeValue] = [NodeFloat3(.init(0, 0, 0), name: "value")]
	
	func update() {
		return
	}
	
	func new() -> Node {
		VectorAddNode()
	}
	
}

struct VectorLengthNode: Node {
	var name: String = "Vector Length"
	var functionName: String = "vectorLength"
	var color: Color = .nodeVector
	var id: UUID = UUID()
	var position: CGPoint = .init()
	
	var inputs: [NodeValue] = [NodeFloat3(.init(0, 0, 0), name: "value")]
	var outputs: [NodeValue] = [NodeFloat(0, name: "value")]
	
	func update() {
		return
	}
	
	func new() -> Node {
		VectorLengthNode()
	}
	
}

struct VectorScaleNode: Node {
	var name: String = "Vector Scale"
	var functionName: String = "vectorScale"
	var color: Color = .nodeVector
	var id = UUID()
	var position: CGPoint = .init()
	
	var inputs: [NodeValue] = [NodeFloat3(Float3(0, 0, 0), name: "vector"), NodeFloat(1, name: "scalar")]
	var outputs: [NodeValue] = [NodeFloat3(Float3(0, 0, 0), name: "vector")]
	
	func update() {
		return
	}
	
	func new() -> Node {
		VectorScaleNode()
	}
	
}

