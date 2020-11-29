//
//  CameraSettings.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 8/5/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import SwiftUI

struct CameraSettings: View {
    @ObservedObject var settings = Engine.Settings.observed

    var body: some View {
        HStack(alignment: .top) {
            VStack {
                VStack(alignment: .leading) {
                    Text("Position")
                        .font(.subheadline)

					Input(value: $settings.camera.position.x, step: 0.01, name: "x")
					Input(value: $settings.camera.position.y, step: 0.01, name: "y")
					Input(value: $settings.camera.position.z, step: 0.01, name: "z")
                }
                Divider()
                VStack(alignment: .leading) {
                    Text("Dericiton")
                        .font(.subheadline)

					Input(value: $settings.camera.deriction.x, step: 0.01, name: "x-axis")
					Input(value: $settings.camera.deriction.y, step: 0.01, name: "y-axis")
					Input(value: $settings.camera.deriction.z, step: 0.01, name: "z-axis")
                }
            }
            Divider()
            VStack() {
                Text("Other")

				Input(value: $settings.camera.zoom, step: 0.00001, name: "Zoom")
				Input(value: $settings.camera.cameraDepth, step: 0.1, name: "Focal Lenghth")
                Spacer()
				Button(action: {
					Engine.Settings.savedCamera = Engine.Settings.camera
				}) {
					Text("Set Saved Camera")
				}
				
                Button(action: {
                    Engine.Settings.camera = Engine.Settings.savedCamera
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
        CameraSettings()
			.environmentObject(Engine.Settings.observed)
    }
}
