//
//  Number.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 12/18/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import Foundation
import SwiftUI



protocol Number: Any, Strideable, AdditiveArithmetic, SIMDScalar {
	var nsNumber: (NSNumber, NumberTypes) { get set }
}

extension Float: Number {
	var nsNumber: (NSNumber, NumberTypes) {
		get {
			return (NSNumber(value: self), .float)
		}
		set { (newValue)
			self = newValue.0.floatValue
		}
	}
}

extension Int: Number {
	var nsNumber: (NSNumber, NumberTypes) {
		get {
			return (NSNumber(value: self), .int)
		}
		set { (newValue)
			self = newValue.0.intValue
		}
	}
}

extension Double: Number {
	var nsNumber: (NSNumber, NumberTypes) {
		get {
			return (NSNumber(value: self), .double)
		}
		set { (newValue)
			self = newValue.0.doubleValue
		}
	}
}

extension UInt32: Number {
	var nsNumber: (NSNumber, NumberTypes) {
		get {
			return (NSNumber(value: self), .uint32)
		}
		set { (newValue)
			self = newValue.0.uint32Value
		}
	}
}
