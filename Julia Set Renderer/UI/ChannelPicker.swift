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
            ColorPicker("Channele \(channel.index)", selection: $channel.color.cgColor)
			
			Text("Strength")
			NumberInput(value: $channel.strength.nsNumber, step: 0.1.nsNumber.0)
		}
    }
}

struct ChannelPicker_Previews: PreviewProvider {
    static var previews: some View {
		/*ChannelPicker(channel: .init(get: { () -> ChannelInfo in
			Engine.Settings.channels[0]
		}, set: { (newChannel) in
			Engine.Settings.channels[0] = newChannel
		}))*/
		Text("hi")
    }
}
