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
				Button("Show Nodes") {
					isShowingList.toggle()
				}.padding(.leading)
				Button("Delete") {
					nodeContainer.delete(node: selected)
					selected = nil
				}
				Button("+") {
					zoom *= 1.1
				}
				Button("-") {
					zoom *= 0.9
				}
				Button("Compile") {
					//nodeContainer.compile()
					do {
						try nodeContainer.compile(library: document.graphics.library, viewState: document.viewState)
					} catch {
						print(error)
					}
				}
				
				Text(nodeContainer.compilerMessage).foregroundColor(nodeContainer.compilerCompleted ? .green : .red).padding([.trailing, .leading])
			}.zIndex(100)
			HStack {
				if isShowingList {
					ScrollView(/*@START_MENU_TOKEN@*/.vertical/*@END_MENU_TOKEN@*/, showsIndicators: true, content: {
						SideBarView(nodeContainer: $nodeContainer, position: $position, selected: selected)
					}).frame(width: 150)
					.padding(.bottom)
					.zIndex(100)
				}
				NodeCanvas(nodeContainer: $nodeContainer, position: $position, selected: $selected, zoom: $zoom)
					.padding([.bottom, .trailing])
					.clipped()
			}.padding(.leading)
		}.onTapGesture {
			selected = nil
		}
    }
}

struct NodeEditor_Previews: PreviewProvider {
    static var previews: some View {
		NodeEditor(nodeContainer: Binding.constant(NodeContainer.init()), document: Document.init())
    }
}
