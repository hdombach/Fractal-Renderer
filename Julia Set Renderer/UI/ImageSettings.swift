//
//  ImageSettings.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 8/5/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import SwiftUI

struct ImageSettings: View {
	@EnvironmentObject var settings: ObservedRenderSettings
	@State var myString: String = "hello"

    var body: some View {

		GroupBox(label: Text("Output Image")) {
			VStack {
				IntInput(value: $settings.imageSize.0, name: "Width")
				IntInput(value: $settings.imageSize.1, name: "Height")
			}
		}
    }
}

struct ImageSettings_Previews: PreviewProvider {
    static var previews: some View {
        ImageSettings()
			.environmentObject(Engine.Settings.observed)
    }
}
