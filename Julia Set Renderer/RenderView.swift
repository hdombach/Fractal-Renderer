//
//  RenderView.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 7/2/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import MetalKit

class RenderView: MTKView {
	var renderer: Renderer!

	var trackingRect: NSTrackingArea!

	var isTracking: Bool = false
	
	func changeRenderMode(isManual: Bool) {
		self.isPaused = isManual
		self.enableSetNeedsDisplay = isManual
	}

	required init(coder: NSCoder) {
		super.init(coder: coder)

		self.device = MTLCreateSystemDefaultDevice()

		Engine.Init(device: device!)

		colorPixelFormat = Engine.PixelFormat.0

		self.clearColor = MTLClearColor.init(red: 0, green: 0, blue: 0, alpha: 0)

		self.renderer = Renderer()
		
		Engine.View = self

		renderer.screenRatio = Float(frame.size.width / frame.size.height)

		self.delegate = renderer


		trackingRect = NSTrackingArea.init(rect: NSRect.init(x: 0, y: 0, width: 10000, height: 10000), options: [NSTrackingArea.Options.mouseMoved, NSTrackingArea.Options.activeWhenFirstResponder], owner: self, userInfo: nil)
		addTrackingArea(trackingRect)


        changeRenderMode(isManual: true)
	}

	override var acceptsFirstResponder: Bool { return true }

	override func mouseDown(with event: NSEvent) {
		changeRenderMode(isManual: false)
		Engine.Settings.isShowingUI = false
		isTracking = true
		CGAssociateMouseAndMouseCursorPosition(boolean_t(UInt32(truncating: false)))
		CGDisplayHideCursor(1)
	}

	override func keyDown(with event: NSEvent) {
		Keys.update(key: event.keyCode, value: true)
		if event.keyCode == 53 { // escape
            changeRenderMode(isManual: true)
			Engine.Settings.isShowingUI = true
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
		if Engine.Settings.window == .rendering {
			printError("Tried to move camera while rendering.")
		} else {
			Engine.Settings.camera.deriction += SIMD4<Float>.init(Float(event.deltaY), Float(event.deltaX), 0, 0) / 1000
			if (Engine.Settings.camera.deriction.x > Float.pi / 2) {
				Engine.Settings.camera.deriction.x = Float.pi / 2
			}
			if Engine.Settings.camera.deriction.x < Float.pi / -2 {
				Engine.Settings.camera.deriction.x = Float.pi / -2
			}
		}
	}

	override func setFrameSize(_ newSize: NSSize) {
		super.setFrameSize(newSize)
		trackingRect = NSTrackingArea.init(rect: self.frame, options: [NSTrackingArea.Options.mouseMoved, NSTrackingArea.Options.activeWhenFirstResponder], owner: self, userInfo: nil)
		updateTrackingAreas()
	}
}
