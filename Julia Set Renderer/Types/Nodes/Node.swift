//
//  Node.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 12/30/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import Foundation
import SwiftUI

//let commandDictionary: [String: Int32] = ["Error Node": 0, "Coordinate Node": 1, "Material Node": 2, "DE Node": 3, "Add Node": 4, "Multiply Node": 5, "Divide Node": 6, "Is Greater Node": 7, "Combine Node": 8, "Seperate Node": 9]

enum NodeType: String, Codable, CaseIterable {
	//io nodes
	case coordinate
	case orbit
	case color
	case material
	case de
	case float3
	case float
	
	//math nodes
	case add
	case subtract
	case multiply
	case divide
	case isGreater
	case combine
	case seperate
	case clamp
	case sin
	case cos
	case abs
	case map
	case mod
	case exp
	case log
	
	//vector nodes
	case vectorAdd
	case vectorLength
	case vectorScale
	case vectorMap
	case dotProduct
	case crossProduct
	case vectorMultiply
	case vectorClamp
	case vectorMod
	
	//Texture Nodes
	case perlin
	case perlin3
	
	//color
	case colorBlend
	case colorRamp
	
	//flow
	case iterate
	case iterateEnd
	
	//DE
	case mandelbulbDE
	case sphereDE
	case boxDE
	case juliaDE
	case mandelboxDE
	case intersect
	case union
	case difference
	case smoothIntersect
	case smoothUnion
	case smoothDifference
	case mirror
	case rotate
}

let allNodes: [NodeType: () -> Node] = [
	.coordinate: CoordinateNode,
	.orbit: OrbitNode,
	.material: MaterialNode,
	.color: ColorNode,
	.de: DENode,
	.float3: Float3Node,
	.float: FloatNode,
	.add: AddNode,
	.subtract: SubtractNode,
	.multiply: MultiplyNode,
	.divide: DivideNode,
	.isGreater: IsGreaterNode,
	.combine: CombineNode,
	.seperate: SeperateNode,
	.clamp: ClampNode,
	.sin: SinNode,
	.cos: CosNode,
	.abs: AbsNode,
	.map: MapNode,
	.mod: ModNode,
	.exp: ExpNode,
	.log: LogNode,
	.vectorAdd: VectorAddNode,
	.vectorLength: VectorLengthNode,
	.vectorScale: VectorScaleNode,
	.vectorMap: VectorMapNode,
	.dotProduct: DotProductNode,
	.crossProduct: CrossProductNode,
	.vectorMultiply: VectorMultiplyNode,
	.vectorClamp: VectorClampNode,
	.vectorMod: VectorModNode,
	.perlin: PerlinNode,
	.perlin3: Perlin3Node,
	.colorBlend: ColorBlendNode,
	.colorRamp: ColorRampNode,
	.iterate: IterateNode,
	.mandelbulbDE: MandelbulbDENode,
	.sphereDE: SphereDENode,
	.boxDE: BoxDENode,
	.juliaDE: juliaDENode,
	.mandelboxDE: mandelboxDENode,
	.intersect: IntersectNode,
	.union: UnionNode,
	.difference: DifferenceNode,
	.smoothIntersect: SmoothIntersectNode,
	.smoothUnion: SmoothUnionNode,
	.smoothDifference: SmoothDifferenceNode,
	.mirror: MirrorNode,
	.rotate: RotateNode,
	.iterateEnd: IterateEndNode
]



struct Node: Codable, Equatable {
	
	var name: String = "Error"
	var functionName = "error"
	var color = Color.red
	var id = UUID()
	var position = CGPoint()
	
	var type: NodeType = .coordinate
	
	var inputs: [NodeValue] = []
	var outputs: [NodeValue] = []
	
	var values: Any?
	
	init() {}
	init(_ type: NodeType) {
		self = allNodes[type]!()
	}
	
	// Methods
	var _generateCommand: ([String], [String], String, Node) -> String = {outputs, inputs, unique, node in
		var code = "node::" + node.functionName + "("
		for output in outputs {
			code += "&" + output + ", "
		}
		for input in inputs {
			code += input + ", "
		}
		code.removeLast(2)
		code.append(");\n")
		
		return code
	}
	func generateCommand(outputs: [String], inputs: [String], unique: String) -> String {
		_generateCommand(outputs, inputs, unique, self)
	}
	
