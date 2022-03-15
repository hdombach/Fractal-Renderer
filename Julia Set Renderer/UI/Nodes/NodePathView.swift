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
				let endingPoint = nodeContainer.getPosition(value: nodePath.beggining)
				let begginingPoint = nodePath.ending
                
                path.move(to: begginingPoint)
                path.addLine(to: endingPoint)
			}.stroke(Color.primary)
		}
	}
}

struct NodePathView_Previews: PreviewProvider {
    static var previews: some View {
        Path { path in
            let endingPoint = CGPoint(x: 100, y: 200)
            let begginingPoint = CGPoint(x: 200, y: -1000)
            
            path.move(to: begginingPoint)
            path.addLine(to: endingPoint)
        }.stroke(Color.primary)
    }
}
