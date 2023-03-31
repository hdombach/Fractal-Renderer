//
//  NodeSource.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 11/13/21.
//  Copyright © 2021 Hezekiah Dombach. All rights reserved.
//

import Foundation
import SwiftUI

struct NodeSource {
	var name: String
	var code: String
    var color = Color.red
    var id = UUID()
    
    var inputs: [NodeValue] = []
    var outputs: [NodeValue] = []
    
    
    
}