	var _generateView: (Binding<NodeContainer>, Binding<Node?>, Node) -> AnyView = {container, selected, node in
		return AnyView(NodeView(nodeAddress: container.wrappedValue.createNodeAddress(node: node), nodeContainer: container, selected: selected))
	}
	func generateView(container: Binding<NodeContainer>, selected: Binding<Node?>) -> AnyView {
		_generateView(container, selected, self)
	}
	
	var _outputRange: (Node) -> Range<Int> = { node in
		return 0..<node.outputs.count
	}
	var outputRange: Range<Int> { _outputRange(self) }
	
	var _inputRange: (Node) -> Range<Int> = { node in
		return node.outputs.count..<node.outputs.count + node.inputs.count
	}
	var inputRange: Range<Int> { _inputRange(self) }
	
	var _getSubscript: (Int, Node) -> NodeValue? = {valueIndex, node in
		if node.outputs.count > valueIndex {
			return node.outputs[valueIndex]
		} else {
			return node.inputs[valueIndex - node.outputs.count]
		}
	}
	var _setSubscript: (Int, NodeValue?, inout Node) -> Void = {valueIndex, newValue, node in
		if let newValue = newValue {
			if node.outputs.count > valueIndex {
				node.outputs[valueIndex] = newValue
			} else {
				node.inputs[valueIndex - node.outputs.count] = newValue
			}
		}
	}
	subscript(valueIndex: Int) -> NodeValue? {
		get { _getSubscript(valueIndex, self) }
		set { _setSubscript(valueIndex, newValue, &self) }
	}
	
	var _getHeight: (Node) -> Int = { node in
		var height: Int = 2
		for value in node.inputs {
			height += value.type.length
		}
		
		height += node.outputs.count
		return height
	}
	func getHeight() -> Int { _getHeight(self) }
	
	var _compareValues: (Node, Node) -> Bool = {_, _ in return true }
	
	var _compare: (Node, Node) -> Bool = { lhs, rhs in
		let id = lhs.id == rhs.id
		let pos = lhs.position == rhs.position
		let inputs = lhs.inputs == rhs.inputs
		let comp = lhs._compareValues(lhs, rhs)
		return id && pos && inputs && comp
		//return ((lhs.id == rhs.id) && (lhs.position == rhs.position)) && ((lhs.inputs == rhs.inputs) && lhs._compareValues(lhs, rhs))
	}
	
	static func == (lhs: Node, rhs: Node) -> Bool {
		return lhs._compare(lhs, rhs)
	}
	
	
	var _decode: (KeyedDecodingContainer<CodingKeys>, inout Node) throws -> Void = {_,_ in }
	var _encode: (inout KeyedEncodingContainer<CodingKeys>, Node) throws -> Void = {_,_ in }
	
	//Loading from json
	enum CodingKeys: String, CodingKey {
		case name
		case functionName
		case color
		case id
		case position
		case inputs
		case outputs
		case type
		case values
	}
	init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		
		type = try values.decode(NodeType.self, forKey: .type)
		
		self = allNodes[type]!()
		
		
		id = try values.decode(UUID.self, forKey: .id)
		position = try values.decode(CGPoint.self, forKey: .position)
		inputs = try values.decode([NodeValue].self, forKey: .inputs)
		outputs = try values.decode([NodeValue].self, forKey: .outputs)
		
		try _decode(values, &self)
	}
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(type, forKey: .type)
		try container.encode(id, forKey: .id)
		try container.encode(position, forKey: .position)
		try container.encode(inputs, forKey: .inputs)
		try container.encode(outputs, forKey: .outputs)
		
		try _encode(&container, self)
	}
}

enum NodeCodingKeys: String, CodingKey {
	case name
	case functionName
	case color
	case id
	case position
	case inputs
	case outputs
}

struct NodeCustom_Previews: PreviewProvider {
	static var previews: some View {
		GroupBox(label: Text("Content"), content: {
			Text("hi")
			//NodeView(node: Binding.constant(PreviewedNode(position: CGPoint(x: 200, y: 200))), selected: Binding.constant(nil), activePath: .constant(nil), viewPosition: .init())
		})
	}
}
