//
//  RenderBox.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 8/5/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import SwiftUI

struct RenderBox: View {
    @ObservedObject var settings = Engine.Settings.observed
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
		GroupBox(label: Text("Render Time!")) {
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
					Input(value: $samples, step: 1, name: "Samples", showsName: true)
					Input(value: $settings.kernelSize.1, step: 1, name: "Kernel groups", min: 0, showsName: true)
					Input(value: $settings.kernelSize.0, step: 1, name: "Kernel group size", min: 0, showsName: true)
                    //max: Engine.MaxThreadsPerGroup
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

