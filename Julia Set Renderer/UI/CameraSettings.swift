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
					
					Tuple3FloatInput(value: $content.camera.position.xyz, step: 0.01, name: "Position")
                }
                Divider()
                VStack(alignment: .leading) {
                    NumberInput("Vertical FOV", value: $content.camera.vfov, format: .number)
                    NumberInput("Lense Radius", value: $content.camera.lensRadius, format: .number)
                    NumberInput("Focus Distance", value: $content.camera.focusDistance, format: .number)
					
					//Tuple3FloatInput(value: $settings.camera.deriction.xyz, step: 0.01.nsNumber.0, name: "Dericiton")
                }
            }
            Divider()
            VStack() {
                Text("Other")
				//NumberInput(value: $settings.camera.zoom.nsNumber, step: 0.00001.nsNumber.0, name: "Zoom")
				//NumberInput(value: $settings.camera.cameraDepth.nsNumber, step: 0.1.nsNumber.0, name: "Focal Lenghth")
                NumberInput("Camera Speed", value: $state.cameraSpeed, format: .number)
                NumberInput("Width", value: $content.camera.resolution.x, format: .number)
                NumberInput("Height", value: $content.camera.resolution.y, format: .number)
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
