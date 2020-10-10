//
//  ComplexNumbers.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 8/19/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import Foundation

struct JuliaSetSettings {
	var realSlope: Float
	var realIntercept: Float
	var imaginarySlope: Float
	var imaginaryIntercept: Float
	var iterations: Int

	init(rSlope: Float = 1, rIntercept: Float = 0, iSlope: Float = 1, iIntercept: Float = 0, iterations: Int = 20) {
		self.realSlope = rSlope
		self.realIntercept = rIntercept
		self.imaginarySlope = iSlope
		self.imaginaryIntercept = iIntercept
		self.iterations = iterations
	}
}

struct Complex: Equatable {

	var real: Float
	var imaginary: Float

	init(_ real: Float, _ imaginary: Float) {
		self.real = real
		self.imaginary = imaginary
	}

	static func + (lhs: Complex, rhs: Complex) -> Complex {
		return Complex(lhs.real + rhs.real, lhs.imaginary + rhs.imaginary)
	}

	static func - (lhs: Complex, rhs: Complex) -> Complex {
		return Complex(lhs.real - rhs.real, lhs.imaginary - rhs.imaginary)
	}

	static func * (lhs: Complex, rhs: Complex) -> Complex {
		return Complex(lhs.real * rhs.real - lhs.imaginary * rhs.imaginary, lhs.imaginary * rhs.real + lhs.real * rhs.imaginary)
	}

	func squared() -> Complex {
		return self * self
	}

	func magnitude() -> Float {
		return sqrt(self.real * self.real + self.imaginary * self.imaginary)
	}

	func round() -> Complex {
		return Complex(self.real.rounded(), self.imaginary.rounded())
	}
	
}

class JuliaSet {
	//var c: Complex = Complex(0, 0)

	//var value: Float = 0

	//var iterations: Int = 20

	//var pointGen: ComGen

	//init(iterations: Int = 20, value: Float = 0, pointGen: ComGen = linearComGen()) {
		//self.c = c
		//self.iterations = iterations
		//self.value = value
		//self.pointGen = pointGen
	//}

	func getBasic(point: Complex, c: Complex, iterations: Int = 20) -> Bool {
		var x = point
		for _ in 1...iterations {
			x = x.squared() + c
			if x.magnitude() > 2 {
				return false
			}
		}

		return true
	}

	/*func getBasic(pointGen: ComGen = Engine.MainPointGen, zValue: Float, c: Complex) -> Bool {
		return self.getBasic(point: pointGen.generateComplex(value: zValue), c: c)
	}*/

	/*func getBasic(c: Complex) -> Bool {
		return self.getBasic(pointGen: self.pointGen, c: c)
	}*/
}

///Generates Complex Numbers for Julia Set
protocol ComGen {
	func generateComplex(value: Float) -> Complex
}

class linearComGen: ComGen {
	var realSlope: Float
	var realIntercept: Float
	var imaginarySlope: Float
	var imaginaryIntercept: Float

	init(rSlope: Float = 1, rIntercept: Float = 0, iSlope: Float = 1, iIntercept: Float = 0) {
		self.realSlope = rSlope
		self.realIntercept = rIntercept
		self.imaginarySlope = iSlope
		self.imaginaryIntercept = iIntercept
	}

	func generateComplex(value: Float) -> Complex {
		return Complex(value * realSlope + realIntercept, value * imaginarySlope + imaginaryIntercept)
	}
}
