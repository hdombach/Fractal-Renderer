//
//  NodePath.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 1/1/21.
//  Copyright © 2021 Hezekiah Dombach. All rights reserved.
//

import Foundation

struct NodeAddress: Equatable, Hashable {
	var nodeIndex: Int
	 
	///Identifies the node it is pointing to
	var id: UUID
	
	func nodeValueAddress(valueIndex: Int) -> NodeValueAddress {
		return NodeValueAddress(nodeIndex: nodeIndex, valueIndex: valueIndex, id: id)
	}
}

struct NodeValueAddress: Equatable, Hashable {
	var nodeIndex: Int
	var valueIndex: Int
	
	///Idetintifies the node it is pointing to
	var id: UUID
	
	func nodeAddress() -> NodeAddress {
		return NodeAddress(nodeIndex: nodeIndex, id: id)
	}
}

struct DraggablePath {
	var id = UUID()
	
	var beggining: NodeValueAddress
	var ending: CGPoint
}

//will be stored in end node
struct NodePath: Equatable, Identifiable {
	///Identifies the path
	var id = UUID()
	
	static func == (lhs: NodePath, rhs: NodePath) -> Bool {
		return lhs.beggining == rhs.beggining && lhs.ending == rhs.ending
	}
	
	var beggining: NodeValueAddress
	var ending: NodeValueAddress
}
