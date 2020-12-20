//
//  ChannelPicker.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 12/3/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import SwiftUI

struct ChannelPicker: View {
	@State var isPickingColor: Bool = false
	@Binding var channel: ChannelInfo
	
	
    var body: some View {
		HStack {
			Text("Channel \(channel.index): ")
			RoundedRectangle(cornerRadius: 10)
				.foregroundColor(isPickingColor ? Color.black : Color.init(red: Double(channel.color.x), green: Double(channel.color.y), blue: Double(channel.color.z), opacity: 1))
				.frame(width: 30, height: 30, alignment: .center)
				.onTapGesture(perform: {
					isPickingColor.toggle()
				})
				.popover(isPresented: $isPickingColor, content: {
					ColorPickerPro(color: $channel.color)
						.padding()
				})
			
			Text("Strength")
			NumberInput(value: $channel.strength.nsNumber, step: 0.1.nsNumber.0)
		}
    }
}

struct ChannelPicker_Previews: PreviewProvider {
    static var previews: some View {
		ChannelPicker(channel: .init(get: { () -> ChannelInfo in
			Engine.Settings.channels[0]
		}, set: { (newChannel) in
			Engine.Settings.channels[0] = newChannel
		}))
    }
}
