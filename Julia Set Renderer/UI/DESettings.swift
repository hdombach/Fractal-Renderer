//
//  DESettings.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 4/21/21.
//  Copyright © 2021 Hezekiah Dombach. All rights reserved.
//

import SwiftUI

struct DESettings: View {
	var document: Document
	@ObservedObject var content: Content
	
	init(doc: Document) {
		self.document = doc
		self.content = doc.content
	}
	
	@State var code: String = ""
	
	
    var body: some View {
		NodeEditor(nodeContainer: $content.deNodeContainer, document: document)
    }
}

struct DESettings_Previews: PreviewProvider {
    static var previews: some View {
		// DESettings()
		Text("Hi")
    }
}
