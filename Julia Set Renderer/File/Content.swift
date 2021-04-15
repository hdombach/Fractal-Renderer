//
//  Content.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 3/30/21.
//  Copyright © 2021 Hezekiah Dombach. All rights reserved.
//

import Foundation
import Cocoa
import Combine

class Content: NSObject, Codable, ObservableObject {
	@Published var imageSize: SIMD2<Int> = .init(1920, 1080)
	@Published var camera: Camera = Camera()
	@Published var savedCamera: Camera = Camera()
	@Published var skyBox: [LightInfo] = [LightInfo.init(color: .init(1, 1, 1), strength: 1, size: 0.9, position: .init(1, 0, 0), channel: 0)]
	@Published var channels: [ChannelInfo] = [ChannelInfo.init(index: 0, color: .init(1, 1, 1), strength: 1)]
	@Published var nodeContainer = NodeContainer()
	@Published var rayMarchingSettings = RayMarchingSettings()
	@Published var julaSettings = JuliaSetSettings()
	@Published var depthSettings: Float3 = .init(0, 0, 1)
	///x: groupsize, y: groups
	@Published var kernelSize: Int2 = .init(200, 50)
	
	var kernelGroupSize: Int { kernelSize.x }
	var kernelGroups: Int { kernelSize.y }
	
	
	//Loading/Saving
	enum CodingKeys: String, CodingKey {
		case imageSize
		case camera
		case savedCamera
		case skyBox
		case channels
		case nodeContainer
		case rayMarchingSettings
		case juliaSettings
		case depthSettings
		case kernelSize
	}
	
	override init() {
		super.init()
	}
	
	required init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		
		imageSize = try values.decode(Int2.self, forKey: .imageSize)
		camera = try values.decode(Camera.self, forKey: .camera)
		savedCamera = try values.decode(Camera.self, forKey: .savedCamera)
		skyBox = try values.decode(Array<LightInfo>.self, forKey: .skyBox)
		channels = try values.decode(Array<ChannelInfo>.self, forKey: .channels)
		nodeContainer = try values.decode(NodeContainer.self, forKey: .nodeContainer)
		rayMarchingSettings = try values.decode(RayMarchingSettings.self, forKey: .rayMarchingSettings)
		julaSettings = try values.decode(JuliaSetSettings.self, forKey: .juliaSettings)
		depthSettings = try values.decode(Float3.self, forKey: .depthSettings)
		kernelSize = try values.decode(Int2.self, forKey: .kernelSize)
	}
	
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(imageSize, forKey: .imageSize)
		try container.encode(camera, forKey: .camera)
		try container.encode(savedCamera, forKey: .savedCamera)
		try container.encode(skyBox, forKey: .skyBox)
		try container.encode(channels, forKey: .channels)
		try container.encode(nodeContainer, forKey: .nodeContainer)
		try container.encode(rayMarchingSettings, forKey: .rayMarchingSettings)
		try container.encode(julaSettings, forKey: .juliaSettings)
		try container.encode(depthSettings, forKey: .depthSettings)
		try container.encode(kernelSize, forKey: .kernelSize)
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
		while max > channels.count - 1 {
			channels.append(ChannelInfo.init(index: UInt32(channels.count), color: .init(1, 1, 1), strength: 1))
		}
		while max < channels.count - 1 {
			channels.removeLast()
		}
	}
}