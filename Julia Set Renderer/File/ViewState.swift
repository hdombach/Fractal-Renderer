//
//  ViewState.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 4/13/21.
//  Copyright © 2021 Hezekiah Dombach. All rights reserved.
//

import Foundation
import MetalKit

enum RenderMode: UInt32 {
	case JuliaSet = 0
	case Mandelbulb = 1
}


var globalId: UInt32 = 0
func generateID() -> UInt32 {
	globalId += 1
	return globalId
}

enum ViewportMode: String, CaseIterable, Identifiable {
	case preview
	case depth
	case rendering
	
	var id: String { self.rawValue }
}

class ViewSate: ObservableObject {
	@Published var viewportMode = ViewportMode.preview
	@Published var renderMode: RenderMode = .Mandelbulb
	@Published var isShowingUI: Bool = true
	@Published var cameraSpeed: Float = 0.01
	var document: Document
	
	var view: MTKView!
	var renderer: Renderer!
	var renderPassManager: RenderPassManager!
	
	init(doc: Document) {
		document = doc
		renderer = Renderer(doc: doc)
		renderPassManager = RenderPassManager(doc: doc)
	}
	
	func startRendering(samplesCount: Int) {
		renderPassManager.startRender(samplesCount: samplesCount)
		viewportMode = .rendering
	}
	
	func stopRendering() {
		viewportMode = .preview
		updateView()
		renderPassManager.resetRender()
	}
	
	func updateView() {
		DispatchQueue.main.async {
			self.view.setNeedsDisplay(self.view.frame)
		}
	}
	
	func updateShaders(material: String? = nil, de: String? = nil) {
		document.graphics.library.loadLibrary(material: material ?? document.content.materialNodeContainer.compiled, de: de ?? document.content.deNodeContainer.compiled, channelsLength: 5 + document.content.skyBox.count * 3) {
			self.updateView()
		}
	}
}
