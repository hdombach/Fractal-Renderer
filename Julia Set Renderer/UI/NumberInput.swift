//
//  NumberInput.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 8/6/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import SwiftUI

struct FloatInput: View {
	@Binding var value: Float
	var difference: Float
	var name: String
	var cap: Float?
	func format() -> NumberFormatter {
		let newFormat = NumberFormatter()
		newFormat.minimumSignificantDigits = 2
		newFormat.maximumSignificantDigits = 8
		if cap != nil {
			newFormat.maximum = NSNumber.init(value: cap!)
		}
		return newFormat
	}

    var body: some View {
		HStack {
			Text("\(name): ")
				.fixedSize()

			Stepper(onIncrement: {
				self.value += self.difference
			}, onDecrement: {
				self.value -= self.difference
			}) {
				TextField(name, value: $value, formatter: format())
			}
		}
    }
}

struct IntInput: View {
	@Binding var value: Int
	var name: String
	var max: Int?
	var min: Int?

	func format() -> NumberFormatter {
		let newFormatter = NumberFormatter()
		if min != nil {
			newFormatter.minimum = NSNumber.init(value: min!)
		}
		if max != nil {
			newFormatter.maximum = NSNumber.init(value: max!)
		}
		return newFormatter
	}

	var body: some View {
		HStack {
			Text("\(name): ")
				.fixedSize()

			Stepper(onIncrement: {
				self.value += 1
			}, onDecrement: {
				self.value -= 1
			}) {
				TextField(name, value: $value, formatter: format())
			}
		}
	}
}

struct NumberInput_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            FloatInput(value: Binding<Float>.init(get: { () -> Float in
                return Engine.Settings.camera.position.x
            }, set: { (float) in
                Engine.Settings.camera.position.x = float
            }), difference: 0.1, name: "Width")
        }
    }
}
