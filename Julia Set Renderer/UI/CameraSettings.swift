//
//  CameraSettings.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 8/5/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import SwiftUI

struct CameraSettings: View {
	@EnvironmentObject var settings: ObservedRenderSettings

    var body: some View {
		GroupBox(label: Text("Camera")) {
			HStack(alignment: .top) {
				VStack {
					VStack(alignment: .leading) {
						Text("Position")
							.font(.subheadline)

						FloatInput(value: $settings.camera.position.x, difference: 0.01, name: "x")
						FloatInput(value: $settings.camera.position.y, difference: 0.01, name: "y")
						FloatInput(value: $settings.camera.position.z, difference: 0.01, name: "z")
					}
					Divider()
					VStack(alignment: .leading) {
						Text("Dericiton")
							.font(.subheadline)

						FloatInput(value: $settings.camera.deriction.x, difference: 0.01, name: "x-axis")
						FloatInput(value: $settings.camera.deriction.y, difference: 0.01, name: "y-axis")
						FloatInput(value: $settings.camera.deriction.z, difference: 0.01, name: "z-axis")
					}
				}
				Divider()
				VStack() {
					Text("Other")

					FloatInput(value: $settings.camera.zoom, difference: 0.00001, name: "Zoom")
					FloatInput(value: $settings.camera.cameraDepth, difference: 0.1, name: "Focal Lenghth")
					Spacer()
					Button(action: {
						Engine.Settings.camera = Engine.Settings.savedCamera
					}) {
						Text("Saved Camera")
					}
				}
			}.fixedSize(horizontal: false, vertical: true)
		}
    }
}

struct CameraSettings_Previews: PreviewProvider {
    static var previews: some View {
        CameraSettings()
			.environmentObject(Engine.Settings.observed)
    }
}
