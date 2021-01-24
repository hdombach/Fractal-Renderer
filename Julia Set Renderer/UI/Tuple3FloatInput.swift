//
//  Tuple3FloatInput.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 12/19/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import SwiftUI

struct Tuple3FloatInput: View {
	@Binding var value: SIMD3<Float>
	var step: NSNumber = 1
	var name: String?
	var min: NSNumber?
	var max: NSNumber?
	
    var body: some View {
		VStack {
			if name != nil {
				Text(name!)
			}
			VStack(spacing: -1) {
				NumberInput(value: $value.x.nsNumber, step: step, min: min, max: max, hasPadding: false)
				NumberInput(value: $value.y.nsNumber, step: step, min: min, max: max, hasPadding: false)
				NumberInput(value: $value.z.nsNumber, step: step, min: min, max: max, hasPadding: false)
			}.cornerRadius(5.0)
			.overlay(RoundedRectangle(cornerRadius: 5)
						.stroke(Color.controlHighlightColor))
		}
    }
}

struct Tuple3FloatInput_Previews: PreviewProvider {
    static var previews: some View {
		Tuple3FloatInput(value: Binding.init(get: {
			Engine.Settings.rayMarchingSettings.colorBase
		}, set: { (newValue) in
			Engine.Settings.rayMarchingSettings.colorBase = newValue
		}), name: "Color").padding()
    }
}
