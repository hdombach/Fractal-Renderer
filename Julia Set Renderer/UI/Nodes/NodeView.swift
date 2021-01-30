//
//  Node.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 12/30/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import SwiftUI


struct NodeView: View, Equatable {
	var nodeAddress: NodeAddress
	
	@Binding var nodeContainer: NodeContainer
	
	@Binding var selected: Node?
	
	var viewPosition: CGPoint
	
	let dotSize: CGFloat = 8
	
	var gridSize: CGFloat {
		get {
			nodeContainer.gridSize
		}
	}
	
	var node: Node {
		get {
			nodeContainer[nodeAddress]!
		}
		
		set {
			nodeContainer[nodeAddress] = newValue
		}
	}
	
	static func == (lhs: NodeView, rhs: NodeView) -> Bool {
		return lhs.node.compare(to: rhs.node)
	}
	
	func createPathGesture(valueIndex: Int) -> some Gesture {
		DragGesture().onChanged({ (data) in
			if nodeContainer.activePath == nil {
				nodeContainer.activePath = nodeContainer.createDraggable(node: node, valueIndex: valueIndex)
			} else {
				nodeContainer.activePath?.ending = nodeContainer.getPosition(value: nodeContainer.createValueAddress(node: node, valueIndex: valueIndex)) + CGPoint(x: data.translation.width, y: data.translation.height)
			}
		}).onEnded({ (data) in
			nodeContainer.linkPath()
		})
	}
	
	func deletePathGesture(valueIndex: Int) -> some Gesture {
		DragGesture().onChanged { (data) in
			if nodeContainer.activePath == nil {
				if let path = nodeContainer.getPathsAt(address: nodeContainer.createValueAddress(node: node, valueIndex: valueIndex)).first {
					nodeContainer.delete(path: path)
					
					let begginingNode = nodeContainer[path.beggining.nodeAddress()]
					let draggable = DraggablePath(beggining: nodeContainer.createValueAddress(node: begginingNode!, valueIndex: path.beggining.valueIndex), ending: nodeContainer.getPosition(value: path.ending))
					
					nodeContainer.activePath = draggable
				}
			} else {
				nodeContainer.activePath?.ending = nodeContainer.getPosition(value: nodeContainer.createValueAddress(node: node, valueIndex: valueIndex)) + CGPoint(x: data.translation.width, y: data.translation.height)
			}
		}.onEnded { (data) in
			nodeContainer.linkPath()
		}
	}
	
    var body: some View {
		ZStack {
			Color.controlBackgroundColor.opacity(0.6)
			VStack(spacing: 0) {
				
				ZStack {
					node.color.opacity(0.4)
					Text(node.name)
				}.frame(height: gridSize)
				ForEach(0..<node.outputs.count) { c in
					HStack {
						Spacer()
						Text(node.outputs[c].name)
						
						Circle()
							.frame(width: dotSize, height: dotSize).gesture(createPathGesture(valueIndex: c))
					}.frame(height: gridSize, alignment: .center)
				}.frame(alignment: Alignment.leading)
				ForEach(0..<node.inputs.count) { c in
					HStack(alignment: .center) {
						
						Circle()
							.frame(width: dotSize, height: dotSize)
							.gesture(deletePathGesture(valueIndex: c + node.outputs.count))
						NodeValueView(value: Binding.init(get: {
							node.inputs[c]
						}, set: { (newValue) in
							nodeContainer[nodeAddress]?.inputs[c] = newValue
						}))
						
						Spacer()
					}.frame(height: gridSize * ((node.inputs[c].type == .float3) ? 3 : 1), alignment: .center)
					
				}
				Spacer()
			}
		}
		.frame(width: nodeContainer.nodeWidth, height: gridSize * CGFloat(node.getHeight()), alignment: .center)
		.overlay(
			RoundedRectangle(cornerRadius: 10)
				.stroke((selected != nil && selected!.id == node.id) ? Color.accentColor : Color.clear, lineWidth: 2)
		)
		.cornerRadius(10)
		.shadow(radius: 5)
		.position(node.position)
		.onTapGesture {
			selected = node
		}
    }
}

struct NodeValueView: View {
	@Binding var value: NodeValue
	
	var body: some View {
		switch value.type {
		case .float:
			NumberInput(value: $value.float.nsNumber, name: value.name)
		case .float3:
			Tuple3FloatInput(value: $value.float3, name: value.name)
		case .int:
			NumberInput(value: $value.int.nsNumber, name: value.name)
		}
	}
}

struct Node_Previews: PreviewProvider {
    static var previews: some View {
		GroupBox(label: Text("Content"), content: {
			Text("Hi")
		})
    }
}
