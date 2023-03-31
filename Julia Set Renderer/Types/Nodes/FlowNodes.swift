//
//  FlowNodes.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 4/20/21.
//  Copyright © 2021 Hezekiah Dombach. All rights reserved.
//

import Foundation
import SwiftUI

struct IterateNodeValue: Codable {
	var draggedPosition: CGPoint?
	var	pairedNode: NodeAddress?
	var repeatedValues: [NodeValue] = []
}

func IterateNode() -> Node {
	
	var result = Node()
	result.type = .iterate
	result.name = "Iterate"
	result.functionName = "iterate"
	result.color = .nodeFlow
	
	result.inputs = [NodeInt(10, name: "times")]
	
	result.values = IterateNodeValue()
	
	result._generateView = {container, selected, node in
		let address = container.wrappedValue.createNodeAddress(node: node)
		
		return AnyView(NodeIterateView(nodeAddress: address, nodeContainer: container, selected: selected))
	}
	
	result._decode = {values, node in
		node.values = try values.decode(IterateNodeValue.self, forKey: .values)
	}
	result._encode = {container, node in
		if let values = node.values as? IterateNodeValue {
			try container.encode(values, forKey: .values)
		}
	}
	func getValues(node: Node) -> [NodeValue]? {
		return (node.values as? IterateNodeValue)?.repeatedValues
	}
	func setValues(node: inout Node, newValues: [NodeValue]) {
		var old = (node.values as? IterateNodeValue)
		old?.repeatedValues = newValues
		node.values = old
	}
	
	result._outputRange = { node in
		return 0..<(getValues(node: node)?.count ?? 0)
	}
	
	result._inputRange = { node in
		let repeatedValuesCount = (getValues(node: node)?.count ?? 0)
		return (repeatedValuesCount)..<(repeatedValuesCount * 2 + 1)
	}
	
	result._getSubscript = {index, node in
		if let values = getValues(node: node) {
			if index < values.count {
				return values[index]
			} else if index < values.count + node.inputs.count {
				return node.inputs[index - values.count]
			} else {
				return values[index - values.count - node.inputs.count]
			}
		} else {
			return nil
		}
	}
	result._setSubscript = {index, newValue, node in
		if var nodeValues = (node.values as? IterateNodeValue), let newValue = newValue {
			let count = nodeValues.repeatedValues.count
			if (index < count) {
				nodeValues.repeatedValues[index] = newValue
			} else if index < node.inputs.count + count {
				node.inputs[index - count] = newValue
			} else {
				nodeValues.repeatedValues[index - count - node.inputs.count] = newValue
			}
			node.values = nodeValues
		}
	}
	
	result._getHeight = {node in
		var height: Int = 3
		if let values = getValues(node: node) {
			for value in values {
				height += value.type.length
			}
			height += values.count
		}
		return height
	}
	
	result._generateCommand = {outputs, inputs, unique, node in
		var temp = ""
		
		
		let values = node.values as! IterateNodeValue
		for c in 0..<values.repeatedValues.count {
			temp += "\(outputs[c]) = \(inputs[c + 1]);\n"
		}
		
		
		temp += "for (int c = 0; c < \(inputs[0]); c++) {\n"
		
		return temp
	}
	
	return result
}

func IterateEndNode() -> Node {
	var result = Node()
	result.type = .iterateEnd
	result.name = "Iterate End"
	result.functionName = "iterateEnd"
	result.color = .nodeFlow
	
	
	result.values = IterateNodeValue()
	
	result._generateView = {container, selected, node in
		let address = container.wrappedValue.createNodeAddress(node: node)
		
		return AnyView(NodeIterateEndView(nodeAddress: address, nodeContainer: container, selected: selected))
	}
	
	result._decode = {values, node in
		node.values = try values.decode(IterateNodeValue.self, forKey: .values)
	}
	
	result._encode = {container, node in
		if let values = node.values as? IterateNodeValue {
			try container.encode(values, forKey: .values)
		}
	}
	
	func getValues(node: Node) -> [NodeValue]? {
		return (node.values as? IterateNodeValue)?.repeatedValues
	}
	func setValues(node: inout Node, newValues: [NodeValue]) {
		var old = (node.values as? IterateNodeValue)
		old?.repeatedValues = newValues
		node.values = old
	}
	
	result._inputRange = {node in
		if let values = getValues(node: node) {
			return values.count..<(values.count * 2)
		} else {
			return 0..<0
		}
	}
	result._outputRange = {node in
		if let values = getValues(node: node) {
			return 0..<values.count
		} else {
			return 0..<0
		}
	}
	
	result._getSubscript = {index, node in
		if let values = getValues(node: node) {
			if index < values.count {
				return values[index]
			} else if index < values.count + node.inputs.count {
				return node.inputs[index - values.count]
			} else {
				return values[index - values.count - node.inputs.count]
			}
		} else {
			return nil
		}
	}
	result._setSubscript = {index, newValue, node in
		if var nodeValues = (node.values as? IterateNodeValue), let newValue = newValue {
			let count = nodeValues.repeatedValues.count
			if (index < count) {
				nodeValues.repeatedValues[index] = newValue
			} else if index < node.inputs.count + count {
				node.inputs[index - count] = newValue
			} else {
				nodeValues.repeatedValues[index - count - node.inputs.count] = newValue
			}
			node.values = nodeValues
		}
	}
	
	result._generateCommand = {outputs, inputs, unique, node in
		var temp = ""
		var tempAfter = ""
		let values = node.values as! IterateNodeValue
		for c in 0..<values.repeatedValues.count {
			temp += "\(outputs[c + values.repeatedValues.count]) = \(inputs[c]);\n"
			tempAfter = "\(outputs[c]) = \(inputs[c]);\n"
		}
		temp += "}\n" + tempAfter
		
		return temp
	}
	
	
	return result
}
