//
//  Graphics.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 4/13/21.
//  Copyright © 2021 Hezekiah Dombach. All rights reserved.
//

import Foundation
import MetalKit

class Graphics {
	var device: MTLDevice!
	lazy var library: LibraryManager = { LibraryManager(doc: document) }()
	var pixelFormat = (MTLPixelFormat.rgba16Float, MTLPixelFormat.r32Float)
	var renderMode: RenderMode = .Mandelbulb
	var document: Document
	
	init(doc: Document) {
		device = MTLCreateSystemDefaultDevice()
		self.document = doc
	}
}
