//
//  RenderBox.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 8/5/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import SwiftUI

struct RenderBox: View {
	@EnvironmentObject var settings: ObservedRenderSettings
	@State var samples: Int = 50
	@State var groups: Int = 100
	@State var groupSize: Int = 100

	func render() {
		Engine.Settings.samples += self.samples
		Engine.Settings.window = .rendering
		if Engine.Settings.samples == Engine.Settings.exposure {
			Engine.ResetRender()
		}
	}

	func preview() {
		Engine.Settings.window = .preview
		Engine.Settings.exposure = 0
		Engine.ResetTexture()
	}

    var body: some View {
		GroupBox(label: Text("Render Time! \(Int.random(in: 0...9))")) {
			HStack {
				VStack(alignment: .leading) {
					Button(action: render) {
						Text("Render")
					}
					Button(action: preview) {
						Text("Pause")
					}
					Text(Engine.Settings.progress)
				}
				Spacer()
				VStack {
					IntInput(value: $samples, name: "Samples")
					IntInput(value: $settings.kernalSize.1, name: "Kernel groups", min: 0)
					IntInput(value: $settings.kernalSize.0, name: "Kernel group size", max: Engine.MaxThreadsPerGroup, min: 0)
				}
			}
		}
    }
}

struct RenderBox_Previews: PreviewProvider {
    static var previews: some View {
        RenderBox()
    }
}
