//
//  RenderWindowController.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 7/2/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import Cocoa

class RenderWindowController: NSWindowController {


	convenience init() {
		self.init(windowNibName: "RenderWindowController")
	}

    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
}
