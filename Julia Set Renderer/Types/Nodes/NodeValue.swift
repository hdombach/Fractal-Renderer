//
//  NodeValue.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 12/30/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import Foundation

enum NodeValueType {
	case float
	case float3
	case int
}

/*class NodeValue: Equatable {
	static func == (lhs: NodeValue, rhs: NodeValue) -> Bool {
		false
	}
	
	var float: Float {
		get { 0 }
		set { }
	}
	
	var float3: Float3 {
		get { .init() }
		set { }
	}
	
	var int: Int {
		get { 0 }
		set { }
	}
	
	var name: String { "" }
	
	var type: NodeValueType { .float }
	
	var position: CGPoint = .init()
}*/



protocol NodeValue {
	var float: Float { get set }
	var float3: Float3 { get set }
	var int: Int { get set }
	var name: String { get }
	
	///Offset within parent node
	//var position: CGPoint? { get set }
	var type: NodeValueType { get set }
}

struct NodeFloat: NodeValue {
	var value: Float
	var position: CGPoint?
	var type: NodeValueType = .float
	private var personalName: String?
	
	init(_ value: Float, name initName: String?) {
		self.value = value
		self.personalName = initName
	}
	
	var float: Float {
		get { value }
		set { value = newValue }
	}
	var float3: Float3 {
		get { Float3(value, value, value) }
		set { value = newValue.x}
	}
	var int: Int {
		get { Int(value) }
		set { value = Float(newValue) }
	}
	
	var name: String {
		get { personalName ?? ""}
	}
}

struct NodeFloat3: NodeValue {
	var value: Float3
	var position: CGPoint?
	var type: NodeValueType = .float3
	private var personalName: String?
	
	init(_ value: Float3, name initName: String?) {
		self.value = value
		self.personalName = initName
	}
	
	var float: Float {
		get { value.x }
		set { value = Float3(newValue, newValue, newValue )}
	}
	var float3: Float3 {
		get { value }
		set { value = newValue }
	}
	var int: Int {
		get { Int(value.x) }
		set { value = Float3(Float(newValue), Float(newValue), Float(newValue))}
	}
	
	var name: String {
		get { personalName ?? ""}
	}
}

struct NodeInt: NodeValue {
	var value: Int
	var position: CGPoint?
	var type: NodeValueType = .int
	private var personalName: String?
	
	init(_ value: Int, name initName: String?) {
		self.value = value
		self.personalName = initName
	}
	
	var float: Float {
		get { Float(value) }
		set { value = Int(newValue) }
	}
	var float3: Float3 {
		get { Float3(Float(value), Float(value), Float(value)) }
		set { value = Int(newValue.x) }
	}
	var int: Int {
		get { value }
		set { value = newValue }
	}
	
	var name: String {
		get { personalName ?? ""}
	}
}
