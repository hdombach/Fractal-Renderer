//
//  RenderBox.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 8/5/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import SwiftUI

struct RenderBox: View {
	var document: Document
	@ObservedObject var content: Content
	@ObservedObject var state: ViewSate
	@ObservedObject var renderPassManager: RenderPassManager
	@State var samples: Int = 50
	
	init(doc: Document) {
		document = doc
		content = doc.content
		state = doc.viewState
		renderPassManager = doc.viewState.renderPassManager
	}

	func render() {
		state.startRendering(samplesCount: self.samples)
		
		document.view.changeRenderMode(isManual: false)
		
		print("Started Rendering with camera: \(content.camera)")
	}

	func preview() {
		state.stopRendering()
		document.view.changeRenderMode(isManual: true)
	}

    var body: some View {
		HStack(alignment: .top) {
			VStack(alignment: .leading) {
				Button(action: render) {
					Text("Wender")
				}
				Button(action: preview) {
					Text("Stop")
				}
				Picker(selection: $state.viewportMode, label: Text("")) {
					Text("preview").tag(ViewportMode.preview)
					Text("depth").tag(ViewportMode.depth)
					Text("rendering").tag(ViewportMode.rendering)
				}.pickerStyle(RadioGroupPickerStyle())
				Text(renderPassManager.progress)
			}
			Spacer()
			VStack {
                NumberInput("Samples", value: $samples, format: .number)
                NumberInput("Kernel groups", value: $content.kernelSize.y, format: .number)
                NumberInput("Kernel group size", value: $content.kernelSize.x, format: .number)
				//max: Engine.MaxThreadsPerGroup
				if (state.viewportMode == .depth) {
					Tuple3FloatInput(value: $content.depthSettings)
				}
                NumberInput("Ambient Shading", value: $content.shadingSettings.x, format: .number)
                NumberInput("Angle Shading", value: $content.shadingSettings.y, format: .number)
			}
		}
		.padding()
    }
}

struct RenderBox_Previews: PreviewProvider {
    static var previews: some View {
        //RenderBox()
		Text("huwu")
    }
}

