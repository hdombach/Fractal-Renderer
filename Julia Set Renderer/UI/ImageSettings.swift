//
//  ImageSettings.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 8/5/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import SwiftUI

struct ImageSettings: View {
    @ObservedObject var settings = Engine.Settings.observed
	@State var myString: String = "hello"

    var body: some View {

        VStack {
			Input(value: $settings.imageSize.0, step: 1, name: "Width")
			Input(value: $settings.imageSize.1, step: 1, name: "Height")
        }
        .padding()
    }
}

struct ImageSettings_Previews: PreviewProvider {
    static var previews: some View {
        ImageSettings()
			.environmentObject(Engine.Settings.observed)
    }
}
