//
//  NodeContainer.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 1/17/21.
//  Copyright © 2021 Hezekiah Dombach. All rights reserved.
//

import Foundation

enum NodeContainerType: String, Codable {
	case Material
	case DE
}

//Root node manager
struct NodeContainer: Codable {
	struct ConstantAddress: Codable {
		var address: NodeValueAddress
		var vector: Int
	}
	
	var nodes: [Node] = []
	var paths: [NodePath] = []
	
	internal var constantsAddresses: [ConstantAddress] = []
	
	//values that can be used to change the procedural texture without recalculating
	var constants: [Float] {
		var output: [Float] = []
		for address in constantsAddresses {
			if let value = self[address.address] {
				if address.vector == 0 {
					output.append(value.float)
				} else {
					output.append(value.float3[address.vector])
				}
			} else {
				output.append(0)
			}
		}
		output.append(0)
		return output
	}
	
	
	var activePath: DraggablePath?
	let dotSize: CGFloat = 8
	let gridSize: CGFloat = 25
	let nodeWidth: CGFloat = 200
	var type: NodeContainerType = .Material
	
	var compiled: String?
	var compilerMessage: String = "Succesfully updated"
	var compilerCompleted: Bool = true
	
	mutating func delete(node nodeIn: Node?) {
		if nodeIn != nil {
			for valueIndex in 0...nodeIn!.inputs.count + nodeIn!.outputs.count - 1 {
				for path in getPathsAt(address: createValueAddress(node: nodeIn!, valueIndex: valueIndex)) {
					delete(path: path)
				}
			}
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
	
	func getPathsAt(address: NodeValueAddress) -> [NodePath] {
		if let node = self[address.nodeAddress()] {
			var result: [NodePath] = []
			for path in paths {
				if (path.ending.id == node.id && path.ending.valueIndex == address.valueIndex) || (path.beggining.id == node.id && path.beggining.valueIndex == address.valueIndex) {
					result.append(path)
				}
			}
			
			return result
		} else {
			printError("Incorrect address while getting paths")
			return []
		}
	}
	
	//returns the height of a node
	func getHeight(nodeAddress: NodeAddress) -> Int {
		if let node = self[nodeAddress] {
			var height = node.outputs.count + 2
			
			for value in node.inputs {
				height += value.type.length
			}
			
			return height
		} else {
			printError("Incorrect address while getting node height")
			return 1
		}
	}
	
	func getPosition(value: NodeValueAddress) -> CGPoint {
		if let node = self[value.nodeAddress()] {
			//should anchor view at top left
			var point = node.position - CGPoint(x: nodeWidth / 2, y: CGFloat(getHeight(nodeAddress: value.nodeAddress())) * gridSize / 2)
			//starts at 1 to include the banner at top
			var viewIndex: Float = 1
			if value.valueIndex < node.outputs.count {
				viewIndex += value.valueIndex.float + 0.5
				point.x += nodeWidth
			} else {
				viewIndex += node.outputs.count.float
				if value.valueIndex >= node.outputs.count {
					for c in 0...(value.valueIndex - node.outputs.count) {
						viewIndex += node.inputs[c].type.length.float
					}
					viewIndex -= node.inputs[value.valueIndex - node.outputs.count].type.length.float / 2
				}
			}
			
			point.y += CGFloat(viewIndex) * gridSize
			
			if node.type == .colorRamp {
				point.y -= gridSize
			}
			
			return point
		} else {
			printError("Incorrect address while getting node point")
			return CGPoint()
		}
	}
	
	//ataches the active path to a node
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
							
							getPathsAt(address: ending).forEach { (path) in
								delete(path: path)
							}
							
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
	
	//Tests if active path is near a value
	private func testValue(valueAddress: NodeValueAddress) -> Bool {
		if activePath == nil {
			return false
		}
		return dotSize * 2 > activePath!.ending.distanceTo(point: getPosition(value: valueAddress))
	}
	
	private func getIndex(address: NodeAddress) -> Int? {
		if nodes.count > address.nodeIndex && nodes[address.nodeIndex].id == address.id {
			return address.nodeIndex
		} else {
			guard let index = nodes.firstIndex(where: { (node) -> Bool in
				node.id == address.id
			}) else {
				//printError("could not find index")
				return nil
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
	
	subscript(address: NodeAddress) -> Node? {
		get {
			if let index = getIndex(address: address) {
				return nodes[index]
			} else {
				return nil
			}
		}
		set {
			if let index = getIndex(address: address) {
				nodes[index] = newValue!
			}
		}
	}
	
	subscript(address: NodeValueAddress) -> NodeValue? {
		get {
			if let index = getIndex(address: address.nodeAddress()) {
				let node = nodes[index]
				return node[address.valueIndex]
			} else {
				return nil
			}
		}
		
		set {
			if let index = getIndex(address: address.nodeAddress()),  newValue != nil {
				nodes[index][address.valueIndex] = newValue!
				return
			}
		}
	}
}
