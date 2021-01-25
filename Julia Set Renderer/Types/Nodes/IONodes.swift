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
	var type: String = "Coordinate Node"
	var color: Color = .nodeInput
	var size: CGSize = CGSize(width: 200, height: 100)
	var id = UUID()
	var position = CGPoint()
	
	var inputs: [NodeValue] = []
	var outputs: [NodeValue] = [NodeFloat3(Float3(0, 0, 0), name: "position")]
	var paths: [NodePath] = []
	
	mutating func update() {
		return
	}
	
	func new() -> Node {
		CoordinateNode()
	}
}

struct MaterialNode: Node {
	var name: String = "Material"
	var type: String = "Material Node"
	var color: Color = .nodeOutput
	var size: CGSize = CGSize(width: 200, height: 150)
	var id = UUID()
	var position = CGPoint()
	
	var inputs: [NodeValue] = [NodeFloat3(Float3(0.5, 0.5, 0.5), name: "Surface Color")]
	var outputs: [NodeValue] = []
	var paths: [NodePath] = []
	
	mutating func update() {
		return
	}
	
	func new() -> Node {
		MaterialNode()
	}
}

struct DENode: Node {
	var name: String = "DE"
	var type: String = "DE Node"
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