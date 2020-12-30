//
//  NodeValue.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 12/30/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import Foundation

protocol NodeValue {
	var float: Float { get set }
	var float3: Float3 { get set }
	var int: Int { get set }
	var name: String { get }
}

struct NodeFloat: NodeValue {
	var value: Float
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
