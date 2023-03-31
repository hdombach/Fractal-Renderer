//
//  IterateNodeView.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 5/6/21.
//  Copyright © 2021 Hezekiah Dombach. All rights reserved.
//

import SwiftUI



struct NodeIterateView: View {
	var nodeAddress: NodeAddress
	
	@Binding var nodeContainer: NodeContainer
	
	@Binding var selected: Node?
	
	var gridSize: CGFloat {
		get {
			nodeContainer.gridSize
		}
	}
	
	var node: Node? {
		get {
			nodeContainer[nodeAddress]
		}
	}
	var nodeValue: IterateNodeValue? {
		get {
			node?.values as? IterateNodeValue
		}
	}
	
	var draggedPosition: CGPoint? {
		get {
			nodeValue?.draggedPosition
		}
	}
	
	var iterateEnd: Node? {
		get {
			if let address = nodeValue?.pairedNode {
				let endNode = nodeContainer[address]
				if (nodeValue?.pairedNode)?.id == endNode?.id {
					return endNode
				}
			}
			return nil
		}
	}
	var endPoint: CGPoint? {
		if let pos = draggedPosition {
			return pos
		} else if let pos = iterateEnd?.position {
			return pos + CGPoint(x: nodeContainer.nodeWidth / -2, y: ((node?.getHeight().cgfloat ?? CGFloat()) / -2 + 1) * nodeContainer.gridSize)
		} else {
			return nil
		}
	}
	
	var startPoint: CGPoint {
		(node?.position ?? CGPoint()) + CGPoint(x: nodeContainer.nodeWidth / 2, y: ((node?.getHeight().cgfloat ?? CGFloat()) / -2 + 0.5) * nodeContainer.gridSize)
	}

	
	func createPathGesture() -> some Gesture {
		DragGesture().onChanged({ (data) in
			setPairedNode(nil)
			setDraggedPosition(startPoint + CGPoint(x: data.translation.width, y: data.translation.height))
		}).onEnded({ (data) in
			setDraggedPosition(nil)
			setPairedNode(nodeContainer.getIntersectedNode(point: startPoint + CGPoint(x: data.translation.width, y: data.translation.height)))
		})
	}
	
	func setDraggedPosition(_ newPosition: CGPoint?) {
		var oldValue = (nodeContainer[nodeAddress]?.values as? IterateNodeValue)
		oldValue?.draggedPosition = newPosition
		nodeContainer[nodeAddress]?.values = oldValue
	}
	
	func setPairedNode(_ newPairedAddress: NodeAddress?) {
		var oldValue = (nodeContainer[nodeAddress]?.values as? IterateNodeValue)
		
		if let oldPairedAddress = oldValue?.pairedNode {
			if var oldPairedValue = nodeContainer[oldPairedAddress]?.values as? IterateNodeValue {
				oldPairedValue.pairedNode = nil
				nodeContainer[oldPairedAddress]?.values = oldPairedValue
			}
		}
		
		if newPairedAddress != nil, var newPairedValue = (nodeContainer[newPairedAddress!]?.values as? IterateNodeValue) {
			newPairedValue.pairedNode = nodeAddress
			newPairedValue.repeatedValues = oldValue!.repeatedValues
			nodeContainer[newPairedAddress!]?.values = newPairedValue
			
			oldValue?.pairedNode = newPairedAddress
		} else {
			oldValue?.pairedNode = nil
		}
		nodeContainer[nodeAddress]?.values = oldValue
	}
	
	func addValue() {
		
	}
	
