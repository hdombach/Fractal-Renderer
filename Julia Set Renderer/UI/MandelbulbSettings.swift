//
//  MandelbulbSettings.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 11/27/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import SwiftUI

struct MandelbulbSettings: View {
	@Binding var settings: RayMarchingSettings
	
    var body: some View {
		HStack {
			VStack {
                NumberInput("Power", value: $settings.mandelbulbPower, format: .number)
                NumberInput("Bundle Size", value: $settings.bundleSize, format: .number)
                NumberInput("Quality", value: $settings.quality, format: .number)
                NumberInput("Iterations", value: $settings.iterations, format: .number)
			}
			VStack {
				Text("Coloring")
                Tuple3FloatInput(value: $settings.colorBase, step: 0.1, name: "Color base")
				Tuple3FloatInput(value: $settings.colorOffset, step: 0.1, name: "Color offset")
				Tuple3FloatInput(value: $settings.colorVariation, step: 0.1, name: "Color variation")
                Tuple3FloatInput(value: $settings.colorFrequency, step: 0.1, name: "Color frequency")
			}
		}
    }
}

struct MandelbulbSettings_Previews: PreviewProvider {
    static var previews: some View {
		/*MandelbulbSettings(settings: Binding.init(get: {
			Engine.Settings.rayMarchingSettings
		}, set: { (newSettings) in
			Engine.Settings.rayMarchingSettings = newSettings
		}))*/
		Text("gi")
    }
}
