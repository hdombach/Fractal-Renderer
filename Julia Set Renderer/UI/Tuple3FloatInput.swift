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
		VStack(spacing: -1.0) {
			if name != nil {
				Text(name!)
			}
			NumberInput(value: $value.x.nsNumber, step: step, min: min, max: max, hasPadding: false)
			NumberInput(value: $value.y.nsNumber, step: step, min: min, max: max, hasPadding: false)
			NumberInput(value: $value.z.nsNumber, step: step, min: min, max: max, hasPadding: false)
		}.cornerRadius(3.0)
    }
}

struct Tuple3FloatInput_Previews: PreviewProvider {
    static var previews: some View {
		Tuple3FloatInput(value: Binding.init(get: {
			Engine.Settings.rayMarchingSettings.colorBase
		}, set: { (newValue) in
			Engine.Settings.rayMarchingSettings.colorBase = newValue
		}))
    }
}
