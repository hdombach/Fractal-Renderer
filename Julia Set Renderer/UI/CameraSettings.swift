//
//  CameraSettings.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 8/5/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import SwiftUI

struct CameraSettings: View {
	@ObservedObject var content: Content
	@ObservedObject var state: ViewSate
	var document: Document
	
	init(doc: Document) {
		self.content = doc.content
		self.state = doc.viewState
		self.document = doc
	}

    var body: some View {
        HStack(alignment: .top) {
            VStack {
				VStack(alignment: .leading) {
					
					Tuple3FloatInput(value: $content.camera.position.xyz, step: 0.01.nsNumber.0, name: "Position")
                }
                Divider()
                VStack(alignment: .leading) {
					NumberInput(value: $content.camera.vfov.nsNumber, name: "Vertical FOV")
					NumberInput(value: $content.camera.lensRadius.nsNumber, step: 0.01, name: "Lense Radius")
					NumberInput(value: $content.camera.focusDistance.nsNumber, step: 0.01, name: "Focus Distance")
					
					//Tuple3FloatInput(value: $settings.camera.deriction.xyz, step: 0.01.nsNumber.0, name: "Dericiton")
                }
            }
            Divider()
            VStack() {
                Text("Other")
				//NumberInput(value: $settings.camera.zoom.nsNumber, step: 0.00001.nsNumber.0, name: "Zoom")
				//NumberInput(value: $settings.camera.cameraDepth.nsNumber, step: 0.1.nsNumber.0, name: "Focal Lenghth")
				NumberInput(value: $state.cameraSpeed.nsNumber, name: "Camera Speed")
				NumberInput(value: $content.camera.resolution.x.nsNumber, name: "Width")
				NumberInput(value: $content.camera.resolution.y.nsNumber, name: "Height")
                Spacer()
				Button(action: {
					content.savedCamera = content.camera
				}) {
					Text("Set Saved Camera")
				}
				
                Button(action: {
					content.camera = content.savedCamera
                }) {
                    Text("Saved Camera")
                }
			}
        }
        .padding()
    }
}

struct CameraSettings_Previews: PreviewProvider {
    static var previews: some View {
		Text("hi")
       // CameraSettings()
		//	.environmentObject(Engine.Settings)
    }
}
