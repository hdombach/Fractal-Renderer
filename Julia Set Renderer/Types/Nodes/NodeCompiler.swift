//
//  NodeCompiler.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 2/24/21.
//  Copyright © 2021 Hezekiah Dombach. All rights reserved.
//

import Foundation

//compiling stuff and things

enum NodeCompilationError: Error {
	case recursivness
	case wrongOutput
	case noOutput
	case severalOutputs
	case noVariable
	case float3ToFloatConstant
}

extension NodeContainer {
	mutating func throwError(_ message: String) {
		compilerCompleted = false
		compilerMessage = "Error: " + message
	}
	
	private struct Variable {
		var vectorLength: Int
		var observers: Int
		var value: NodeValueAddress
		///If variable is a constant hols what position in vector
		var constantIndex: Int?
		
		mutating func updateValue(variable: Variable) -> Bool {
			if variable.vectorLength == self.vectorLength {
				self.observers = variable.observers
				self.value = variable.value
				self.constantIndex = variable.constantIndex
				return true
			} else {
				return false
			}
		}
		
		init(value: NodeValueAddress, observers: Int, constantIndex: Int? = nil, vectorLength: Int) {
			self.observers = observers
			self.value = value
			self.constantIndex = constantIndex
			self.vectorLength = vectorLength
			
			if isConstant {
				self.vectorLength = 1
			}
		}
		
		var isConstant: Bool {
			get {
				constantIndex != nil
			}
		}
	}
	
	
	
