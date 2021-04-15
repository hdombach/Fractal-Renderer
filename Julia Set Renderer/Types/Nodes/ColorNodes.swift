//
//  ColorNodes.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 1/30/21.
//  Copyright © 2021 Hezekiah Dombach. All rights reserved.
//

import SwiftUI

func ColorBlendNode() -> Node {
	var result = Node()
	result.type = .colorBlend
	result.name = "Color Blend"
	result.functionName = "colorBlend"
	result.color = .nodeColor
	
	result.inputs = [NodeFloat(0, name: "factor"), NodeColor(Float3(), name: "color"), NodeColor(Float3(), name: "color")]
	result.outputs = [NodeFloat3(0, 0, 0, name: "color")]
	
	return result
}



struct ColorRampValue: Codable, Equatable {
	var position: Float
	var color: Float3
}

func ColorRampNode() -> Node {
	
	var result = Node()
	result.name  = "Color Ramp"
	result.functionName = "colorRamp"
	result.type = .colorRamp
	result.color = .nodeColor
	result.inputs = [NodeFloat(0, name: "value")]
	result.outputs = [NodeColor(Float3(), name: "color")]
	
	result._decode = {values, node in
		node.values = try values.decode([ColorRampValue].self, forKey: .values)
	}
	result._encode = {container, node in
		if let values = node.values as? [ColorRampValue] {
			try container.encode(values, forKey: .values)
		}
	}
	
	func getValues(_ node: Node) -> [ColorRampValue] {
		return (node.values as? [ColorRampValue]) ?? []
	}
	
	func sortValues(node: inout Node) {
		var values = getValues(node)
		values.sort { (less, great) -> Bool in
			less.position < great.position
		}
		node.values = values
	}
	func addValue(node: inout Node) {
		var values = getValues(node)
		values.append(ColorRampValue(position: 0, color: Float3(0)))
		node.values = values
	}
	
	
	
	result._inputRange = {node in
		return node.outputs.count ..< node.outputs.count + node.inputs.count + getValues(node).count * 2
	}
	result._getSubscript = {index, node in
		if (node.outputs.count > index) {
			return node.outputs[index]
		} else if node.outputs.count + node.inputs.count > index {
			return node.inputs[index - node.outputs.count]
		} else {
			let ind = Int(floor(CGFloat(index - node.inputs.count - node.outputs.count) / 2))
			let itemIndex = (index - node.inputs.count - node.outputs.count) % 2
			if (itemIndex == 0) {
				return NodeFloat(getValues(node)[ind].position, name: nil)
			} else {
				return NodeFloat3(getValues(node)[ind].color, name: nil)
			}
		}
	}
	result._setSubscript = {valueIndex, newValue, node in
		if (node.outputs.count > valueIndex) {
			node.outputs[valueIndex] = newValue
		} else if (node.outputs.count + node.inputs.count > valueIndex) {
			node.inputs[valueIndex - node.outputs.count] = newValue
		} else {
			let index = Int(floor(CGFloat(valueIndex - node.inputs.count - node.outputs.count) / 2))
			let itemIndex = (valueIndex - node.inputs.count - node.outputs.count) % 2
			var values = getValues(node)
			if (itemIndex == 0) {
				values[index].position = newValue.float
			} else {
				values[index].color = newValue.float3
			}
			node.values = values
		}
		
		if node.outputs.count > valueIndex {
			node.outputs[valueIndex] = newValue
		} else {
			node.inputs[valueIndex - node.outputs.count] = newValue
		}
	}
	
	result._compareValues = {lhs, rhs in
		let lValues = getValues(lhs)
		let rValues = getValues(rhs)
		return lValues == rValues
	}
	
	result._generateView = {container, selected, node in
		let address = container.wrappedValue.createNodeAddress(node: node)
		let bNode = Binding.init(get: {
			container.wrappedValue[address]!
		}, set: { (newNode) in
			container.wrappedValue[address] = newNode
		})
		let values = Binding.init { () -> [ColorRampValue] in
			getValues(bNode.wrappedValue)
		} set: { (newValue) in
			bNode.wrappedValue.values = newValue
		}


		return AnyView(ColorRampNodeView(nodeAddress: address, nodeContainer: container, selected: selected, node: bNode, values: values))
	}
	
	result._generateCommand = {outputs, inputs, unique, node in
		var code = ""
		let values = getValues(node)
		if values.count == 0 {
			code.append(outputs[0] + " = float3(0);\n")
		} else if values.count == 1 {
			code.append("\(outputs[0]) = \(inputs[2]);\n")
		} else {
			//0 is value input
			//1-end is colors and indexes
			//---0---point(1-4)---1---point(5-8)---2---point(9-12)----3----
			//---0---point(1-2)---1---point(3-4)---2---point(5-6)----3
			
			let valueVariable = inputs[0]
			for c in 0...values.count {
				if c == 0 {
					code.append("if (\(valueVariable) < \(inputs[1])) {\n")
					code.append("\(outputs[0]) = \(inputs[2]);\n")
				} else if c == values.count {
					code.append("} else {\n")
					code.append("\(outputs[0]) = \(inputs[c * 2]);\n")
					code.append("}\n")
				} else {
					let greater = inputs[c * 2 + 1]
					let lesser = inputs[c * 2 - 1]
					code.append("} else if (\(valueVariable) < \(greater)) {\n")
					//gradient = 1 - (value - lower) / (greater - lower)
					code.append("float gradientValue\(unique) = 1 - (\(valueVariable) - \(lesser)) / (\(greater) - \(lesser));\n")
					code.append("float3 color\(unique) = float3(0);\n")
					
					//add lower color
					code.append("color\(unique) += \(inputs[c * 2]) * gradientValue\(unique);\n")
					
					//add uper color
					code.append("color\(unique) += \(inputs[c * 2 + 2]) * (1.0 - gradientValue\(unique));\n")
					
					//set outputs
					code.append("\(outputs[0]) = color\(unique);\n")
				}
			}
		}
		return code
	}
	
	return result
}
