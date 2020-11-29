//
//  NumberInput.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 8/6/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import SwiftUI

struct Input<type>: View where type: Strideable, type: _FormatSpecifiable, type: AdditiveArithmetic {
    @Binding var value: type
    var step: type
    var name: String?
    var min: type?
    var max: type?
    
    func currentType() -> types {
        if value is Float {
            return .float
        } else if value is Int {
            return .int
		} else if value is Double {
			return .double
        } else {
            return .na
        }
    }
    
    func getFormat() -> NumberFormatter {
        let newFormat = NumberFormatter()
		if currentType() == .float || currentType() == .double{
            newFormat.minimumSignificantDigits = 2
            newFormat.maximumSignificantDigits = 4
        }
        newFormat.maximum = max as? NSNumber
        newFormat.minimum = min as? NSNumber
        return newFormat
    }
    
    enum types {
        case float
        case int
		case double
        case na
    }
    
    var body: some View {
		
		HStack {
			if name != nil {
				Text(name! + ":")
			}
			ZStack {
				TextField("Enter new value", value: $value, formatter: getFormat())
					.multilineTextAlignment(.center)
					.cornerRadius(3.0)
				HStack {
					Button("+") {
						value = step + value
					}.buttonStyle(PlainButtonStyle())
					.frame(width: 20)
					.contentShape(Rectangle())
					
					Spacer()
					
					Button("-") {
						value = value - step
					}.buttonStyle(PlainButtonStyle())
					.frame(width: 20)
					.contentShape(Rectangle())
				}
			}
			.padding()
		}
		.padding(0.0)
		
        /*.popover(isPresented: $isEditing) {
            TextField("Enter New Value", value: $value, formatter: getFormat()) {
                isEditing.toggle()
            }
            .padding()
        }*/
    }
}

struct InputPopover<type>: View where type: _FormatSpecifiable {
    @Binding var value: type
    var format: NumberFormatter
    
    var body: some View {
        /*TextField("Enter New Value", value: $value, formatter: format)
            .padding()*/
        TextField("Enter New Value", value: $value, formatter: format) {
            hidden()
        }
    }
}

/*struct FloatInput: View {
	@Binding var value: Float
    @State var isEditing: Bool = false
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

            Stepper(value: $value, step: difference) {
				Text("\(value)")
                    .onTapGesture {
                        isEditing.toggle()
                    }
            }.sheet(isPresented: $isEditing, content: {
                Text("hello")
            })
            
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

            Stepper(value: $value, step: 1) {
                Text("\(value)")
            }
		}
	}
}*/


struct NumberInput_Previews: PreviewProvider {
    @EnvironmentObject var settings: ObservedRenderSettings
    
    

    static var previews: some View {
        
        Group {
            Input(value: Binding<Float>.init(get: { () -> Float in
                return Engine.Settings.camera.position.x
            }, set: { (newValue) in
                Engine.Settings.camera.position.x = newValue
			}), step: 1, name: "x Position")
            InputPopover(value: Binding<Float>.init(get: { () -> Float in
                return Engine.Settings.camera.position.x
            }, set: { (newValue) in
                Engine.Settings.camera.position.x = newValue
			}), format: NumberFormatter())
        }
    }
}
