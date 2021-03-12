//
//  ColorNodes.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 1/30/21.
//  Copyright © 2021 Hezekiah Dombach. All rights reserved.
//

import SwiftUI

struct ColorBlendNode: Node {
	var name: String = "Color Blend"
	var functionName: String = "colorBlend"
	var color: Color = .nodeColor
	var id: UUID = UUID()
	var position: CGPoint = CGPoint()
	
	var inputs: [NodeValue] = [NodeFloat(0, name: "factor"), NodeColor(Float3(), name: nil), NodeColor(Float3(), name: nil)]
	var outputs: [NodeValue] = [NodeFloat3(Float3(), name: nil)]
	
	func update() {
		return
	}
	
	func new() -> Node {
		ColorBlendNode()
	}
	
}

struct ColorRampNode: Node {
	var name: String = "Color Ramp"
	var functionName: String = "colorRamp"
	var color: Color = .nodeColor
	var id: UUID = UUID()
	var position: CGPoint = CGPoint()
	
	var inputs: [NodeValue] = [NodeFloat(0, name: "value")]
	var outputs: [NodeValue] = [NodeColor(Float3(), name: "color")]
	
	var values: [(position: Float, color: Float3)] = []
	
	mutating func sortValues() {
		values.sort { (lesser, greater) -> Bool in
			lesser.position < greater.position
		}
	}
	
	mutating func addValue() {
		values.append((0, Float3(0)))
	}
	
	func update() {
		return
	}
	
	func new() -> Node {
		ColorRampNode()
	}
	
	var inputRange: Range<Int> {
		get {
			return outputs.count ..< outputs.count + inputs.count + values.count * 2
		}
	}
	
	subscript(valueIndex: Int) -> NodeValue {
		get {
			if outputs.count > valueIndex {
				return outputs[valueIndex]
			} else if outputs.count + inputs.count > valueIndex {
				return inputs[valueIndex - outputs.count]
			} else {
				let index = Int(floor(CGFloat(valueIndex - inputs.count - outputs.count) / 2))
				let itemIndex = (valueIndex - inputs.count - outputs.count) % 2
				if itemIndex == 0 {
					return NodeFloat(values[index].position, name: nil)
				} else {
					return NodeFloat3(values[index].color, name: nil)
				}
			}
		}
		
		set {
			
			if outputs.count > valueIndex {
				outputs[valueIndex] = newValue
			} else if outputs.count + inputs.count > valueIndex {
				inputs[valueIndex - outputs.count] = newValue
			} else if outputs.count + inputs.count > valueIndex{
				values[valueIndex - inputs.count - outputs.count].color = newValue.float3
			} else {
				let index = Int(floor(CGFloat(valueIndex - inputs.count - outputs.count) / 2))
				let itemIndex = (valueIndex - inputs.count - outputs.count) % 2
				if itemIndex == 0 {
					values[index].position = newValue.float
				} else {
					values[index].color = newValue.float3
				}
			}
		}
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
		if let colorRampNode = node as? ColorRampNode {
			if values.count != colorRampNode.values.count {
				return false
			}
			for index in 0..<values.count {
				if values[index].color != colorRampNode.values[index].color || values[index].position != colorRampNode.values[index].position {
					return false
				}
			}
		}
		return true
	}
	
	func generateCommand(outputs: [String], inputs: [String], unique: String) -> String {
		var code = ""
		if values.count == 0 {
			code.append(outputs[0] + " = float3(0);\n")
		} else if values.count == 1 {
			code.append("\(outputs[0]) = float3(\(inputs[2]), \(inputs[3]), \(inputs[4]));\n")
		} else {
			//---0---point(1-4)---1---point(5-8)---2---point(9-12)----3----
			
			let valueVariable = inputs[0]
			for c in 0...values.count {
				if c == 0 {
					code.append("if (\(valueVariable) < \(inputs[1])) {\n")
					code.append("\(outputs[0]) = float3(\(inputs[2]), \(inputs[3]), \(inputs[4]));\n")
				} else if c == values.count {
					code.append("} else {\n")
					code.append("\(outputs[0]) = float3(\(inputs[c * 4 - 2]), \(inputs[c * 4 - 1]), \(inputs[c * 4]));\n")
					code.append("}\n")
				} else {
					let greater = inputs[c * 4 + 1]
					let lesser = inputs[c * 4 - 3]
					code.append("} else if (\(valueVariable) < \(greater)) {\n")
					//gradient = 1 - (value - lower) / (greater - lower)
					code.append("float gradientValue\(unique) = 1 - (\(valueVariable) - \(lesser)) / (\(greater) - \(lesser));\n")
					code.append("float3 color\(unique) = float3(0);\n")
					
					//add lower color
					code.append("color\(unique) += float3(\(inputs[c * 4 - 2]), \(inputs[c * 4 - 1]), \(inputs[c * 4])) * gradientValue\(unique);\n")
					
					//add uper color
					code.append("color\(unique) += float3(\(inputs[c * 4 + 2]), \(inputs[c * 4  + 3]), \(inputs[c * 4 + 4])) * (1.0 - gradientValue\(unique));\n")
					
					//set outputs
					code.append("\(outputs[0]) = color\(unique);\n")
				}
			}
		}
		return code
	}
	
	
	func generateView(container: Binding<NodeContainer>, selected: Binding<Node?>) -> AnyView {
		let address = container.wrappedValue.createNodeAddress(node: self)
		return AnyView(ColorRampNodeView(nodeAddress: address, nodeContainer: container, selected: selected, node: Binding.init(get: {
			container.wrappedValue[address]! as! ColorRampNode
		}, set: { (newNode) in
			container.wrappedValue[address] = newNode
		})))
	}
}
