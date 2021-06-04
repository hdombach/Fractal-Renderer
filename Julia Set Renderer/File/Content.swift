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
	@Published var imageSize: SIMD2<Int> = .init(1920, 1080) { didSet { update() } }
	@Published var camera: Camera = Camera() { didSet { update() } }
	@Published var savedCamera: Camera = Camera() { didSet { update() } }
	@Published var skyBox: [LightInfo] = [LightInfo.init(color: .init(1, 1, 1), strength: 1, size: 0.9, position: .init(1, 0, 0), channel: 0)] { didSet { updateChannels(); update() } }
	@Published var channels: [ChannelInfo] = [ChannelInfo.init(index: 0, color: .init(1, 1, 1), strength: 1)] { didSet { update() } }
	@Published var materialNodeContainer = NodeContainer() {didSet {
		if materialNodeContainer.constants != oldMaterialNodeContainerConstants {
			oldMaterialNodeContainerConstants = materialNodeContainer.constants
			update()
		}
	}}
	@Published var deNodeContainer = NodeContainer() {didSet {
		if deNodeContainer.constants != oldDeMaterialNodeContainerConstants {
			oldDeMaterialNodeContainerConstants = deNodeContainer.constants
			update()
		}
	}}
	@Published var rayMarchingSettings = RayMarchingSettings() { didSet { update() } }
	@Published var julaSettings = JuliaSetSettings() { didSet { update() } }
	@Published var depthSettings: Float3 = .init(0, 0, 1) { didSet { update() } }
	///ambient, angle
	@Published var shadingSettings: Float2 = .init(0.995, 1) { didSet { update() } }
	///x: groupsize, y: groups
	@Published var kernelSize: Int2 = .init(200, 50)
	@Published var atmosphereSettings = AtmosphereSettings() { didSet { update() }}
	
	var kernelGroupSize: Int { kernelSize.x }
	var kernelGroups: Int { kernelSize.y }
	
	var viewState: ViewSate?
	
	private var oldNodeContainerConstants: [Float] = []
	private var oldMaterialNodeContainerConstants: [Float] = []
	private var oldDeMaterialNodeContainerConstants: [Float] = []
	
	func update() {
		viewState?.updateView()
	}
	
	
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
		case atmosphereSettings
		
		case materialNodeContainer
		case deNodeContainer
	}
	
	override init() {
		super.init()
		deNodeContainer.type = .DE
	}
	
	required init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		
		imageSize = try values.decode(Int2.self, forKey: .imageSize)
		camera = try values.decode(Camera.self, forKey: .camera)
		savedCamera = try values.decode(Camera.self, forKey: .savedCamera)
		skyBox = try values.decode(Array<LightInfo>.self, forKey: .skyBox)
		channels = try values.decode(Array<ChannelInfo>.self, forKey: .channels)
		do {
			materialNodeContainer = try values.decode(NodeContainer.self, forKey: .materialNodeContainer)
			deNodeContainer = try values.decode(NodeContainer.self, forKey: .deNodeContainer)
		} catch {
			materialNodeContainer = try values.decode(NodeContainer.self, forKey: .nodeContainer)
		}
		
		rayMarchingSettings = try values.decode(RayMarchingSettings.self, forKey: .rayMarchingSettings)
		julaSettings = try values.decode(JuliaSetSettings.self, forKey: .juliaSettings)
		depthSettings = try values.decode(Float3.self, forKey: .depthSettings)
		kernelSize = try values.decode(Int2.self, forKey: .kernelSize)
		do {
			atmosphereSettings = try values.decode(AtmosphereSettings.self, forKey: .atmosphereSettings)
		} catch {
			
		}
		
		super.init()
		
		deNodeContainer.type = .DE
		
	}
	
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(imageSize, forKey: .imageSize)
		try container.encode(camera, forKey: .camera)
		try container.encode(savedCamera, forKey: .savedCamera)
		try container.encode(skyBox, forKey: .skyBox)
		try container.encode(channels, forKey: .channels)
		try container.encode(materialNodeContainer, forKey: .materialNodeContainer)
		try container.encode(deNodeContainer, forKey: .deNodeContainer)
		try container.encode(rayMarchingSettings, forKey: .rayMarchingSettings)
		try container.encode(julaSettings, forKey: .juliaSettings)
		try container.encode(depthSettings, forKey: .depthSettings)
		try container.encode(kernelSize, forKey: .kernelSize)
		try container.encode(atmosphereSettings, forKey: .atmosphereSettings)
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
