//
//  NodePathView.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 1/1/21.
//  Copyright © 2021 Hezekiah Dombach. All rights reserved.
//

import SwiftUI

struct NodePathView: View {
	var nodePath: NodePath!
	var nodeContainer: NodeContainer!
	
    var body: some View {
		if nodePath != nil {
			Path { path in
				
				let begginingPoint = nodeContainer.getPosition(value: nodePath.beggining)
				let endingPoint = nodeContainer.getPosition(value: nodePath.ending)
				
				path.addLines([begginingPoint, endingPoint])
			}.stroke(Color.primary)
		}
    }
}

struct NodeDraggableView: View {
	var nodePath: DraggablePath!
	var nodeContainer: NodeContainer!
	
	var body: some View {
		if nodePath != nil {
			Path { path in
				let begginingPoint = nodeContainer.getPosition(value: nodePath.beggining)
				let endingPoint = nodePath.ending
				
				path.addLines([begginingPoint, endingPoint])
			}.stroke(Color.primary)
		}
	}
}

struct NodePathView_Previews: PreviewProvider {
    static var previews: some View {
		Text("na")
    }
}
