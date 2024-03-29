//
//  SkyBoxSettings.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 11/22/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import SwiftUI

struct SkyBoxSettings: View {
	@ObservedObject var content: Content
	@State var spareLight = LightInfo.init(color: .init(), strength: 0, size: 0, position: .init(), channel: 0)
	@State var selected: LightInfo?
	@State var items = ["test1", "test2", "test3", "test4"]
	var currentId: UInt32 = 0
    
    @State var test = 5
	
	func index(id: UInt32) -> Int {
		guard let index = self.content.skyBox.firstIndex(where: { $0.id == id}) else {
			fatalError("light does not exist")
		}
		return index
	}
	
    var body: some View {
		VStack {
			
			VStack {
				ColorInput(value: $content.atmosphereSettings.backgroundColor, name: "Background")
				
				HStack {
					ColorInput(value: $content.atmosphereSettings.depthColor, name: "Mist")
                    NumberInput("Strength", value: $content.atmosphereSettings.depthStrength, format: .number)
				}
                NumberInput("Emission Strength: ", value: $content.atmosphereSettings.emissionStrength, format: .number).frame(width: 500)
                
                NumberInput("Cutoff", value: $content.cutoff, format: .number)
			}.frame(height: 150)
			
			Text("Lights")
			List(content.skyBox, id: \.self, selection: $selected) { light in
				LightPicker(light: $content.skyBox[index(id: light.id)])
			}.cornerRadius(5)

			HStack {
				Button("+") {
					content.skyBox.append(.init(color: .init(1, 1, 1), strength: 1, size: 0.9, position: .init(1, 0, 0), channel: 0))
				}
				.padding(.leading)
				.buttonStyle(PlainButtonStyle())
				
				Button("-") {
					if selected != nil {
						let i = index(id: selected!.id)
						content.skyBox.remove(at: i)
						selected = nil
					}
				}
				.disabled(selected == nil)
				.buttonStyle(PlainButtonStyle())
				Spacer()
				
			}
		}.padding([.top, .leading, .trailing])
    }
}

struct SkyBoxSettings_Previews: PreviewProvider {
    static var previews: some View {
		SkyBoxSettings(content: Content()).frame(height: 1000)
			
    }
}
