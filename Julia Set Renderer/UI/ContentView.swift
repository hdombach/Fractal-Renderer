//
//  ContentView.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 7/2/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var settings = Engine.Settings
    @State var isShowingCamera = false
    @State var isShowingImageSettings = false
    @State var isShowingPatternSettings = false
	
	enum Menu {
		case Render
		case Camera
		case Image
		case Fractal
		case Material
		case Lightin
	}
	
	@State private var currentMenu = Menu.Render
    //@State private var renderMode: RenderMode = .JuliaSet
	
	var body: some View {
		if settings.isShowingUI {
			VStack {
				HStack {
					Button("􀏅") {
						currentMenu = .Render
					}.foregroundColor(currentMenu == .Render ? .accentColor : .primary)
					.buttonStyle(PlainButtonStyle())
					
					Button("􀌞") {
						currentMenu = .Camera
					}.foregroundColor(currentMenu == .Camera ? .accentColor : .primary)
					.buttonStyle(PlainButtonStyle())
					
					Button("􀙮") {
						currentMenu = .Image
					}.foregroundColor(currentMenu == .Image ? .accentColor : .primary)
					.buttonStyle(PlainButtonStyle())
					Button("􀆪") {
						currentMenu = .Fractal
					}.foregroundColor(currentMenu == .Fractal ? .accentColor : .primary)
					.buttonStyle(PlainButtonStyle())
					Button("􀎑") {
						currentMenu = .Material
					}.foregroundColor(currentMenu == .Material ? .accentColor : .primary)
					.buttonStyle(PlainButtonStyle())
					Button("􀆭") {
						currentMenu = .Lightin
					}.foregroundColor(currentMenu == .Lightin ? .accentColor : .primary)
					.buttonStyle(PlainButtonStyle())
				}
				
				switch currentMenu {
				case .Render:
					RenderBox()
				case .Camera:
					CameraSettings()
				case .Image:
					ImageSettings()
				case .Fractal:
					TabView(selection: $settings.renderMode) {
						PatternSettings()
							.tabItem { Text("yeet") }.tag(RenderMode.JuliaSet)
						MandelbulbSettings(settings: $settings.rayMarchingSettings)
							.tabItem { Text("better yeet") }.tag(RenderMode.Mandelbulb)
					}.frame(minHeight: 400)
				case .Material:
					MaterialSettings()
				case .Lightin:
					ScrollView {
						SkyBoxSettings().frame(height: 300)
						ChannelSettings().frame(height: 300)
					}.frame(minHeight: 500)
				}
			}
			.frame(minWidth: 400)
		}
	}
}


#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
			.environmentObject(Engine.Settings)
    }
}
#endif
