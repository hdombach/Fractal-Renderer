//
//  Node.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 12/30/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import Foundation
import SwiftUI

let allNodes: [Node] = [CoordinateNode(), MaterialNode(), DENode(), AddNode(), MultiplyNode(), DivideNode(), IsGreaterNode(), CombineNode(), SeperateNode()]

protocol Node {
	var name: String { get }
	var type: String { get }
	var color: Color { get }
	var size: CGSize { get }
	var id: UUID { get }
	var position: CGPoint { get set }
	
	var inputs: [NodeValue] { get set }
	var outputs: [NodeValue] { get set }
	//var paths: [NodePath] { get set }
	
	mutating func update()
	func new() -> Node
}

extension Node {
	
	subscript(valueIndex: Int) -> NodeValue {
		get {
			if outputs.count > valueIndex {
				return outputs[valueIndex]
			} else {
				return outputs[valueIndex - outputs.count]
			}
		}
		
		set {
			if outputs.count > valueIndex {
				outputs[valueIndex] = newValue
			} else {
				return outputs[valueIndex - outputs.count] = newValue
			}
		}
	}
	
	func getHeight() -> Int {
		var height: Int = 2
		for value in inputs {
			if value.type == .float3 {
				height += 3
			} else {
				height += 1
			}
		}
		
		height += outputs.count
		return height
	}
	
	func compare(to node: Node) -> Bool {
		if id != node.id {
			return false
		}
		if position != node.position {
			return false
		}
		if !compare(lhs: inputs, rhs: node.inputs) {
			return false
		}
		return true
	}
	
	
	func compare(lhs: [NodeValue], rhs: [NodeValue]) -> Bool {
		if lhs.count != rhs.count {
			return false
		}
		if lhs.count == 0 && rhs.count == 0 {
			return true
		}
		for c in 0...lhs.count - 1 {
			if lhs[c].float3 != rhs[c].float3 {
				return false
			}
		}
		return true
	}
}

struct ErrorNode: Node {
	var name: String = "Error"
	var type: String = "Error Node"
	var color = Color.clear
	var size: CGSize = .init()
	var id = UUID()
	var position: CGPoint = CGPoint()
	
	var inputs: [NodeValue] = []
	var outputs: [NodeValue] = []
	
	init() {
		printError("Error node created")
	}
	
	mutating func update() {
		return
	}
	func new() -> Node {
		ErrorNode()
	}
}

typealias PreviewedNode = DENode

struct NodeCustom_Previews: PreviewProvider {
	static var previews: some View {
		GroupBox(label: Text("Content"), content: {
			Text("hi")
			//NodeView(node: Binding.constant(PreviewedNode(position: CGPoint(x: 200, y: 200))), selected: Binding.constant(nil), activePath: .constant(nil), viewPosition: .init())
		})
	}
}
