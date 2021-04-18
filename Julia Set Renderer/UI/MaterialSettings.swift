//
//  MaterialSettings.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 12/30/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import SwiftUI

struct MaterialSettings: View {
	var document: Document
	@ObservedObject var content: Content
	
	init(doc: Document) {
		self.document = doc
		self.content = doc.content
	}
	
	@State var code: String = ""
	
	
	
	var body: some View {
		NodeEditor(nodeContainer: $content.nodeContainer, document: document)
    }
}

struct MaterialSettings_Previews: PreviewProvider {
    static var previews: some View {
		 //MaterialSettings()
		Text("Asdf")
    }
}
