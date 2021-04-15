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
			if node.type == .material || node.type == .de {
				if output == nil {
					if (node.type == .material && type == .Material) || (node.type == .de && type == .DE) {
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
						
						constantsAddresses.append(ConstantAddress(address: valueAddress, vector: 0))
						if node[valueIndex].type == .float3 || node[valueIndex].type == .color {
							constantsAddresses.append(ConstantAddress(address: valueAddress, vector: 1))
							constantsAddresses.append(ConstantAddress(address: valueAddress, vector: 2))
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
			
			if let dealocatedIndex = dealocatedVariables.firstIndex(where: { (test) -> Bool in
				variables[test].updateValue(variable: new)
			}) {
				return "v\(dealocatedVariables.remove(at: dealocatedIndex) - constantsLength)"
			} else {
				variables.append(new)
				return "v\(variables.count - 1 - constantsLength)"
			}
			
		}
		
		func findVariable(value: NodeValueAddress, vectorLength: Int) throws -> String {
			if let index = variables.firstIndex(where: { (test) -> Bool in
				test.value.id == value.id && test.value.valueIndex == value.valueIndex
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
						//print("dealocated variable", index - constantsLength)
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
			//print("compiling node\n", node)
			var outputVariables: [String] = []
			var inputVariables: [String] = []
			for c in node.outputRange {
				let output = node[c]
				let address = createValueAddress(node: node, valueIndex: c)
				let observors = getPathsAt(address: address).count
				
				if observors > 0 {
					outputVariables.append(createVarialbe(Variable(value: address, observers: observors, vectorLength: output.type.length)))
					//print("created variable", outputVariables.last, "for node", node)
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
	
}
