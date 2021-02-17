//
//  Settings.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 8/3/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import MetalKit
import Combine
import SwiftUI

enum RenderMode: UInt32 {
    case JuliaSet = 0
    case Mandelbulb = 1
}

var globalId: UInt32 = 0
func generateID() -> UInt32 {
	globalId += 1
	return globalId
}

class JoinedRenderSettings: ObservableObject {
	
	init() {
		savedCamera = camera
	}
	
	func update() {
		Engine.View.setNeedsDisplay(Engine.View.frame)
	}
	
	func updateChannels() {
		var max: UInt32 = 0
		var min: UInt32 = UInt32.max
		for light in skyBox {
			if light.channel > max {
				max = light.channel
			}
			if light.channel < min {
				min = light.channel
			}
		}
		print(max, min)
		while max > channels.count - 1 {
			channels.append(ChannelInfo.init(index: UInt32(channels.count), color: .init(1, 1, 1), strength: 1))
		}
		while max < channels.count - 1 {
			channels.removeLast()
		}
		//print(channels.count, "update")
	}
	
	@Published var window = WindowView.preview {
		didSet {
			update()
			(Engine.View as? RenderView)?.updateRenderMode()
		}
	}
	var exposure: Int = 1
	
	var isRendering: Bool = false
	
	@Published var imageSize: (Int, Int) = (1920, 1080)
	
	@Published var kernelSize: (groupSize: Int, groups: Int) = (200, 50)
	
	@Published var camera: Camera = Camera(position: SIMD4<Float>(0, 0.001, -2, 0), deriction: SIMD4<Float>(0, 0, 0, 0), zoom: 1 / 2000, cameraDepth: 1, rotateMatrix: matrix_identity_float4x4, resolution: SIMD2<Float>(1920, 1080)) {
		didSet {
			update()
		}
	}
	
	var savedCamera: Camera!
	
	@Published var progress: String = "0% (0 / 0)" {
		didSet {
			update()
		}
	}
	
	@Published var skyBox: [LightInfo] = [LightInfo.init(color: .init(1, 1, 1), strength: 1, size: 0.9, position: .init(1, 0, 0), channel: 0)] {
		didSet {
			updateChannels()
			update()
		}
	}
	
	@Published var channels: [ChannelInfo] = [ChannelInfo.init(index: 0, color: .init(1, 1, 1), strength: 1)]
	
	//@Published var nodes: [Node] = []
	@Published var nodeContainer = NodeContainer()
	
	var samples: Int = 0
	
	var renderMode: RenderMode = .Mandelbulb
	
	@Published var rayMarchingSettings: RayMarchingSettings = .init() {
		didSet {
			update()
		}
	}
	
	@Published var juliaSetSettings = JuliaSetSettings() {
		didSet {
			update()
		}
	}
	
	@Published var isShowingUI: Bool = true
}

