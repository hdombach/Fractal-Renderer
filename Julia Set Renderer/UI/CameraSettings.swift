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
					
					Tuple3FloatInput(value: $settings.camera.position.xyz, step: 0.01.nsNumber.0, name: "Position")
                }
                Divider()
                VStack(alignment: .leading) {
					
					Tuple3FloatInput(value: $settings.camera.deriction.xyz, step: 0.01.nsNumber.0, name: "Dericiton")
                }
            }
            Divider()
            VStack() {
                Text("Other")

				NumberInput(value: $settings.camera.zoom.nsNumber, step: 0.00001.nsNumber.0, name: "Zoom")
				NumberInput(value: $settings.camera.cameraDepth.nsNumber, step: 0.1.nsNumber.0, name: "Focal Lenghth")
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
