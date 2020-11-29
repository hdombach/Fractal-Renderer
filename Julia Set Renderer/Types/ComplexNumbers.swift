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
    
    static func * (lhs: Complex, rhs: Float) -> Complex {
        return Complex(lhs.real * rhs, lhs.imaginary * rhs)
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
    
    static func power(_ base: Complex, _ exponent: Float) -> Complex {
        var theta = atan(base.imaginary / base.real)
        if (base.real == 0) {
            theta = 0
        }
        if (base.real < 0) {
            theta += Float.pi
        }
        //r^n
        var rn: Float = pow(Float(base.magnitude()), exponent)
        return Complex.init(rn * cos(exponent * theta), rn * sin(exponent * theta))
    }
	
}

class JuliaSet {
    
    var iterations = 20

	func getBasic(point: Complex, c: Complex) -> Bool {
		var x = point
		for _ in 1...iterations {
            x = Complex.power(x, 4) + c
			if x.magnitude() > 2 {
				return false
			}
		}

		return true
	}
}

class LinearJuliaSet: JuliaSet {
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
    
    func getLinear(point: Complex, z: Float) -> Bool {
        return getBasic(point: point, c: generateComplex(value: z))
    }
}
