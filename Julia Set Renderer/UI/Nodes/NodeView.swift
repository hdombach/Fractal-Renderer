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
	
	var gridSize: CGFloat {
		get {
			nodeContainer.gridSize
		}
	}
	
	var node: Node? {
		get {
			nodeContainer[nodeAddress]
		}
		
		set {
			nodeContainer[nodeAddress] = newValue
		}
	}
	
	static func == (lhs: NodeView, rhs: NodeView) -> Bool {
		if let lnode = lhs.node, let rnode = rhs.node {
			return lnode == rnode
		} else {
			return false
		}
	}
	
    var body: some View {
		if let node = node {
			ZStack {
				Color.controlBackgroundColor.opacity(0.6)
				VStack(spacing: 0) {
					
					ZStack {
						node.color.opacity(0.4)
						Text(node.name)
					}.frame(height: gridSize)
					if node.outputs.count > 0 {
						ForEach(0..<node.outputs.count) { c in
							
							NodeOutputView(valueAddress: nodeContainer.createValueAddress(node: node, valueIndex: c), nodeContainer: $nodeContainer)
							
						}.frame(alignment: Alignment.leading)
					}
					
					if node.inputs.count > 0 {
						ForEach(0..<node.inputs.count) { c in
							NodeInputView(valueAddress: nodeContainer.createValueAddress(node: node, valueIndex: c + node.outputs.count), nodeContainer: $nodeContainer)
							
						}
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
}

struct ColorRampNodeView: View, Equatable {
	var nodeAddress: NodeAddress
	
	@Binding var nodeContainer: NodeContainer
	
	@Binding var selected: Node?
	
	var gridSize: CGFloat {
		get {
			nodeContainer.gridSize
		}
	}
	
	@Binding var node: Node
	@Binding var values: [ColorRampValue]
	
	func sortValues() {
		values.sort { (lesser, greater) -> Bool in
			lesser.position < greater.position
		}
	}

	
	@State private var startPosition: Float?
	@State private var selectedPoint: Int?
	
	private func dragGesture(index: Int, frameWidth: CGFloat) -> some Gesture {
		DragGesture().onEnded { (data) in
			let pos = startPosition! + Float(data.translation.width / frameWidth)
			if pos > 1 {
				values[index].position = 1
			} else if pos < 0 {
				values[index].position = 0
			} else {
				values[index].position = pos
			}
			sortValues()
			startPosition = nil
		}.onChanged { (data) in
			if startPosition == nil {
				startPosition = values[index].position
			}
			let pos = startPosition! + Float(data.translation.width / frameWidth)
			if pos > 1 {
				values[index].position = 1
			} else if pos < 0 {
				values[index].position = 0
			} else {
				values[index].position = pos
			}
			
		}.simultaneously(with: TapGesture().onEnded({ (data) in
			selectedPoint = index
		}))
	}
	
	static func == (lhs: ColorRampNodeView, rhs: ColorRampNodeView) -> Bool {
		return lhs.node == rhs.node
	}
	
	private var gradient: Gradient {
		get {
			var stops: [Gradient.Stop] = []
			for value in values {
				stops.append(.init(color: Color(value.color.cgColor), location: value.position.cgFloat))
			}
			return Gradient(stops: stops)
		}
	}
	
	var body: some View {
		ZStack {
			if nodeContainer.nodes.contains(node) {
				Color.controlBackgroundColor.opacity(0.6)
				VStack(spacing: 0) {
					
					ZStack {
						node.color.opacity(0.4)
						Text(node.name)
					}.frame(height: gridSize)
					if node.outputs.count > 0 {
						ForEach(0..<node.outputs.count) { c in
							
							NodeOutputView(valueAddress: nodeContainer.createValueAddress(node: node, valueIndex: c), nodeContainer: $nodeContainer)
							
						}.frame(alignment: Alignment.leading)
					}
					
					if node.inputs.count > 0 {
						ForEach(0..<node.inputs.count) { c in
							NodeInputView(valueAddress: nodeContainer.createValueAddress(node: node, valueIndex: c + node.outputs.count), nodeContainer: $nodeContainer)
							
						}
					}
					HStack(alignment: .top) {
						Button("+") {
							values.append(ColorRampValue(position: 0, color: Float3(0, 0, 0)))
						}.buttonStyle(PlainButtonStyle())
						Button("-") {
							if let point = selectedPoint {
								values.remove(at: point)
								selectedPoint = nil
							}
						}.buttonStyle(PlainButtonStyle())
						if let c = selectedPoint {
                            NumberInput("", value: $values[c].position, format: .number)
							ColorInput(value: $values[c].color)
						}
						Spacer()
					}.padding(.horizontal).frame(height: gridSize)
					ZStack {
						GeometryReader { reader in
							
							LinearGradient(gradient: gradient, startPoint: .leading, endPoint: .trailing)
							ZStack {
								ForEach(0..<values.count, id: \.self) { c in
									let frame = reader.frame(in: .local)
									let position = CGPoint(x: frame.minX + CGFloat(values[c].position) * frame.width, y: frame.midY)
									Circle()
										.gesture(dragGesture(index: c, frameWidth: frame.width))
										.position(position)
										.overlay(Circle().stroke((selectedPoint ?? -1 == c) ? Color.blue : Color.controlBackgroundColor).position(position))
								}
							}
						}
					}
					.padding(.horizontal)
					.padding(.vertical, 5)
					.frame(height: gridSize)
					Spacer()
					
				}
			}
			
		}
		.frame(width: nodeContainer.nodeWidth, height: gridSize * CGFloat(6), alignment: .center)
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

struct NodeOutputView: View {
	var valueAddress: NodeValueAddress
	@Binding var nodeContainer: NodeContainer
	var dotSize: CGFloat = 8
	
	var gridSize: CGFloat {
		get {
			nodeContainer.gridSize
		}
	}
	
	var node: Node {
		get {
			nodeContainer[valueAddress.nodeAddress()]!
		}
		
		set {
			nodeContainer[valueAddress.nodeAddress()] = newValue
		}
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
	
	var body: some View {
		HStack {
			Spacer()
			Text(nodeContainer[valueAddress]?.name ?? "")
            if let input = nodeContainer[valueAddress] {
                Circle()
                    .fill((nodeContainer[valueAddress]!.type.length == 3) ? Color.gray : Color.primary)
                    .frame(width: dotSize, height: dotSize)
                    .gesture(createPathGesture(valueIndex: valueAddress.valueIndex))
            }
		}.frame(height: gridSize, alignment: .center)
	}
}

struct NodeInputView: View {
	var valueAddress: NodeValueAddress
	@Binding var nodeContainer: NodeContainer
	var dotSize: CGFloat = 8
	
	var gridSize: CGFloat {
		get {
			nodeContainer.gridSize
		}
	}
	
	var node: Node {
		get {
			nodeContainer[valueAddress.nodeAddress()]!
		}
		
		set {
			nodeContainer[valueAddress.nodeAddress()] = newValue
		}
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
		HStack(alignment: .center) {
			Circle()
				.fill(((nodeContainer[valueAddress]?.type.length) ?? 1 == 3) ? Color.gray : Color.primary)
				.frame(width: dotSize, height: dotSize)
				.gesture(deletePathGesture(valueIndex: valueAddress.valueIndex))
				
				
            if (nodeContainer[valueAddress] != nil) {
                NodeValueView(value: Binding.init(get: {
                    nodeContainer[valueAddress]!
                }, set: { (newValue) in
                    nodeContainer[valueAddress] = newValue
                }))
            }
			
			Spacer()
		}.frame(height: gridSize * CGFloat((nodeContainer[valueAddress]?.type.length ?? 1)), alignment: .center)
	}
}

struct NodeValueView: View {
	@Binding var value: NodeValue
	
	var body: some View {
		switch value.type {
		case .float:
            NumberInput(value.name, value: $value.float, format: .number)
		case .float3:
			Tuple3FloatInput(value: $value.float3, name: value.name)
		case .int:
            NumberInput(value.name, value: $value.int, format: .number)
		case .color:
			ColorInput(value: $value.float3, name: value.name)
		case .float4:
			Tuple4FloatInput(value: $value.float4, name: value.name)
		}
	}
}

struct Node_Previews: PreviewProvider {
	static var container = NodeContainer()
	static var node = ColorRampNode()
	static var adress: NodeAddress!
	
    static var previews: some View {
		node.position = CGPoint(x: 200, y: 200)
		container.nodes.append(node)
		return NodeIterateView(nodeAddress: container.createNodeAddress(node: node), nodeContainer: .constant(container), selected: .constant(nil))
    }
}
