//
//  PatternSettings.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 8/20/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import SwiftUI

struct PatternSettings: View {
	var document: Document
	@State var quality: Float = 1
    var body: some View {
        HStack {
            Button(action: {
                print("started loading")
				document.container.loadQuality = quality
				document.content.savedCamera = document.content.camera
				document.container.load(passSize: 10000)
            }) {
                Text("Load Pattern")
            }
            NumberInput("Quality", value: $quality, format: .number)
        }.padding()
    }
}

struct PatternSettings_Previews: PreviewProvider {
    static var previews: some View {
        //PatternSettings()
		Text("hi")
    }
}
