//
//  SideBarViews.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 5/22/21.
//  Copyright © 2021 Hezekiah Dombach. All rights reserved.
//

import SwiftUI

struct SideBarView: View {
	@Binding var nodeContainer: NodeContainer
	@Binding var position: CGPoint
	var selected: Node?
	
    var body: some View {
		if (selected != nil && selected!.type == .iterate) {
			SideBarIterate(nodeContainer: $nodeContainer, address: nodeContainer.createNodeAddress(node: selected!))
		} else {
			SideBarList(nodeContainer: $nodeContainer, position: $position)
		}
    }
}

struct SideBarList: View {
	
	@Binding var nodeContainer: NodeContainer
	@Binding var position: CGPoint
	
	var body: some View {
		ForEach(Array(NodeType.allCases), id: \.self) { type in
			NodeMenuItem(nodes: $nodeContainer.nodes, position: position, node: Node(type))
		}
	}
}

struct SideBarIterate: View {
	struct ItemView: View {
		@Binding var value: NodeValue
		var selected = false
		var body: some View {
			HStack {
				Spacer()
				TextField("Name", text: $value.name).textFieldStyle(PlainTextFieldStyle())
			}.background(selected ? Color.blue : Color.controlBackgroundColor)
		}
	}
	
	func add() {
		if var old = iterateValue {
			old.repeatedValues.append(NodeFloat("Value"))
			setIterateValue(newValue: old)
		}
	}
	
	func delete() {
		if let selected = selected, var value = iterateValue {
			value.repeatedValues.remove(at: selected)
			setIterateValue(newValue: value)
			self.selected = nil
		}
	}
	
	@Binding var nodeContainer: NodeContainer
	@State var selected: Int?
	var address: NodeAddress
	
	var node: Node? {
		get {
			return nodeContainer[address]
		}
		set {
			nodeContainer[address] = newValue
		}
	}
	
	var iterateValue: IterateNodeValue? {
		return node?.values as? IterateNodeValue
	}
	func setIterateValue(newValue: IterateNodeValue) {
		nodeContainer[address]?.values = newValue
		if let paired = newValue.pairedNode {
			var pairedValues = nodeContainer[paired]?.values as? IterateNodeValue
			pairedValues?.repeatedValues = newValue.repeatedValues
			nodeContainer[paired]?.values = pairedValues
		}
	}
	
	func getBinding(index: Int) -> Binding<NodeValue> {
		return Binding.init(get: {
			iterateValue!.repeatedValues[index]
		}, set: { (newValue) in
			var old = iterateValue
			old!.repeatedValues[index] = newValue
			setIterateValue(newValue: old!)
		})
	}
	
	func getTypeBinding(index: Int) -> Binding<NodeValueType> {
		Binding.init {
			iterateValue!.repeatedValues[index].type
		} set: { (newValue) in
			var old = iterateValue
			old?.repeatedValues[index].type = newValue
			setIterateValue(newValue: old!)
		}

	}
	
	var body: some View {
		if let iterateValue = iterateValue {
			ForEach(0..<iterateValue.repeatedValues.count, id: \.self) { index in
				ItemView(value: getBinding(index: index), selected: selected == index).onTapGesture {
					if index == selected {
						selected = nil
					} else {
						selected = index
					}
				}
			}
			HStack {
				Button("+", action: add).buttonStyle(PlainButtonStyle())
				Button("-", action: delete).disabled(selected == nil).buttonStyle(PlainButtonStyle())
				Spacer()
			}
			if let selected = selected {
				Picker("Values", selection: getTypeBinding(index: selected)) {
					Text("Float").tag(NodeValueType.float)
					Text("Float3").tag(NodeValueType.float3)
					Text("Color").tag(NodeValueType.color)
				}
			}
		}
		
		
	}
}

struct SideBarViews_Previews: PreviewProvider {
    static var previews: some View {
        Text("hi")
    }
}
