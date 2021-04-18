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
				.foregroundColor(isPickingColor ? Color.black : Color.init(red: Double(light.color.x), green: Double(light.color.y), blue: Double(light.color.z), opacity: 1))
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
					NumberInput(value: $light.position.x.nsNumber, step: 0.1.nsNumber.0, name: "X")
						.padding(.bottom, -2.0)
					NumberInput(value: $light.position.y.nsNumber, step: 0.1.nsNumber.0, name: "Y")
						.padding(.vertical, -2.0)
					NumberInput(value: $light.position.z.nsNumber, step: 0.1.nsNumber.0, name: "Z")
						.padding(.top, -2.0)
				}
			}
			HStack {
				VStack {
					Text("Size")
					NumberInput(value: $light.size.nsNumber, step: 0.1.nsNumber.0)
				}
				VStack {
					Text("Strength")
					NumberInput(value: $light.strength.nsNumber, step: 0.1.nsNumber.0)
				}
				VStack {
					Text("Chanel")
					NumberInput(value: $light.channel.nsNumber, step: 1.nsNumber.0)
				}
			}
		}
    }
}

struct ColorPicker_Previews: PreviewProvider {
    static var previews: some View {
		/*LightPicker(light: .init(get: { () -> LightInfo in
			Engine.Settings.skyBox[0]
		}, set: { (newLight) in
			Engine.Settings.skyBox[0] = newLight
		}))*/
		Text("hi")
    }
}
