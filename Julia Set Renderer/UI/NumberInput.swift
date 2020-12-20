//
//  NumberInput.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 8/6/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import SwiftUI

enum NumberTypes {
	case float
	case int
	case double
	case uint32
	case na
}

struct NumberInput: View {
	@Binding var value: NSNumber
	@State private var isActive: Bool = false
	@State private var isEditing: Bool = false
	var type: NumberTypes
    var step: NSNumber = 1
    var name: String?
    var min: NSNumber?
    var max: NSNumber?
	var hasPadding = true
    
    func getFormat() -> NumberFormatter {
        let newFormat = NumberFormatter()
		if type == .float || type == .double{
            newFormat.minimumSignificantDigits = 2
            newFormat.maximumSignificantDigits = 4
        }
		newFormat.maximum = max
		newFormat.minimum = min
        return newFormat
    }
	
	init(value: Binding<(NSNumber, NumberTypes)>, step: NSNumber = 1, name: String? = nil, min: NSNumber? = nil, max: NSNumber? = nil, hasPadding: Bool = true) {
		self._value = value.0
		self.type = value.1.wrappedValue
		self.step = step
		self.name = name
		self.min = min
		self.max = max
		self.hasPadding = hasPadding
	}
    
    var body: some View {
		
		HStack {
			if name != nil {
				Text(name! + ":")
			}
			ZStack {
				if isActive || isEditing {
					TextField("Enter new value", value: $value, formatter: getFormat(), onEditingChanged: { (editingChanged) in
						isEditing = editingChanged
					})
						.textFieldStyle(PlainTextFieldStyle())
						.multilineTextAlignment(.center)
						.cornerRadius(3.0)
				} else {
					Text(getFormat().string(from: value)!)
				}
				HStack {
					Button("+") {
						value = NSNumber(value: step.doubleValue + value.doubleValue)
					}.buttonStyle(PlainButtonStyle())
					.frame(width: 20)
					.contentShape(Rectangle())
					
					Spacer()
					
					Button("-") {
						value = NSNumber(value: value.doubleValue - step.doubleValue)
					}.buttonStyle(PlainButtonStyle())
					.frame(width: 20)
					.contentShape(Rectangle())
				}
			}
			.border(SeparatorShapeStyle(), width: 1)
			.cornerRadius(hasPadding ? 3.0 : 0.0)
			.padding(hasPadding ? 4.0 : 0.0)
		}
		.padding(0.0)
		.onHover(perform: { hovering in
			isActive = hovering
		})
		
        /*.popover(isPresented: $isEditing) {
            TextField("Enter New Value", value: $value, formatter: getFormat()) {
                isEditing.toggle()
            }
            .padding()
        }*/
    }
}


struct NumberInput_Previews: PreviewProvider {
    @EnvironmentObject var settings: ObservedRenderSettings
    
    

    static var previews: some View {
        
        Group {
			NumberInput(value: Binding.init(get: {
				return Engine.Settings.camera.position.x.nsNumber
			}, set: { (newValue) in
				Engine.Settings.camera.position.x.nsNumber = newValue
			}))
        }
    }
}