	mutating func newCompile() throws {
		
		//Find all outputs nodes if there is more than one, throw error.
		var output: NodeAddress? = nil
		for node in nodes {
			if node is MaterialNode || node is DENode {
				if output == nil {
					if (node is MaterialNode && type == .Material) || (node is DENode && type == .DE) {
						output = createNodeAddress(node: node)
					} else {
						throw NodeCompilationError.wrongOutput
					}
				} else {
					throw NodeCompilationError.severalOutputs
				}
			}
		}
		if output == nil {
			throw NodeCompilationError.noOutput
		}
		
		//Find the depth of each node and add constants to variable list
		//keeps track of a value and the number of observers
		
		constantsAddresses.removeAll()
		var variables: [Variable] = []
		var history: [Node] = []
		var depths: [NodeAddress: Int] = [:]
		
		func depthSort(node: Node, previousDepth: Int) throws {
			if history.contains(where: { (testNode) -> Bool in
				testNode.id == node.id
			}) {
				throw NodeCompilationError.recursivness
			}
			history.append(node)
			
			let currentDepth = previousDepth + 1
			let address = createNodeAddress(node: node)
			if currentDepth > depths[address] ?? -1 {
				depths.updateValue(currentDepth, forKey: address)
			}
			
			//recursivly call all inputs to the node to backtrack through node network
			if node.inputs.count > 0 {
				for valueIndex in node.inputRange {
					let valueAddress = createValueAddress(node: node, valueIndex: valueIndex)
					
					if let path = getPathsAt(address: valueAddress).first {
						do {
							try depthSort(node: self[path.beggining.nodeAddress()]!, previousDepth: currentDepth)
						} catch {
							throw error
						}
					} else {
						//if there are no paths at the input then it is a constant
						
						variables.append(Variable(value: valueAddress, observers: -1, constantIndex: constantsAddresses.count, vectorLength: node[valueIndex].type.length))
						
						constantsAddresses.append((valueAddress, 0))
						if node[valueIndex].type == .float3 || node[valueIndex].type == .color {
							constantsAddresses.append((valueAddress, 1))
							constantsAddresses.append((valueAddress, 2))
						}
					}
				}
			}
			
			history.popLast()
		}
		
		do {
			try depthSort(node: self[output!]!, previousDepth: -1)
		} catch {
			throw error
		}
		
		
		//set up varialbes that will be used in compiled product
		let constantsLength = variables.count
		
		let maxDepth = depths.values.max() ?? 0
		
		var layers: [[Node]] = Array.init(repeating: [], count: maxDepth + 1)
		for key in depths.keys {
			layers[depths[key]!].append(self[key]!)
		}
		layers.reverse()
		
		var tempCode: String = ""
		var dealocatedVariables: [Int] = []
		var unique: Int = 0
		
		//functions for keeping track of variables
		func createVarialbe(_ new: Variable) -> String {
			
			
			if let variableIndex = dealocatedVariables.first(where: { (test) -> Bool in
				//returns true when variable is correct type and succesfully updated
				variables[test].updateValue(variable: new)
			}) {
				return "v\(variableIndex - constantsLength)"
			} else {
				variables.append(new)
				return "v\(variables.count - 1 - constantsLength)"
			}
			
		}
		
		func findVariable(value: NodeValueAddress, vectorLength: Int) throws -> String {
			if let index = variables.firstIndex(where: { (test) -> Bool in
				test.value == value
			}) {
				var variable: Variable {
					get { variables[index] }
					set { variables[index] = newValue}
				}
				
				if variable.isConstant {
					//constants are only floats so if float3 is required then fix it
					if vectorLength == 3 {
						//from 3 floats to float3
						let v1 = "constants[\(variable.constantIndex! + 0)]"
						let v2 = "constants[\(variable.constantIndex! + 1)]"
						let v3 = "constants[\(variable.constantIndex! + 2)]"
						return "float3(\(v1), \(v2), \(v3))"
					} else {
						return "constants[\(variable.constantIndex!)]"
					}
				} else {
					variable.observers -= 1
					if variable.observers <= 0 {
						dealocatedVariables.append(index)
					}
					
					if variable.vectorLength != vectorLength {
						//if the vector lengths are incorrect then fix it
						if vectorLength == 3 {
							//float to float3
							return "float3(v\(index - constantsLength))"
						} else {
							//float3 to float
							return "v\(index - constantsLength).x"
						}
					} else {
						return "v\(index - constantsLength)"
					}
				}
			} else {
				throw NodeCompilationError.noVariable
			}
		}
		
		//generates names of variables node can use and calls a function that generates that appropiate code
		func compileNode(node: Node) throws {
			var outputVariables: [String] = []
			var inputVariables: [String] = []
			for c in node.outputRange {
				let output = node[c]
				let address = createValueAddress(node: node, valueIndex: c)
				let observors = getPathsAt(address: address).count
				
				if observors > 0 {
					outputVariables.append(createVarialbe(Variable(value: address, observers: observors, vectorLength: output.type.length)))
				} else {
					outputVariables.append("empty\(output.type.length)")
				}
			}
			
			for c in node.inputRange {
				var address: NodeValueAddress = createValueAddress(node: node, valueIndex: c)
				let input = node[c]
				
				//should only be one path per input
				if let path = getPathsAt(address: address).first {
					address = path.beggining
				}
				
				do {
					let tempVar = try findVariable(value: address, vectorLength: input.type.length)
					inputVariables.append(tempVar)
				} catch {
					throw error
				}
			}
			
			tempCode.append(node.generateCommand(outputs: outputVariables, inputs: inputVariables, unique: "\(unique)"))
			unique += 1
		}
		
		for layer in layers {
			for node in layer {
				do {
					try compileNode(node: node)
				} catch {
					throw error
				}
			}
		}
		
		if variables.count - constantsLength > 0 {
			var createdVariables: String = ""
			for c in 0..<(variables.count - constantsLength) {
				let length = variables[c + constantsLength].vectorLength
				if length == 1 {
					createdVariables += "float "
				} else {
					createdVariables += "float3 "
				}
				
				createdVariables += "v\(c);\n"
			}
			
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
				
				//find variables in reverse to decrease chance of deallocating to early
				var tempInputVariables: [String] = []
				
				if input.type == .float3 || input.type == .color {
					tempInputVariables.append(findVariable(value: address, vectorIndex: 2))
					tempInputVariables.append(findVariable(value: address, vectorIndex: 1))
				}
				
				tempInputVariables.append(findVariable(value: address, vectorIndex: 0))
				
				tempInputVariables.reverse()
				
				inputVariables += tempInputVariables
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
