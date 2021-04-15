//
//  Application.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 3/28/21.
//  Copyright © 2021 Hezekiah Dombach. All rights reserved.
//

import Foundation

class Application {
	var keys = Keys()
	var mouse: Mouse!
	
	init() {
		
		self.mouse = Mouse(app: self)
	}
}
