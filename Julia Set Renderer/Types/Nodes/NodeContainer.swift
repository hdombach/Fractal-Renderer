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

//Root node manager
struct NodeContainer {
	var nodes: [Node] = [] {
		didSet {
			if oldConstants != constants {
				Engine.View.setNeedsDisplay(Engine.View.frame)
				oldConstants = constants
			}
		}
	}
	var paths: [NodePath] = []
	
	private var constantsAddresses: [(address: NodeValueAddress, vector: Int)] = []
	private var oldConstants: [Float] = []
	
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
		return output
	}
	
	
	var activePath: DraggablePath?
	let circleSize: CGFloat = 8
	let gridSize: CGFloat = 25
	let nodeWidth: CGFloat = 200
	var type: NodeContainerType = .Material
	
	var compiledMaterial: String?
	var compiledDE: String?
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
				if value.type == .float3 {
					height += 3
				} else {
					height += 1
				}
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
			
			if node is ColorRampNode {
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
		return circleSize * 2 > activePath!.ending.distanceTo(point: getPosition(value: valueAddress))
	}
	
	private func getIndex(address: NodeAddress) -> Int? {
		if nodes.count > address.nodeIndex && nodes[address.nodeIndex].id == address.id {
			return address.nodeIndex
		} else {
			guard let index = nodes.firstIndex(where: { (node) -> Bool in
				node.id == address.id
			}) else {
				printError("could not find index")
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

//compiling stuff and things

extension NodeContainer {
	mutating func throwError(_ message: String) {
		compilerCompleted = false
		compilerMessage = "Error: " + message
	}
	
	mutating func compile() {
		print(nodes)
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
		if output == nil {
			throwError("No output node")
			return
		}
		
		//Find the depth of each node and add constants to variable list
		//keeps track of a value and the number of observers
		
		//
		constantsAddresses.removeAll()
		var variables: [(observers: Int, value: NodeValueAddress, vectorIndex: Int)] = []
		var history: [Node] = []
		var depthDictionary: [NodeAddress: Int] = [:]
		
		func depthSort(node: Node, previousDepth: Int) -> Bool {
			if history.contains(where: { (anotherNode) -> Bool in
				anotherNode.id == node.id
			}) {
				throwError("Recursivness detected")
				return false
			}
			history.append(node)
			
			let currentDepth = previousDepth + 1
			if currentDepth > depthDictionary[createNodeAddress(node: node)] ?? -1 {
				depthDictionary.updateValue(currentDepth, forKey: createNodeAddress(node: node))
			}
			
			if node.inputs.count > 0 {
				for valueIndex in node.inputRange {
					if let path = getPathsAt(address: createValueAddress(node: node, valueIndex: valueIndex)).first {
						let result = depthSort(node: self[path.beggining.nodeAddress()]!, previousDepth: currentDepth)
						if result == false {
							return result
						}
					} else {
						let valueAddress = createValueAddress(node: node, valueIndex: valueIndex)
						
						if node[valueIndex].type == .float3 || node[valueIndex].type == .color {
							variables.append((-1, valueAddress, 0))
							variables.append((-1, valueAddress, 1))
							variables.append((-1, valueAddress, 2))
							
							constantsAddresses.append((valueAddress, 0))
							constantsAddresses.append((valueAddress, 1))
							constantsAddresses.append((valueAddress, 2))
						} else {
							variables.append((-1, valueAddress, 0))
							constantsAddresses.append((valueAddress, 0))
						}
					}
				}
			}
			history.removeLast()
			return true
		}
		
		depthSort(node: self[output!]!, previousDepth: -1)
		
		let constantsLength = variables.count
		
		var maxDepth: Int = 0
		for depth in depthDictionary.values {
			if depth > maxDepth {
				maxDepth = depth
			}
		}
		
		var layers: [[Node]] = Array.init(repeating: [], count: maxDepth + 1)
		for key in depthDictionary.keys {
			layers[depthDictionary[key]!].append(self[key]!)
		}
		//all nodes starting from deepest layer
		layers.reverse()
		
		var tempCode: String = ""
		var dealocatedVariables: [Int] = []
		var unique: Int = 0
		
		//generate code from nodes
		//Format: <command code> <outputs> <inputs>
		//Free up variables for future use when all readers are accounted for.
		
		//Maybe fix later. float3 variables that are read as a float1 will never get deallocated
		
		func createVariable(info: (observers: Int, value: NodeValueAddress, vectorIndex: Int)) -> String {
			if dealocatedVariables.isEmpty {
				variables.append(info)
				return "v\(variables.count - 1 - constantsLength)"
			} else {
				variables[dealocatedVariables.last!] = info
				return "v\(dealocatedVariables.removeLast() - constantsLength)"
			}
		}
		
		func findVariable(value: NodeValueAddress, vectorIndex: Int) -> String {
			var fallBack: Int = -1
			var index: Int = -1
			for c in 0...variables.count - 1 {
				let variable = variables[c]
				
				if variable.value == value {
					if variable.vectorIndex == vectorIndex {
						index = c
					}
					if variable.vectorIndex == 0 {
						fallBack = c
					}
				}
			}
			if index == -1 {
				index = fallBack
				fallBack = -2
				assert(index != -1)
			}
			
			//is constant if observers is -1
			if variables[index].observers == -1 {
				return "constants[\(index)]"
			} else {
				if fallBack > -2 {
					if fallBack > -2 {
						variables[index].observers -= 1
					}
					if variables[index].observers <= 0 {
						dealocatedVariables.append(index)
					}
				}
				return "v\(index - constantsLength)"
			}
		}
		
		func compileNode(node: Node) {
			var outputVariables: [String] = []
			var inputVariables: [String] = []
			for c in node.outputRange {
				let output = node[c]
				let address = createValueAddress(node: node, valueIndex: c)
				let observors = getPathsAt(address: address).count
				
				if observors > 0 {
					outputVariables.append(createVariable(info: (observors, address, 0)))
					
					if output.type == .float3 || output.type == .color {
						outputVariables.append(createVariable(info: (observors, address, 1)))
						outputVariables.append(createVariable(info: (observors, address, 2)))
					}
				} else {
					outputVariables.append("empty")
					if output.type == .float3 || output.type == .color {
						outputVariables.append("empty")
						outputVariables.append("empty")
					}
				}
			}
			for c in node.inputRange {
				let address: NodeValueAddress!
				let input = node[c]
				
				if let path = getPathsAt(address: createValueAddress(node: node, valueIndex: c)).first {
					address = path.beggining
				} else {
					address = createValueAddress(node: node, valueIndex: c)
				}
				
				inputVariables.append(findVariable(value: address, vectorIndex: 0))
				
				if input.type == .float3 || input.type == .color {
					inputVariables.append(findVariable(value: address, vectorIndex: 1))
					inputVariables.append(findVariable(value: address, vectorIndex: 2))
				}
			}
			tempCode.append(node.generateCommand(outputs: outputVariables, inputs: inputVariables, unique: "\(unique)"))
			unique += 1
			
		}
		
		for layer in layers {
			for node in layer {
				compileNode(node: node)
			}
		}
		
		if variables.count - constantsLength > 0 {
			var createdVariables: String = "float "
			for c in 0...(variables.count - constantsLength - 1) {
				createdVariables.append("v\(c), ")
			}
			createdVariables.removeLast(2)
			createdVariables.append(";\n\n")
			tempCode.insert(contentsOf: createdVariables, at: tempCode.startIndex)
		}
		
		
		//compiled = tempCode
		print("\n\n*__CODE__*\n\n")
		print(tempCode)
		compiledMaterial = tempCode
		
		compilerCompleted = true
		compilerMessage = "Succesfully updated"
		
		//compiledMaterial = "rgbAbsorption = float3(1, 0, 0); return;"
		Engine.Library.loadLibrary(material: compiledMaterial, de: compiledDE, completion: {
			DispatchQueue.main.async {
				Engine.View.setNeedsDisplay(Engine.View.frame)
			}
		})
	}
}
