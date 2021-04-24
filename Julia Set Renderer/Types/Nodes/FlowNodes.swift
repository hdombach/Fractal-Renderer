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
	
	return result
}
