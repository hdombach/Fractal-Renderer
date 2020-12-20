//
//  PatternSettings.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 8/20/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import SwiftUI

struct PatternSettings: View {
	@State var quality: Float = 1
    var body: some View {
        HStack {
            Button(action: {
                print("started loading")
                Engine.LoadJuliaSet(quality: self.quality)
            }) {
                Text("Load Pattern")
            }
			NumberInput(value: $quality.nsNumber, step: 1.nsNumber.0, name: "Quality")
        }.padding()
    }
}

struct PatternSettings_Previews: PreviewProvider {
    static var previews: some View {
        PatternSettings()
    }
}
