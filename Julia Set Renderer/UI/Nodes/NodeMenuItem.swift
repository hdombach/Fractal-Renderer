//
//  NodeMenuItem.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 12/30/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import SwiftUI

struct NodeMenuItem: View {
	@Binding var nodes: [Node]
	var node: Node
	
    var body: some View {
		ZStack {
			node.color.opacity(0.5)
			Text(node.name)
		}.onTapGesture {
			nodes.append(node.new())
		}.cornerRadius(5)
    }
}

struct NodeMenuItem_Previews: PreviewProvider {
    static var previews: some View {
		NodeMenuItem(nodes: .constant([]), node: AddNode())
    }
}
