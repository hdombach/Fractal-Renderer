//
//  ContentView.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 7/2/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import SwiftUI

struct ContentView: View {
	@ObservedObject var content: Content
	@ObservedObject var state: ViewSate
	var document: Document
	
	init(doc: Document, menu: ContentView.Menu = .Render) {
		content = doc.content
		state = doc.viewState
		document = doc
		currentMenu = menu
	}
	
    @State var isShowingCamera = false
    @State var isShowingImageSettings = false
    @State var isShowingPatternSettings = false
	
	
	
	enum Menu {
		case Render
		case Camera
		case Fractal
		case Material
		case DE
		case Lightin
	}
	
	@State private var currentMenu = Menu.Lightin
    //@State private var renderMode: RenderMode = .JuliaSet
	
	var body: some View {
        VStack {
            if state.isShowingUI {
				HStack {
					Button("Render") {
						currentMenu = .Render
					}.foregroundColor(currentMenu == .Render ? .accentColor : .primary)
					.buttonStyle(PlainButtonStyle())
					
					Button("Camera") {
						currentMenu = .Camera
					}.foregroundColor(currentMenu == .Camera ? .accentColor : .primary)
					.buttonStyle(PlainButtonStyle())
					Button("Fractal") {
						currentMenu = .Fractal
					}.foregroundColor(currentMenu == .Fractal ? .accentColor : .primary)
					.buttonStyle(PlainButtonStyle())
					Button("Material") {
						currentMenu = .Material
					}.foregroundColor(currentMenu == .Material ? .accentColor : .primary)
					.buttonStyle(PlainButtonStyle())
					Button("DE") {
						currentMenu = .DE
					}.foregroundColor(currentMenu == .DE ? .accentColor : .primary)
					.buttonStyle(PlainButtonStyle())
					Button("Lighting") {
						currentMenu = .Lightin
					}.foregroundColor(currentMenu == .Lightin ? .accentColor : .primary)
					.buttonStyle(PlainButtonStyle())
				}
				
				switch currentMenu {
				case .Render:
					RenderBox(doc: document)
				case .Camera:
					CameraSettings(doc: document)
				case .Fractal:
					TabView(selection: $state.renderMode) {
						PatternSettings(document: document)
							.tabItem { Text("yeet") }.tag(RenderMode.JuliaSet)
						MandelbulbSettings(settings: $content.rayMarchingSettings)
							.tabItem { Text("better yeet") }.tag(RenderMode.Mandelbulb)
					}.frame(minHeight: 400)
				case .Material:
					MaterialSettings(doc: document)
				case .DE:
					DESettings(doc: document)
				case .Lightin:
					SkyBoxSettings(content: content)
				}
				Spacer()
            } else {
                Spacer()
                HStack {
                    Spacer()
                }
            }
		}
        .frame(minWidth: 400)
	}
}


#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
		ContentView(doc: Document(), menu: .Lightin)
		//	.environmentObject(Engine.Settings)
    }
}
#endif
