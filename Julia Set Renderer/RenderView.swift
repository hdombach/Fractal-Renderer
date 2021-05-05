//
//  RenderView.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 7/2/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import MetalKit

//The render window.
class RenderView: MTKView {
	var document: Document!
	var renderer: Renderer!

	var trackingRect: NSTrackingArea!

	var isTracking: Bool = false
	
	var isSelected: Bool = false
	
	func updateRenderMode() {
		changeRenderMode(isManual: !(isSelected || document.viewState.viewportMode == .rendering))
	}
	
	func changeRenderMode(isManual: Bool) {
		print("changed render mode", isManual)
		self.isPaused = isManual
		self.enableSetNeedsDisplay = isManual
	}
	
	init(doc: Document) {
		super.init(frame: CGRect(), device: doc.graphics.device)
		self.document = doc
		colorPixelFormat = document.graphics.pixelFormat.0
		
		self.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
		
		self.renderer = doc.viewState.renderer
		
		renderer.screenRatio = Float(frame.size.width / frame.size.height)
		
		self.delegate = renderer
		
		trackingRect = NSTrackingArea.init(rect: NSRect.init(x: 0, y: 0, width: 10000, height: 10000), options: [NSTrackingArea.Options.mouseMoved, NSTrackingArea.Options.activeWhenFirstResponder], owner: self, userInfo: nil)
		addTrackingArea(trackingRect)
		
		changeRenderMode(isManual: true)
		
		colorspace = CGColorSpace.init(name: CGColorSpace.sRGB)
	}

	required init(coder: NSCoder) {
		//Initializes render pipelines and settings
		super.init(coder: coder)

		self.device = MTLCreateSystemDefaultDevice()

		colorPixelFormat = document.graphics.pixelFormat.0

		self.clearColor = MTLClearColor.init(red: 0, green: 0, blue: 0, alpha: 0)

		self.renderer = Renderer()

		renderer.screenRatio = Float(frame.size.width / frame.size.height)

		self.delegate = renderer


		trackingRect = NSTrackingArea.init(rect: NSRect.init(x: 0, y: 0, width: 10000, height: 10000), options: [NSTrackingArea.Options.mouseMoved, NSTrackingArea.Options.activeWhenFirstResponder], owner: self, userInfo: nil)
		addTrackingArea(trackingRect)


        changeRenderMode(isManual: true)
	}

	override var acceptsFirstResponder: Bool { return true }

	//IO Events
	override func mouseDown(with event: NSEvent) {
		isSelected = true
		updateRenderMode()
		document.viewState.isShowingUI = false
		isTracking = true
		CGAssociateMouseAndMouseCursorPosition(boolean_t(UInt32(truncating: false)))
		CGDisplayHideCursor(1)
	}

	override func keyDown(with event: NSEvent) {
		Keys.update(key: event.keyCode, value: true)
		if event.keyCode == 53 { // escape
			isSelected = false
			updateRenderMode()
			document.viewState.isShowingUI = true
			isTracking = false
			CGAssociateMouseAndMouseCursorPosition(boolean_t(UInt32(truncating: true)))
			CGDisplayShowCursor(1)
		}
	}

	override func keyUp(with event: NSEvent) {
		Keys.update(key: event.keyCode, value: false)
	}

	override func mouseMoved(with event: NSEvent) {
		if isTracking {
			rotateCamera(event: event)
		}
	}

	override func mouseDragged(with event: NSEvent) {
		if isTracking {
			rotateCamera(event: event)
		}
	}

	func rotateCamera(event: NSEvent) {
		if document.viewState.viewportMode == .rendering {
			printError("Tried to move camera while rendering.")
		} else {
			document.content.camera.rotate(deltaX: Float(event.deltaX / 1000), deltaY: Float(event.deltaY / -1000))
		}
	}

	//Need to update the tracking rectangle whenever screen is resized
	override func setFrameSize(_ newSize: NSSize) {
		super.setFrameSize(newSize)
		trackingRect = NSTrackingArea.init(rect: self.frame, options: [NSTrackingArea.Options.mouseMoved, NSTrackingArea.Options.activeWhenFirstResponder], owner: self, userInfo: nil)
		updateTrackingAreas()
	}
}
