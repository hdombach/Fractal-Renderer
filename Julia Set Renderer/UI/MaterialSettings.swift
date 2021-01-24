//
//  MaterialSettings.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 12/30/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import SwiftUI

struct MaterialSettings: View {
	@ObservedObject var settings = Engine.Settings
	
	@State var code: String = ""
	
	
	
	var body: some View {
		NodeEditor(nodeContainer: $settings.nodeContainer)
    }
}

struct MaterialSettings_Previews: PreviewProvider {
    static var previews: some View {
        MaterialSettings()
    }
}
