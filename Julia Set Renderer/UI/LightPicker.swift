//
//  ColorPicker.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 11/22/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import SwiftUI

struct LightPicker: View {
	@Binding var light: LightInfo
	@State var isPickingColor: Bool = false
	
    var body: some View {
		HStack {
			RoundedRectangle(cornerRadius: 10)
				.foregroundColor(Color.init(red: Double(light.color.x), green: Double(light.color.y), blue: Double(light.color.z), opacity: 1))
				.frame(width: 30, height: 30, alignment: .center)
				.onTapGesture(perform: {
					isPickingColor.toggle()
				})
				.popover(isPresented: $isPickingColor, content: {
					ColorPickerPro(color: $light.color)
						.padding()
				})
			
			VStack {
				Text("Position")
				HStack {
					Input(value: $light.position.x, step: 0.01, name: "X")
						.padding(.bottom, -2.0)
					Input(value: $light.position.y, step: 0.01, name: "Y")
						.padding(.vertical, -2.0)
					Input(value: $light.position.z, step: 0.01, name: "Z")
						.padding(.top, -2.0)
				}
			}
			HStack {
				VStack {
					Text("Size")
					Input(value: $light.size, step: 0.01)
				}
				VStack {
					Text("Strength")
					Input(value: $light.strength, step: 0.01)
				}
			}
		}
    }
}

struct ColorPicker_Previews: PreviewProvider {
    static var previews: some View {
		LightPicker(light: .init(get: { () -> LightInfo in
			Engine.Settings.skyBox[0]
		}, set: { (newLight) in
			Engine.Settings.skyBox[0] = newLight
		}))
    }
}
