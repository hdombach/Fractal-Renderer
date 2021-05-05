//
//  FlowNodes.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 4/20/21.
//  Copyright © 2021 Hezekiah Dombach. All rights reserved.
//

import Foundation
import SwiftUI

func IterateNode() -> Node {
	var result = Node()
	result.type = .iterate
	result.name = "Iterate"
	result.functionName = "iterate"
	result.color = .nodeFlow
	
	result.inputs = [NodeInt(10, name: "times")]
	
	result._generateView = {container, selected, node in
		let address = container.wrappedValue.createNodeAddress(node: node)
		
		return AnyView(NodeIterateView(nodeAddress: address, nodeContainer: container, selected: selected))
	}
	
	result._decode = {values, node in
		node.values = try values.decode(NodeAddress.self, forKey: .values)
	}
	result._encode = {container, node in
		if let values = node.values as? NodeAddress {
			try container.encode(values, forKey: .values)
		}
	}
	
	return result
}
