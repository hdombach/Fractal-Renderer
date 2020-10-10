//
//  JuliaSetComputeTests.swift
//  Julia Set RendererTests
//
//  Created by Hezekiah Dombach on 8/24/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import XCTest
import MetalKit
@testable import Julia_Set_Renderer

struct TestItem {
	var v1: Complex
	var v2: Complex
	var answer: Complex
}

class JuliaSetComputeTests: XCTestCase {

	func testComputeAddition() {
		var queue = [TestItem(v1: Complex(5, 3), v2: Complex(4, 9), answer: Complex(0, 0))]
		for _  in 0...10 {
			let c1 = Complex(Float.random(in: -100...100), Float.random(in: -100...100))
			let c2 = Complex(Float.random(in: -100...100), Float.random(in: -100...100))
			queue.append(TestItem(v1: c1, v2: c2, answer: Complex(0, 0)))
		}
		var buffer: MTLBuffer?

		func dispatchThreads(_ encoder: MTLComputeCommandEncoder, _ device: MTLDevice) {
			buffer = device.makeBuffer(bytes: &queue, length: MemoryLayout<TestItem>.stride * queue.count, options: [])

			let pointer = buffer?.contents()
			let bufferPointer = UnsafeBufferPointer(start: pointer?.bindMemory(to: TestItem.self, capacity: queue.count), count: queue.count)
			print("hjajlkdejljfdsahljhfadshl", queue[9], bufferPointer[9])

			encoder.setBuffer(buffer, offset: 0, index: 0)

			let threadsPerThreadgroup = MTLSize(width: 100, height: 1, depth: 1)
			let threadsPerGrid = MTLSize.init(width: queue.count, height: 1, depth: 1)

			encoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
		}

		dispatchTestThreads(functionName: "add_test", dispatchFunction: dispatchThreads(_:_:))
		let pointer = buffer?.contents()
		let bufferPointer = UnsafeBufferPointer(start: pointer?.bindMemory(to: TestItem.self, capacity: queue.count), count: queue.count)
		for c in 0...bufferPointer.count - 1 {
			let item = bufferPointer[c]
			print(item.answer, item.v1 * item.v2, item)
			XCTAssert(item.answer.round() == (item.v1.squared()).round())
			XCTAssert(true)
		}
	}

	func dispatchTestThreads(functionName: String, dispatchFunction: (_ encoder: MTLComputeCommandEncoder, _ device: MTLDevice) -> ()) {
		let device = MTLCreateSystemDefaultDevice()

		let commandQueue = device?.makeCommandQueue()

		let defaultLibrary = device?.makeDefaultLibrary()

		let function = defaultLibrary?.makeFunction(name: functionName)
		//XCTAssertNil(function)

		var pipelineState: MTLComputePipelineState!
		do {
			pipelineState = try device?.makeComputePipelineState(function: function!)
		} catch {
			XCTAssertNil(false, "\(error)")
		}

		let commandBuffer = commandQueue?.makeCommandBuffer()
		let encoder = commandBuffer?.makeComputeCommandEncoder()
		encoder?.setComputePipelineState(pipelineState)
		//XCTAssertNil(encoder)
		dispatchFunction(encoder!, device!)

		encoder?.endEncoding()
		commandBuffer?.commit()
		commandBuffer?.waitUntilCompleted()
	}

}
