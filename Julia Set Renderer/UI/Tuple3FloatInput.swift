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
                NumberInput("", value: $value.x, format: .number)
                NumberInput("", value: $value.y, format: .number)
                NumberInput("", value: $value.z, format: .number)
			}.cornerRadius(5.0)
			.overlay(RoundedRectangle(cornerRadius: 5)
						.stroke(Color.controlHighlightColor))
		}
    }
}

struct Tuple4FloatInput: View {
	@Binding var value: Float4
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
                NumberInput("", value: $value.x, format: .number)
                NumberInput("", value: $value.y, format: .number)
                NumberInput("", value: $value.z, format: .number)
                NumberInput("", value: $value.w, format: .number)
			}.cornerRadius(5.0)
			.overlay(RoundedRectangle(cornerRadius: 5)
						.stroke(Color.controlHighlightColor))
		}
	}
}

struct Tuple3FloatInput_Previews: PreviewProvider {
    static var previews: some View {
		Text("hi")
    }
}
