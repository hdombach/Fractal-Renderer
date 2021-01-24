//
//  NodeContainer.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 1/17/21.
//  Copyright © 2021 Hezekiah Dombach. All rights reserved.
//

import Foundation

enum NodeContainerType {
	case Material
	case DE
}

struct NodeContainer {
	var nodes: [Node] = []
	var paths: [NodePath] = []
	var activePath: DraggablePath?
	let circleSize: CGFloat = 8
	let gridSize: CGFloat = 25
	let nodeWidth: CGFloat = 200
	var type: NodeContainerType = .Material
	
	var compiled: [UInt32] = []
	var compilerMessage: String = "Succesfully updated"
	var compilerCompleted: Bool = true
	
	mutating func delete(node nodeIn: Node?) {
		if nodeIn != nil {
			nodes.removeAll { (node) -> Bool in
				nodeIn!.id == node.id
			}
		}
	}
	
	mutating func delete(path pathIn: NodePath?) {
		if pathIn != nil {
			paths.removeAll { (path) -> Bool in
				path.id == pathIn!.id && path.beggining == pathIn!.beggining && path.ending == pathIn!.ending
			}
		}
	}
	
	func index(_ id: UUID) -> Int {
		guard let index = nodes.firstIndex(where: { $0.id == id}) else {
			fatalError("Node does not exist")
		}
		return index
	}
	
	func createValueAddress(node: Node, valueIndex: Int) -> NodeValueAddress {
		return NodeValueAddress(nodeIndex: index(node.id), valueIndex: valueIndex, id: node.id)
	}
	
	func createNodeAddress(node: Node) -> NodeAddress {
		return NodeAddress(nodeIndex: index(node.id), id: node.id)
	}
	
	func createDraggable(node: Node, valueIndex: Int) -> DraggablePath {
		return DraggablePath(beggining: createValueAddress(node: node, valueIndex: valueIndex), ending: getPosition(value: createValueAddress(node: node, valueIndex: valueIndex)))
	}
	
	func getPathAt(address: NodeValueAddress) -> NodePath? {
		let node = self[address.nodeAddress()]
		return paths.first { (path) -> Bool in
			path.ending.id == node.id && path.ending.valueIndex == address.valueIndex
		}
	}
	
	func getHeight(nodeAddress: NodeAddress) -> Int {
		let node = self[nodeAddress]
		var height = node.outputs.count + 2
		
		for value in node.inputs {
			if value.type == .float3 {
				height += 3
			} else {
				height += 1
			}
		}
		
		return height
	}
	
	func getPosition(value: NodeValueAddress) -> CGPoint {
		let node = self[value.nodeAddress()]
		//should anchor view at top left
		var point = node.position - CGPoint(x: nodeWidth / 2, y: CGFloat(getHeight(nodeAddress: value.nodeAddress())) * gridSize / 2)
		//starts at 1 to include the banner at top
		var viewIndex: Int = 0
		if value.valueIndex < node.outputs.count {
			viewIndex += value.valueIndex + 1
			point.x += nodeWidth
		} else {
			viewIndex += node.outputs.count
			for c in 0...(value.valueIndex - node.outputs.count) {
				if node.inputs[c].type == .float3 {
					if c == (value.valueIndex - node.outputs.count) {
						viewIndex += 2
					} else {
						viewIndex += 3
					}
				} else {
					viewIndex += 1
				}
			}
		}
		point.y += CGFloat(viewIndex) * gridSize + gridSize / 2
		
		return point
	}
	
	mutating func linkPath() {
		for nodeIndex in 0...nodes.count - 1 {
			let node = nodes[nodeIndex]
			if activePath?.beggining.id != node.id {
				if node.inputs.count > 0 {
					for valueIndex in node.outputs.count...node.outputs.count + node.inputs.count - 1 {
						//let value = node.inputs[valueIndex]
						if testValue(valueAddress: createValueAddress(node: node, valueIndex: valueIndex)) {
							let begging = activePath!.beggining
							let ending = NodeValueAddress(nodeIndex: nodeIndex, valueIndex: valueIndex, id: node.id)
							
							delete(path: getPathAt(address: ending))
							
							paths.append(NodePath(beggining: begging, ending: ending))
							
							activePath = nil
							return
						}
					}
				}
			}
		}
		activePath = nil
	}
	
	private func testValue(valueAddress: NodeValueAddress) -> Bool {
		if activePath == nil {
			return false
		}
		return circleSize * 2 > activePath!.ending.distanceTo(point: getPosition(value: valueAddress))
	}
	
	private func getIndex(address: NodeAddress) -> Int {
		if nodes.count > address.nodeIndex && nodes[address.nodeIndex].id == address.id {
			return address.nodeIndex
		} else {
			guard let index = nodes.firstIndex(where: { (node) -> Bool in
				node.id == address.id
			}) else {
				printError("could not find index")
				return 0
			}
			return index
		}
	}
	
	mutating private func updatePathAddresses() {
		for index in 0...paths.count - 1 {
			var path = paths[index]
			if path.beggining.id != nodes[path.beggining.nodeIndex].id {
				path.beggining.nodeIndex = nodes.firstIndex(where: { (node) -> Bool in
					node.id == path.beggining.id
				}) ?? -1
			}
		}
	}
	
	subscript(address: NodeAddress) -> Node {
		get {
			nodes[getIndex(address: address)]
		}
		set {
			nodes[getIndex(address: address)] = newValue
		}
	}
	
	subscript(address: NodeValueAddress) -> NodeValue {
		get {
			let node = nodes[getIndex(address: address.nodeAddress())]
			if node.outputs.count > address.valueIndex {
				return node.outputs[address.valueIndex]
			} else {
				return node.inputs[address.valueIndex - node.outputs.count]
			}
		}
		
		set {
			let index = getIndex(address: address.nodeAddress())
			if nodes[index].outputs.count > address.valueIndex {
				nodes[index].outputs[address.valueIndex] = newValue
			} else {
				nodes[index].inputs[address.valueIndex - nodes[index].outputs.count] = newValue
			}
		}
	}
}

//compiling stuff and things

extension NodeContainer {
	mutating func throwError(_ message: String) {
		compilerCompleted = false
		compilerMessage = "Error: " + message
	}
	mutating func compile() {
		//Find all outputs nodes if there is more than one, throw error.
		var output: NodeAddress? = nil
		for node in nodes {
			if node is MaterialNode || node is DENode {
				if output == nil {
					if (node is MaterialNode && type == .Material) || (node is DENode && type == .DE) {
						output = createNodeAddress(node: node)
					} else {
						throwError("Wrong output node")
						return
					}
				} else {
					throwError("More than one output node")
					return
				}
			}
		}
		
		compilerMessage = "Succesfully updated"
	}
}
