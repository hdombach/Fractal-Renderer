//
//  Keys.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 7/24/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import Foundation

//Class for remembering key presses
class Keys {
	public static var dictionary: [UInt16: Bool] = [
		13: false,
		0: false,
		1: false,
		2: false,
		12: false,
		14: false
	]
	public static var keyCodes: [Character: UInt16] = [
		"w": 13,
		"a": 0,
		"s": 1,
		"d": 2,
		"q": 12,
		"e": 14
	]

	public static func update(key: UInt16, value: Bool) {
		dictionary.updateValue(value, forKey: key)
	}

	public static func isPressed(char: Character) -> Bool {
		if let code = keyCodes[char] {
			if let isPressed = dictionary[code] {
				return isPressed
			}
		}
		print("could not get key \(char)")
		return false
	}
}
