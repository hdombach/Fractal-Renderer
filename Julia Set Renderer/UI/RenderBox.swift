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
		Engine.MainTexture.updateTexture()
		Engine.Settings.samples += self.samples
		Engine.Settings.window = .rendering
		if Engine.Settings.samples == Engine.Settings.exposure {
			Engine.ResetRender()
		}
		Engine.Settings.observed.update()
		print("Started Rendering with camera: \(Engine.Settings.camera)")
	}

	func preview() {
		Engine.Settings.window = .preview
		Engine.Settings.exposure = 0
		Engine.ResetTexture()
		Engine.Settings.observed.update()
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
					NumberInput(value: $samples.nsNumber, step: 1.nsNumber.0, name: "Samples")
					NumberInput(value: $settings.kernelSize.1.nsNumber, step: 1.nsNumber.0, name: "Kernel groups", min: 0)
					NumberInput(value: $settings.kernelSize.0.nsNumber, step: 1.nsNumber.0, name: "Kernel group size", min: 0)
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

