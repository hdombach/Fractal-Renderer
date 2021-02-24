//
//  ColorInput.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 1/30/21.
//  Copyright © 2021 Hezekiah Dombach. All rights reserved.
//

import SwiftUI

struct ColorInput: View {
	static func == (lhs: ColorInput, rhs: ColorInput) -> Bool {
		lhs.value == rhs.value
	}
	
	@Binding var value: Float3
	@State private var isPickingColor: Bool = false
	var name: String? = nil
	var hasPadding = true
	
    var body: some View {
		HStack {
			if name != nil {
				Text(name! + ":")
			}
			Spacer()
			Capsule()
				.aspectRatio(1.618, contentMode: .fit)
				.foregroundColor(Color(red: Double(value.x), green: Double(value.y), blue: Double(value.z)))
				.onTapGesture {
					isPickingColor.toggle()
				}
				.popover(isPresented: $isPickingColor, content: {
					ColorPickerPro(color: $value).padding()
				})
		}
    }
}

struct ColorInput_Previews: PreviewProvider {
    static var previews: some View {
		ColorInput(value: .constant(Float3()))
    }
}
