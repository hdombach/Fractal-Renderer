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
			ColorInput(value: $light.color)
			
			VStack {
				Text("Position")
				HStack {
                    NumberInput("X", value: $light.position.x, format: .number)
                    NumberInput("Y", value: $light.position.y, format: .number)
                    NumberInput("Z", value: $light.position.z, format: .number)
				}
			}
			HStack {
                NumberInput("Size", value: $light.size, format: .number)
                NumberInput("Strength", value: $light.strength, format: .number)
                NumberInput("Channel", value: $light.channel, format: .number)
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
