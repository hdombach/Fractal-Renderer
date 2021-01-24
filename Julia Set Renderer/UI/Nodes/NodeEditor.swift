//
//  NodeEditor.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 12/31/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import SwiftUI

struct NodeEditor: View {
	
	@Binding var nodeContainer: NodeContainer
	
	@State var isShowingList = true
	
	@State var selected: Node?
	
	@State var zoom: CGFloat = 1
	
    var body: some View {
		VStack(alignment: .leading) {
			HStack {
				Button("􀏚") {
					isShowingList.toggle()
				}.padding(.leading)
				Button("Delete") {
					nodeContainer.delete(node: selected)
				}
				Button("􀊬") {
					zoom *= 1.1
				}
				Button("􀊭") {
					zoom *= 0.9
				}
				Button("􀅈") {
					nodeContainer.compile()
				}
				
				Text(nodeContainer.compilerMessage).foregroundColor(nodeContainer.compilerCompleted ? .green : .red).padding([.trailing, .leading])
			}
			HStack {
				if isShowingList {
					ScrollView(/*@START_MENU_TOKEN@*/.vertical/*@END_MENU_TOKEN@*/, showsIndicators: true, content: {
						ForEach(allNodes, id: \.id) { node in
							NodeMenuItem(nodes: $nodeContainer.nodes, node: node)
						}
					}).frame(width: 150)
					.padding(.bottom)
				}
				NodeCanvas(nodeContainer: $nodeContainer, selected: $selected, zoom: $zoom)
					.padding([.bottom, .trailing])
			}.padding(.leading)
		}.onTapGesture {
			selected = nil
		}
    }
}

struct NodeEditor_Previews: PreviewProvider {
    static var previews: some View {
		/*NodeEditor(nodeContainer: Binding.init(get: {
			Engine.Settings.nodeContainer
		}, set: { (newValue) in
			Engine.Settings.nodeContainer = newValue
		}))*/
		Text("Hi")
    }
}
