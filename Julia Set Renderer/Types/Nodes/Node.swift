//
//  Node.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 12/30/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import Foundation
import SwiftUI

protocol Node {
	var name: String { get }
	var color: Color { get }
}

struct MaterialNode: Node {
	var name: String {
		get { "Material" }
	}
	var color: Color {
		get { Color.green }
	}
	
	
}
