//
//  NodeCanvas.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 12/30/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import SwiftUI

struct NodeCanvas: View {
	
	@Binding var nodeContainer: NodeContainer
	
	@State var dragOffset: CGPoint?
	
	@Binding var position: CGPoint
	
	@Binding var selected: Node?
	
	@Binding var zoom: CGFloat
	
	func linkActivePath() {
		print("link")
	}
	
	var body: some View {
		GeometryReader { geometry in
			GroupBox {
				ZStack() {
					ForEach(nodeContainer.paths) { path in
                        NodePathView(nodePath: path, nodeContainer: nodeContainer)
                            .border(Color.init(.sRGB, white: 1, opacity: 0.1), width: 0.1)
					}
					ForEach(nodeContainer.nodes, id: \.id) { node in
						let c = nodeContainer.index(node.id)
						node.generateView(container: $nodeContainer, selected: $selected).gesture(
						//NodeView(nodeAddress: nodeContainer.createNodeAddress(node: node), nodeContainer: $nodeContainer, selected: $selected).gesture(
							DragGesture().onChanged({ (data) in
								if dragOffset == nil {
									dragOffset = data.location - node.position
								}
								nodeContainer.nodes[c].position = data.location - dragOffset!
								//print("drag", (data.location - dragOffset!))
							}).onEnded({ (data) in
								dragOffset = nil
							})
						)
					}
					if nodeContainer.activePath != nil {
						NodeDraggableView(nodePath: nodeContainer.activePath, nodeContainer: nodeContainer)
                            .border(Color.init(.sRGB, white: 1, opacity: 0.1), width: 0.1)
					}
				}
				.coordinateSpace(name: "Canvas")
				.position(CGPoint.init(x: position.x + geometry.size.width / 2, y: position.y + geometry.size.height / 2))
				.scaleEffect(zoom)
			}.clipped()
			.gesture(
				DragGesture().onChanged({ (data) in
					if dragOffset == nil {
						dragOffset = data.location - position
					}
					position = data.location - dragOffset!
				}).onEnded({ (data) in
					dragOffset = nil
				})
			)
		}
		
	}
}

struct NodeCanvas_Previews: PreviewProvider {
    static var previews: some View {
		Text("Hi")
    }
}