	var body: some View {
		if let node = node {
			if let endPoint = endPoint {
				Path { path in
					
					path.addLines([startPoint, endPoint])
				}.stroke(Color.primary)
			}
			ZStack {
				Color.controlBackgroundColor.opacity(0.6)
				VStack(spacing: 0) {
					
					ZStack {
						node.color.opacity(0.4)
						Text(node.name)
						HStack {
							Spacer()
							Circle().frame(width: nodeContainer.dotSize, height: nodeContainer.dotSize).gesture(
								createPathGesture()
							)
						}
					}.frame(height: gridSize)
					if !node.outputRange.isEmpty {
						ForEach(node.outputRange, id: \.self) { c in
							
							NodeOutputView(valueAddress: nodeContainer.createValueAddress(node: node, valueIndex: c), nodeContainer: $nodeContainer)
							
						}.frame(alignment: Alignment.leading)
					}
					
					if !node.inputRange.isEmpty {
						ForEach(node.inputRange, id: \.self) { c in
							NodeInputView(valueAddress: nodeContainer.createValueAddress(node: node, valueIndex: c + node.outputs.count), nodeContainer: $nodeContainer)
							
						}
					}
					//Button("Add", action: addValue).frame(height: nodeContainer.gridSize)
					//Text(String(describing: node.outputRange))
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
}

struct NodeIterateEndView: View {
	var nodeAddress: NodeAddress
	
	@Binding var nodeContainer: NodeContainer
	
	@Binding var selected: Node?
	
	var gridSize: CGFloat {
		get {
			nodeContainer.gridSize
		}
	}
	
	var node: Node? {
		get {
			nodeContainer[nodeAddress]
		}
	}
	var nodeValue: IterateNodeValue? {
		get {
			node?.values as? IterateNodeValue
		}
	}
	
	var draggedPosition: CGPoint? {
		get {
			nodeValue?.draggedPosition
		}
	}
	
	var iterateStart: Node? {
		get {
			if let address = nodeValue?.pairedNode {
				let startNode = nodeContainer[address]
				if (startNode?.values as? IterateNodeValue)?.pairedNode?.id == node?.id {
					return startNode
				}
			}
			return nil
		}
	}
	
	var startPoint: CGPoint {
		(node?.position ?? CGPoint()) + CGPoint(x: nodeContainer.nodeWidth / -2, y: ((node?.getHeight().cgfloat ?? CGFloat()) / -2 + 0.5) * nodeContainer.gridSize)
	}
	
	func setDraggedPosition(_ newPosition: CGPoint?) {
		if let pairedAddress = nodeValue?.pairedNode {
			if var pairedValue = (nodeContainer[pairedAddress]?.values as? IterateNodeValue) {
				if pairedValue.pairedNode?.id == node?.id {
					pairedValue.draggedPosition = newPosition
					nodeContainer[pairedAddress]?.values = pairedValue
				}
			}
		}
	}
	
	func setPairedNode(_ newPairedAddress: NodeAddress?) {
		var oldValue = (nodeContainer[nodeAddress]?.values as? IterateNodeValue)
		let oldPairedNode = oldValue?.pairedNode
		oldValue?.pairedNode = nil
		if let startNodeAddress = oldPairedNode {
			if var startNodeValue = (nodeContainer[startNodeAddress]?.values as? IterateNodeValue) {
				if startNodeValue.pairedNode?.id != node?.id {
					//the start node is not valid
					oldValue?.pairedNode = nil
				} else {
					//find new node being connected to
					if newPairedAddress != nil {
						if var newPairedValue = (nodeContainer[newPairedAddress!]?.values as? IterateNodeValue) {
							newPairedValue.pairedNode = startNodeAddress
							nodeContainer[newPairedAddress!]?.values = newPairedValue
						}
					}
					
					startNodeValue.pairedNode = newPairedAddress
					nodeContainer[startNodeAddress]?.values = startNodeValue
					
					oldValue?.repeatedValues = startNodeValue.repeatedValues
				}
				
			}
		}
		
		if nodeAddress.id != newPairedAddress?.id {
			nodeContainer[nodeAddress]?.values = oldValue
		}
	}
	
	
	func createPathGesture() -> some Gesture {
		DragGesture().onChanged({ (data) in
			setDraggedPosition(startPoint + CGPoint(x: data.translation.width, y: data.translation.height))
		}).onEnded({ (data) in
			setDraggedPosition(nil)
			setPairedNode(nodeContainer.getIntersectedNode(point: startPoint + CGPoint(x: data.translation.width, y: data.translation.height)))
		})
	}
	
	var body: some View {
		if let node = node {
			ZStack {
				Color.controlBackgroundColor.opacity(0.6)
				VStack(spacing: 0) {
					
					ZStack {
						node.color.opacity(0.4)
						Text(node.name)
						HStack {
							Circle().frame(width: nodeContainer.dotSize, height: nodeContainer.dotSize).gesture(
								createPathGesture()
							)
							Spacer()
						}
					}.frame(height: gridSize)
					if !(node.outputRange.isEmpty) {
						ForEach(node.outputRange, id: \.self) { c -> NodeOutputView in
							NodeOutputView(valueAddress: nodeContainer.createValueAddress(node: node, valueIndex: c), nodeContainer: $nodeContainer)
							
						}.frame(alignment: Alignment.leading)
					}
					
					if !(node.inputRange.isEmpty) {
						ForEach(node.inputRange, id: \.self) { c in
							NodeInputView(valueAddress: nodeContainer.createValueAddress(node: node, valueIndex: c + iterateStart!.outputs.count), nodeContainer: $nodeContainer)
							
						}
					}
					Spacer()
				}
			}
			.frame(width: nodeContainer.nodeWidth, height: gridSize * CGFloat((iterateStart?.getHeight() ?? node.getHeight() + 1) - 1), alignment: .center)
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
}

struct IterateNodeView_Previews: PreviewProvider {
	static var container = NodeContainer()
	static var node = IterateNode()
	static var adress: NodeAddress!
	
	static var previews: some View {
		node.position = CGPoint(x: 200, y: 200)
		container.nodes.append(node)
		return NodeIterateView(nodeAddress: container.createNodeAddress(node: node), nodeContainer: .constant(container), selected: .constant(nil))
	}
}
