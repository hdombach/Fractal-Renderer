//
//  ColorPickerPro.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 11/23/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import SwiftUI

struct ColorPickerPro: View {
	@Binding var color: SIMD3<Float>
    var body: some View {
		HStack {
			VStack {
				HStack {
					Input(value: $color.x, step: 0.01, name: "R")
					Slider(value: $color.x)
				}
				HStack {
					Input(value: $color.y, step: 0.01, name: "G")
					Slider(value: $color.y)
				}
				HStack {
					Input(value: $color.z, step: 0.01, name: "B")
					Slider(value: $color.z)
				}
			}
				.frame(width: 200)
			RoundedRectangle(cornerRadius: 10)
				.frame(width: 50, height: 50)
				.foregroundColor(Color.init(red: Double(color.x), green: Double(color.y), blue: Double(color.z), opacity: 1))
		}
    }
}

struct ColorPickerPro_Previews: PreviewProvider {
    static var previews: some View {
		ColorPickerPro(color: Binding.init(get: {
			Engine.Settings.observed.skyBox[0].color
		}, set: { (newColor) in
			Engine.Settings.observed.skyBox[0].color = newColor
		}))
    }
}
