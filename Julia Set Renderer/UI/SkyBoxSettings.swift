//
//  SkyBoxSettings.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 11/22/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import SwiftUI

struct SkyBoxSettings: View {
	@ObservedObject var settings = Engine.Settings.observed
	@State var spareLight = LightInfo.init(color: .init(), strength: 0, size: 0, position: .init())
	@State var selected: LightInfo?
	@State var items = ["test1", "test2", "test3", "test4"]
	var currentId: UInt32 = 0
	
	func index(id: UInt32) -> Int {
		guard let index = self.settings.skyBox.firstIndex(where: { $0.id == id}) else {
			fatalError("light does not exist")
		}
		return index
	}
	
    var body: some View {
		GroupBox(label: Text("Sky Box"), content: {
			VStack {
				
				List(settings.skyBox, id: \.self, selection: $selected) { light in
					LightPicker(light: $settings.skyBox[index(id: light.id)])
				}
				
				HStack {
					Button("+") {
						settings.skyBox.append(.init(color: .init(1, 1, 1), strength: 1, size: 0.9, position: .init(1, 0, 0)))
					}
						.padding(.leading)
						.buttonStyle(PlainButtonStyle())
					
					Button("-") {
						if selected != nil {
							let i = index(id: selected!.id)
							settings.skyBox.remove(at: i)
							selected = nil
						}
					}
						.disabled(selected == nil)
						.buttonStyle(PlainButtonStyle())
					Spacer()
					
				}
			}
		}).padding()
    }
}

struct SkyBoxSettings_Previews: PreviewProvider {
    static var previews: some View {
		SkyBoxSettings()
			
    }
}
