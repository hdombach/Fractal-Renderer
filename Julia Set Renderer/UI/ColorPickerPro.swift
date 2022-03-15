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
	@State var tempColor: SIMD3<Float> = .init()
	
    var body: some View {
		HStack {
			VStack {
				HStack {
                    NumberInput("R", value: $tempColor.x, format: .number)
					Slider(value: $tempColor.x)
				}
				HStack {
                    NumberInput("G", value: $tempColor.y, format: .number)
					Slider(value: $tempColor.y)
				}
				HStack {
                    NumberInput("B", value: $tempColor.z, format: .number)
					Slider(value: $tempColor.z)
				}
			}
				.frame(width: 200)
			VStack {
				RoundedRectangle(cornerRadius: 10)
					.frame(width: 50, height: 50)
					.foregroundColor(Color.init(red: Double(tempColor.x), green: Double(tempColor.y), blue: Double(tempColor.z), opacity: 1))
				Button("Set") {
					color = tempColor
				}
			}
		}.onAppear(perform: {
			tempColor = color
		})
    }
}

struct ColorPickerPro_Previews: PreviewProvider {
    static var previews: some View {
		/*ColorPickerPro(color: Binding.init(get: {
			Engine.Settings.skyBox[0].color
		}, set: { (newColor) in
			Engine.Settings.skyBox[0].color = newColor
		}))*/
		Text("afsdg")
    }
}
