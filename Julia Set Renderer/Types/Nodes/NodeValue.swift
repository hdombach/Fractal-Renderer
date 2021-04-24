//
//  NodeValue.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 12/30/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import Foundation
import SwiftUI

enum NodeValueType: String, Codable {
	case float
	case float3
	case int
	case color
	
	var isVector: Bool {
		get {
			self == .float3 || self == .color
		}
	}
	
	var length: Int {
		get {
			switch self {
			case .float:
				return 1
			case .float3:
				return 3
			case .int:
				return 1
			case .color:
				return 3
			}
		}
	}
}

struct NodeValue: Codable, Equatable {
	private var value = Float3(repeating: 0)
	var position: CGPoint?
	var type: NodeValueType = .float3
	var name = ""
	
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
}

func NodeFloat(_ value: Float, name initName: String?) -> NodeValue {
	var result =  NodeValue()
	result.float = value
	result.type = .float
	result.name = initName ?? ""
	
	return result
}
func NodeFloat(_ initName: String?) -> NodeValue {
	var result = NodeValue()
	result.type = .float
	result.name = initName ?? ""
	
	return result
}

func NodeFloat3(_ value: Float3, name initName: String?) -> NodeValue {
	var result = NodeValue()
	result.float3 = value
	result.type = .float3
	result.name = initName ?? ""
	
	return result
}
func NodeFloat3(_ value1: Float, _ value2: Float, _ value3: Float, name initName: String?) -> NodeValue {
	return NodeFloat3(Float3(value1, value2, value3), name: initName)
}
func NodeFloat3(_ initName: String?) -> NodeValue {
	var result = NodeValue()
	result.type = .float3
	result.name = initName ?? ""
	
	return result
}

func NodeColor(_ value: Float3, name initName: String?) -> NodeValue {
	var result = NodeValue()
	result.float3 = value
	result.type = .color
	result.name = initName ?? ""
	
	return result
}
func NodeInt(_ value: Int, name initName: String?) -> NodeValue {
	var result = NodeValue()
	result.int = value
	result.type = .int
	result.name = initName ?? ""
	
	return result
}

protocol _NodeValue: Codable {
	var float: Float { get set }
	var float3: Float3 { get set }
	var int: Int { get set }
	var name: String { get }
	
	///Offset within parent node
	//var position: CGPoint? { get set }
	var type: NodeValueType { get set }
}

struct _NodeFloat: _NodeValue {
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

struct _NodeColor: _NodeValue {
	var value: Float3
	var position: CGPoint?
	var type: NodeValueType = .color
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

struct _NodeFloat3: _NodeValue {
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

struct _NodeInt: _NodeValue {
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
