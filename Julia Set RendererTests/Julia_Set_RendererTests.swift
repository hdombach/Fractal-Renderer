//
//  Julia_Set_RendererTests.swift
//  Julia Set RendererTests
//
//  Created by Hezekiah Dombach on 8/19/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import XCTest
import Foundation
import simd
@testable import Julia_Set_Renderer

class Julia_Set_RendererTests: XCTestCase {

	func testComplexAddition() {
		XCTAssert(Complex(1, 4) + Complex(4, 2) == Complex(5, 6))
		print(Complex(1, 4) + Complex(4, 2))
	}

	func testComplexSubtraction() {
		XCTAssert(Complex(1, 4) - Complex(4, 2) == Complex(-3, 2))
	}

	func testMultiplication() {
		XCTAssert(Complex(1, 4) * Complex(4, 2) == Complex(-4, 18))
	}

	func testSquaring() {
		XCTAssert(Complex(2, 5).squared() == Complex(-21, 20))
	}

	func testMagnitude() {
		XCTAssert(Complex(3, 4).magnitude() == 5)
	}
	func testyeet() {
		let test: Double = log2(8)
		print(test)
		XCTAssert(test == 3)
	}

	func testVoxels() {
		let container = VoxelContainer.init()
		container.loadBegin()
		container.load(passCount: 10000)
		for voxel in container.voxels {
			print(voxel.id, voxel.isEnd, voxel._0.id, voxel._0.index, voxel._1.id, voxel._2.id, voxel._3.id, voxel._4.id, voxel._5.id, voxel._6.id, voxel._7.id)
		}
	}
}
