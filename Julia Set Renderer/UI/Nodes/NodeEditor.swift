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
	
	@State var position: CGPoint = .init(x: 100, y: 100)
	
	var document: Document
	
    var body: some View {
		VStack(alignment: .leading) {
			HStack {
				Button("􀏚") {
					isShowingList.toggle()
				}.padding(.leading)
				Button("Delete") {
					nodeContainer.delete(node: selected)
					selected = nil
				}
				Button("􀊬") {
					zoom *= 1.1
				}
				Button("􀊭") {
					zoom *= 0.9
				}
				Button("􀅈") {
					//nodeContainer.compile()
					do {
						try nodeContainer.compile(library: document.graphics.library, viewState: document.viewState)
					} catch {
						print(error)
					}
				}
				
				Text(nodeContainer.compilerMessage).foregroundColor(nodeContainer.compilerCompleted ? .green : .red).padding([.trailing, .leading])
			}
			HStack {
				if isShowingList {
					ScrollView(/*@START_MENU_TOKEN@*/.vertical/*@END_MENU_TOKEN@*/, showsIndicators: true, content: {
						ForEach(Array(NodeType.allCases), id: \.self) { type in
							NodeMenuItem(nodes: $nodeContainer.nodes, position: position, node: Node(type))
						}
					}).frame(width: 150)
					.padding(.bottom)
					.zIndex(100)
				}
				NodeCanvas(nodeContainer: $nodeContainer, position: $position, selected: $selected, zoom: $zoom)
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
