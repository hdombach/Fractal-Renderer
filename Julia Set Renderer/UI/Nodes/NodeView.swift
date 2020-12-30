//
//  Node.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 12/30/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import SwiftUI

struct NodeView: View {
	@State var value: Float = 0
    var body: some View {
		ZStack {
			Color.black.opacity(0.3)
			VStack {
				ZStack {
					Color.green.opacity(0.5)
					Text("Main node")
				}.frame(height: 25)
				NumberInput(value: $value.nsNumber)
				Spacer()
			}
		}.cornerRadius(10)
		.shadow(radius: 10)
    }
}

struct Node_Previews: PreviewProvider {
    static var previews: some View {
		GroupBox(label: Text("Content"), content: {
			NodeView()
		})
    }
}
