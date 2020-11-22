//
//  ContentView.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 7/2/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var settings = Engine.Settings.observed
    @State var isShowingCamera = false
    @State var isShowingImageSettings = false
    @State var isShowingPatternSettings = false
    //@State private var renderMode: RenderMode = .JuliaSet
	
	var body: some View {
        ScrollView {
            RenderBox()
                .padding([.top, .leading, .trailing])
            HStack {
                Button("Camera Settings") {
                    isShowingCamera.toggle()
                }
                .popover(isPresented: $isShowingCamera, content: {
                    CameraSettings()
                })
                
                Button("Image Settings") {
                    isShowingImageSettings.toggle()
                }
                .popover(isPresented: $isShowingImageSettings, content: {
                    ImageSettings()
                })
            }
            TabView(selection: $settings.renderMode) {
                PatternSettings()
                    .tabItem { Text("yeet") }.tag(RenderMode.JuliaSet)
                Text("yeet2")
                    .tabItem { Text("yeet2") }.tag(RenderMode.Mandelbulb)
            }.frame(width: 300, height: 100, alignment: .center)
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
