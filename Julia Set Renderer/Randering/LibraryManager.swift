//
//  LibraryManager.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 1/26/21.
//  Copyright © 2021 Hezekiah Dombach. All rights reserved.
//

import MetalKit

class LibraryManager {
	private var previewRenderPipelineState: MTLRenderPipelineState!
	private var mainRenderPipelineState: MTLRenderPipelineState!
	
	private var mainComputePipelineState: MTLComputePipelineState!
	private var resetComputePipelineState: MTLComputePipelineState!
	
	var samplerState: MTLSamplerState!
	
	enum RenderPipelineState {
		case preview
		case render
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
	
	func loadLibrary(material: String?, de: String?, completion: @escaping () -> ()) {
		let url = Bundle.main.path(forResource: "RuntimeShaders", ofType: "txt")
		var code = "Hi"
		do {
			try code = String(contentsOfFile: url ?? "Error")
		} catch {
			print(error)
		}
		
		if material != nil {
			if let range = code.range(of: "//INSERT_MATERIAL//") {
				code.insert(contentsOf: material!, at: range.lowerBound)
			}
		}
		
		let testUrl = Bundle.main.path(forResource: "Types.metal", ofType: ".metal")
		do {
			try print(String(contentsOfFile: testUrl ?? "Error"))
		} catch {
			print(error)
		}
		
		Engine.Device.makeLibrary(source: code, options: nil) { (library, compileError) in
			if compileError != nil {
				print(compileError!)
			}
			self.setUp(library: library)
			completion()
		}
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
		let previewFragmentShader = library?.makeFunction(name: "depth_fragment_shader")
		
		let previewRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
		
		previewRenderPipelineDescriptor.colorAttachments[0].pixelFormat = Engine.PixelFormat.0
		previewRenderPipelineDescriptor.vertexFunction = vertexShader
		previewRenderPipelineDescriptor.fragmentFunction = previewFragmentShader
		previewRenderPipelineDescriptor.vertexDescriptor = vertexDescriptor
		
		do {
			previewRenderPipelineState = try Engine.Device.makeRenderPipelineState(descriptor: previewRenderPipelineDescriptor)
		} catch {
			print(error)
		}
		
		//Create Render state
		let mainFragmentShader = library?.makeFunction(name: "basic_fragment_shader")
		
		let mainRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
		
		mainRenderPipelineDescriptor.colorAttachments[0].pixelFormat = Engine.PixelFormat.0
		mainRenderPipelineDescriptor.vertexFunction = vertexShader
		mainRenderPipelineDescriptor.fragmentFunction = mainFragmentShader
		mainRenderPipelineDescriptor.vertexDescriptor = vertexDescriptor
		
		do {
			mainRenderPipelineState = try Engine.Device.makeRenderPipelineState(descriptor: mainRenderPipelineDescriptor)
		} catch {
			print(error)
		}
		
		//create sampler state
		let samplerDescriptor = MTLSamplerDescriptor()
		samplerDescriptor.minFilter = .linear
		samplerDescriptor.magFilter = .linear
		samplerDescriptor.label = "basic"
		samplerState = Engine.Device.makeSamplerState(descriptor: samplerDescriptor)
		
		
		//Create Reset Compute function
		let resetFunction = library?.makeFunction(name: "reset_compute_shader")
		
		do {
			resetComputePipelineState = try Engine.Device.makeComputePipelineState(function: resetFunction!)
		} catch {
			print(error)
		}
		
		//Create Main compute function
		let mainFunction = library?.makeFunction(name: "ray_compute_shader")
		
		do {
			mainComputePipelineState = try Engine.Device.makeComputePipelineState(function: mainFunction!)
		} catch {
			print(error)
		}
	}
}
