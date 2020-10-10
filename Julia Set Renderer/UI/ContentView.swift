//
//  ContentView.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 7/2/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import SwiftUI

struct ContentView: View {
	@EnvironmentObject var settings: ObservedRenderSettings
	
	var body: some View {
		ScrollView {
			RenderBox()
				.padding([.top, .leading, .trailing])
			ImageSettings()
				.padding([.top, .leading, .trailing])
			CameraSettings()
				.padding([.top, .leading, .trailing])
			PatternSettings()
				.padding([.top, .leading, .trailing])
		}
    }
}


#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
			.environmentObject(Engine.Settings.observed)
    }
}
#endif
