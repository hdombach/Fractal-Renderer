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
	var position: CGPoint
	var node: Node
	
    var body: some View {
		ZStack {
			node.color.opacity(0.5)
			Text(node.name)
		}.onTapGesture {
			var new = node.new()
			new.position = position.scale(-1) + CGPoint(x: 100, y: 100)
			nodes.append(new)
		}.cornerRadius(5)
    }
}

struct NodeMenuItem_Previews: PreviewProvider {
    static var previews: some View {
		NodeMenuItem(nodes: .constant([]), position: .init(), node: AddNode())
    }
}
