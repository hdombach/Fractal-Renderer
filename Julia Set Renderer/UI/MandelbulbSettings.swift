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
				NumberInput(value: $settings.mandelbulbPower.nsNumber, step: 0.1.nsNumber.0, name: "Power")
				NumberInput(value: $settings.bundleSize.nsNumber, step: 1.nsNumber.0, name: "Bundle Size")
				NumberInput(value: $settings.quality.nsNumber, step: 100.nsNumber.0, name: "Quality")
				//Input(value: $settings.colorOffset, step: 0.01, name: "Color Offset")
				NumberInput(value: $settings.iterations.nsNumber, step: 1.nsNumber.0, name: "Iterations")
			}
			VStack {
				Text("Coloring")
				Tuple3FloatInput(value: $settings.colorBase, step: 0.1.nsNumber.0, name: "Color base")
				Tuple3FloatInput(value: $settings.colorOffset, step: 0.1.nsNumber.0, name: "Color offset")
				Tuple3FloatInput(value: $settings.colorVariation, step: 0.1.nsNumber.0, name: "Color variation")
				Tuple3FloatInput(value: $settings.colorFrequency, step: 10.nsNumber.0, name: "Color frequency")
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
