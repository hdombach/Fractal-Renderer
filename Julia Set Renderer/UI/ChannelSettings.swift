//
//  ChannelSettings.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 12/3/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import SwiftUI

struct ChannelSettings: View {
	@ObservedObject var settings = Engine.Settings
	@State var selected: ChannelInfo?
	
	func index(id: UInt32) -> Int {
		guard let index = self.settings.channels.firstIndex(where: { $0.index == id}) else {
			fatalError("channel does not exist")
		}
		return index
	}
	
    var body: some View {
		VStack {
			Text("Channels")
			List(settings.channels, id: \.self, selection: $selected) { channel in
				ChannelPicker(channel: $settings.channels[index(id: channel.index)])
			}.cornerRadius(5)
		}.padding([.leading, .bottom, .trailing])
    }
}

struct ChannelSettings_Previews: PreviewProvider {
    static var previews: some View {
        ChannelSettings()
    }
}