/*class RenderSettings {
    let delayTime = 0
	var isReady = true

	var observed: ObservedRenderSettings!

	init() {
		observed = .init(source: self)
		savedCamera = camera
        delaySet()
	}
	
	func updateChannels() {
		var max: UInt32 = 0
		var min: UInt32 = UInt32.max
		for light in skyBox {
			if light.channel > max {
				max = light.channel
			}
			if light.channel < min {
				min = light.channel
			}
		}
		print(max, min)
		while max > channels.count - 1 {
			channels.append(ChannelInfo.init(index: UInt32(channels.count), color: .init(1, 1, 1), strength: 1))
		}
		while max < channels.count - 1 {
			channels.removeLast()
		}
		if self.channels != observed.channels {
			self.observed.channels = self.channels
		}
		//print(channels.count, "update")
	}

	private func delaySet() {
		if isReady {
			isReady = false
			let deadline = DispatchTime.now() + Double(delayTime)
			DispatchQueue.main.asyncAfter(deadline: deadline) {
				if self.observed.camera != self.camera {
					self.observed.camera = self.camera
				}

				if self.observed.imageSize != self.imageSize {
					self.observed.imageSize = self.imageSize
				}

				if self.observed.kernelSize != self.kernelSize {
					self.observed.kernelSize = self.kernelSize
				}

				if self.observed.progress != self.progress {
					self.observed.progress = self.progress
					self.observed.update()
					//the update makes sures the view updates while rendering
				}

                if self.observed.renderMode != self.renderMode {
                    self.observed.renderMode = self.renderMode
                }
				if self.observed.channels != self.channels {
					self.observed.channels = self.channels
				}
				//if self.observed.nodes != self.nodes {
					self.observed.nodes = self.nodes
				//}
                
				self.isReady = true
			}
		}
	}

	var window = WindowView.preview
	var exposure: Int = 1

	var imageSize: (Int, Int) = (1920, 1080) {
		didSet {
			delaySet()
		}
	}

	var kernelSize: (groupSize: Int, groups: Int) = (200, 50) {
		didSet {
			delaySet()
		}
	}

    var camera = Camera(position: SIMD4<Float>(0, 0.001, -2, 0), deriction: SIMD4<Float>(0, 0, 0, 0), zoom: 1 / 2000, cameraDepth: 1, rotateMatrix: matrix_identity_float4x4, resolution: SIMD2<Float>(1920, 1080)) {
		didSet {
			delaySet()
		}
	}

	var savedCamera: Camera!

	var progress: String = "0% (0 / 0)" {
		didSet {
			delaySet()
		}
	}
	
	var skyBox: [LightInfo] = [LightInfo.init(color: .init(1, 1, 1), strength: 1, size: 0.9, position: .init(1, 0, 0), channel: 0)]
	
	var channels: [ChannelInfo] = [ChannelInfo.init(index: 0, color: .init(1, 1, 1), strength: 1)] {
		didSet {
			delaySet()
		}
	}
	
	var nodes: [Node] = [AddNode()] {
		didSet {
			delaySet()
		}
	}

	var samples: Int = 0
    
    //0 julia set
    //1 mandelbulb
	var renderMode: RenderMode = .Mandelbulb
	
	var rayMarchingSettings: RayMarchingSettings = .init()
	
	var juliaSetSettings = JuliaSetSettings()
	
	
	var isShowingUI: Bool = true {
		didSet {
			observed.isShowingUI = self.isShowingUI
		}
	}
}

final class ObservedRenderSettings: ObservableObject {
	var sourceSettings: RenderSettings
	
	func update() {
		Engine.View.setNeedsDisplay(Engine.View.frame)
	}

	@Published var kernelSize: (groupSize: Int, groups: Int) {
		didSet {
			if sourceSettings.kernelSize != self.kernelSize {
				sourceSettings.kernelSize = self.kernelSize
				update()
			}
		}
	}

	@Published var imageSize: (Int, Int) {
		didSet {
			if sourceSettings.imageSize != self.imageSize {
				sourceSettings.imageSize = self.imageSize
				update()
			}
		}
	}

	@Published var camera: Camera {
		didSet {
			if sourceSettings.camera != self.camera {
				sourceSettings.camera = self.camera
				update()
			}
		}
	}

	@Published var progress: String {
		didSet {
			if sourceSettings.progress != self.progress {
				sourceSettings.progress = self.progress
				update()
				print("update")
			}
		}
	}
    
    @Published var renderMode: RenderMode {
        didSet {
            if sourceSettings.renderMode != self.renderMode {
                sourceSettings.renderMode = self.renderMode
				update()
            }
        }
    }
	
	@Published var skyBox: [LightInfo] {
		didSet {
			sourceSettings.skyBox = self.skyBox
			sourceSettings.updateChannels()
			update()
		}
	}
	
	@Published var channels: [ChannelInfo] {
		didSet {
			sourceSettings.channels = self.channels
			update()
		}
	}
	
	@Published var nodes: [Node] {
		didSet {
			sourceSettings.channels = self.channels
			update()
		}
	}
	
	@Published var rayMarchingSettings: RayMarchingSettings {
		didSet {
			sourceSettings.rayMarchingSettings = self.rayMarchingSettings
			update()
		}
	}
	
	@Published var isShowingUI: Bool = true

	init(source: RenderSettings) {
		sourceSettings = source
		self.imageSize = sourceSettings.imageSize
		self.camera = sourceSettings.camera
		self.kernelSize = sourceSettings.kernelSize
		self.progress = sourceSettings.progress
        self.renderMode = sourceSettings.renderMode
		self.skyBox = source.skyBox
		self.rayMarchingSettings = source.rayMarchingSettings
		self.channels = source.channels
		self.nodes = source.nodes
	}
}*/

enum WindowView: String, CaseIterable, Identifiable {
	case preview
	case depth
	case rendering
	
	var id: String { self.rawValue }
}

struct Settings_Previews: PreviewProvider {
	static var previews: some View {
		/*@START_MENU_TOKEN@*/Text("Hello, World!")/*@END_MENU_TOKEN@*/
	}
}
