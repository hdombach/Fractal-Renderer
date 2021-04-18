//
//  LibraryManager.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 1/26/21.
//  Copyright © 2021 Hezekiah Dombach. All rights reserved.
//

import MetalKit


//Creates and manages all the states that are used when interacting with the gpu
class LibraryManager {
	private var previewRenderPipelineState: MTLRenderPipelineState!
	private var depthRenderPipelineState: MTLRenderPipelineState!
	private var mainRenderPipelineState: MTLRenderPipelineState!
	
	private var mainComputePipelineState: MTLComputePipelineState!
	private var resetComputePipelineState: MTLComputePipelineState!
	
	var document: Document!
	
	var samplerState: MTLSamplerState!
	
	init(doc: Document) {
		document = doc
		do {
			try document.content.nodeContainer.compile(library: self, viewState: document.viewState)
		} catch {
			loadDefaultDibrary(completion: nil)
		}
	}
	
	enum RenderPipelineState {
		case preview
		case render
		case depth
	}
	enum ComputePipelineState {
		case render
		case reset
	}
	
	subscript(state: RenderPipelineState) -> MTLRenderPipelineState {
		switch (state) {
		case .preview:
			return previewRenderPipelineState
			
		case .render:
			return mainRenderPipelineState
		
		case .depth:
			return depthRenderPipelineState
			
		}
	}
	
	subscript(state: ComputePipelineState) -> MTLComputePipelineState {
		switch (state) {
		case .render:
			return mainComputePipelineState
			
		case .reset:
			return resetComputePipelineState
		}
	}
	
	func loadLibrary(material: String?, de: String?, completion: (() -> ())?) {
		let url = Bundle.main.path(forResource: "Shaders", ofType: "txt")
		var code: String;
		do {
			try code = String(contentsOfFile: url!)
		} catch {
			assertionFailure(error.localizedDescription)
			return;
		}
		
		//Manually do the #include commands
		var imported: [String] = []
		
		while (true) {
			if let range = code.range(of: "#include \"") {
				let start = range.lowerBound
				var lower = code.index(range.lowerBound, offsetBy: 10)
				var upper = range.upperBound
				while (code[upper] != ".") {
					upper = code.index(after: upper)
				}
				
				upper = code.index(before: upper)
				
				let fileName = String(code[lower...upper])
				print(fileName)
				
				repeat {
					upper = code.index(after: upper)
				} while (code[upper] != "\"")
				
				code.removeSubrange(start...upper)
				
				if !imported.contains(fileName) {
					var url = Bundle.main.path(forResource: fileName, ofType: "metal")
					if url == nil {
						url = Bundle.main.path(forResource: fileName, ofType: "txt")
					}
					
					var file: String!
					do {
						try file = String(contentsOfFile: url!)
					} catch {
						print(error)
						return;
					}
					code.insert(contentsOf: file, at: start)
					imported.append(fileName)
				}
			} else {
				break;
			}
		}
		
		
		
		if material != nil {
			if let range = code.range(of: "//INSERT_MATERIAL//") {
				code.insert(contentsOf: material!, at: range.lowerBound)
			}
		}
		
		if completion != nil {
			
			document.graphics.device.makeLibrary(source: code, options: nil) { (library, compileError) in
				if compileError != nil {
					print(code)
					print(compileError!)
				} else {
					
				}
				self.setUp(library: library)
				completion!()
			}
		} else {
			do {
				let library = try document.graphics.device.makeLibrary(source: code, options: nil)
				self.setUp(library: library)
			} catch {
				print(error)
			}
		}
	}
	
	func loadDefaultDibrary(completion: (() -> ())?) {
		loadLibrary(material: nil, de: nil, completion: completion)
	}
	
	func setUp(library: MTLLibrary?) {
		
		//create vertex stuff
		let vertexShader = library?.makeFunction(name: "basic_vertex_shader")
		
		let vertexDescriptor = MTLVertexDescriptor()
		
		//Position
		vertexDescriptor.attributes[0].format = .float3
		vertexDescriptor.attributes[0].bufferIndex = 0
		vertexDescriptor.attributes[0].offset = 0
		
		//Color
		vertexDescriptor.attributes[1].format = .float4
		vertexDescriptor.attributes[1].bufferIndex = 0
		vertexDescriptor.attributes[1].offset = SIMD3<Float>.size
		
		//Texture Coordinate
		vertexDescriptor.attributes[2].format = .float2
		vertexDescriptor.attributes[2].bufferIndex = 0
		vertexDescriptor.attributes[2].offset = SIMD3<Float>.size + SIMD4<Float>.size
		
		vertexDescriptor.layouts[0].stride = Vertex.stride
		
		//Create preview state
		let previewFragmentShader = library?.makeFunction(name: "preview_fragment_shader")
		
		let previewRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
		
		previewRenderPipelineDescriptor.colorAttachments[0].pixelFormat = document.graphics.pixelFormat.0
		previewRenderPipelineDescriptor.vertexFunction = vertexShader
		previewRenderPipelineDescriptor.fragmentFunction = previewFragmentShader
		previewRenderPipelineDescriptor.vertexDescriptor = vertexDescriptor
		
		do {
			previewRenderPipelineState = try document.graphics.device.makeRenderPipelineState(descriptor: previewRenderPipelineDescriptor)
		} catch {
			print(error)
		}
		
		//Create depth state
		let depthFragmentShader = library?.makeFunction(name: "depth_fragment_shader")
		
		let depthRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
		
		depthRenderPipelineDescriptor.colorAttachments[0].pixelFormat = document.graphics.pixelFormat.0
		depthRenderPipelineDescriptor.vertexFunction = vertexShader
		depthRenderPipelineDescriptor.fragmentFunction = depthFragmentShader
		depthRenderPipelineDescriptor.vertexDescriptor = vertexDescriptor
		
		do {
			depthRenderPipelineState = try document.graphics.device.makeRenderPipelineState(descriptor: depthRenderPipelineDescriptor)
		} catch {
			print(error)
		}
		
		//Create Render state
		let mainFragmentShader = library?.makeFunction(name: "basic_fragment_shader")
		
		let mainRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
		
		mainRenderPipelineDescriptor.colorAttachments[0].pixelFormat = document.graphics.pixelFormat.0
		mainRenderPipelineDescriptor.vertexFunction = vertexShader
		mainRenderPipelineDescriptor.fragmentFunction = mainFragmentShader
		mainRenderPipelineDescriptor.vertexDescriptor = vertexDescriptor
		
		do {
			mainRenderPipelineState = try document.graphics.device.makeRenderPipelineState(descriptor: mainRenderPipelineDescriptor)
		} catch {
			print(error)
		}
		
		//create sampler state
		let samplerDescriptor = MTLSamplerDescriptor()
		samplerDescriptor.minFilter = .linear
		samplerDescriptor.magFilter = .linear
		samplerDescriptor.label = "basic"
		samplerState = document.graphics.device.makeSamplerState(descriptor: samplerDescriptor)
		
		
		//Create Reset Compute function
		let resetFunction = library?.makeFunction(name: "reset_compute_shader")
		
		do {
			resetComputePipelineState = try document.graphics.device.makeComputePipelineState(function: resetFunction!)
		} catch {
			print(error)
		}
		
		//Create Main compute function
		let mainFunction = library?.makeFunction(name: "ray_compute_shader")
		
		do {
			mainComputePipelineState = try document.graphics.device.makeComputePipelineState(function: mainFunction!)
		} catch {
			print(error)
		}
		
		print("loaded library")
	}
}
