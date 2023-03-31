//
//  NumberInput.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 12/6/21.
//  Copyright © 2021 Hezekiah Dombach. All rights reserved.
//

import SwiftUI

struct NumberInput<V>: View where V : ParseableFormatStyle, V.FormatInput : Strideable, V.FormatOutput == String {
    var name: String?
    @Binding var value: V.FormatInput
    var format: V
    init(_ name: String?, value: Binding<V.FormatInput>, format: V) {
        self.name = name
        self._value = value
        self.format = format
    }
    var body: some View {
        HStack {
            if let name = name, !name.isEmpty {
                Text(name + ": ")
            }
            ZStack {
                TextField("adf", value: $value, format: format).multilineTextAlignment(.center)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                HStack {
                    Button("+") {
                        value = value.advanced(by: 1)
                    }.padding(.leading).buttonStyle(PlainButtonStyle())
                    Spacer()
                    Button("-") {
                        value = value.advanced(by: -1)
                    }.padding(.trailing).buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

struct NumberInput_Previews: PreviewProvider {
    static var previews: some View {
        NumberInput("Hellow", value: .constant(8), format: .number)
    }
}
