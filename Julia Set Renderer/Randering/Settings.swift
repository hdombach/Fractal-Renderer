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

enum RenderMode: Int32 {
    case JuliaSet = 0
    case Mandelbulb = 1
}

class RenderSettings {
    let delayTime = 1
	var isReady = true

	var observed: ObservedRenderSettings!

	init() {
		observed = .init(source: self)
		savedCamera = camera
        delaySet()
	}

	func delaySet() {
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
				}

                if self.observed.renderMode != self.renderMode {
                    self.observed.renderMode = self.renderMode
                }
                
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

	var samples: Int = 0
    
    //0 julia set
    //1 mandelbulb
    var renderMode: RenderMode = .JuliaSet
}

final class ObservedRenderSettings: ObservableObject {
	var sourceSettings: RenderSettings

	@Published var kernelSize: (groupSize: Int, groups: Int) {
		didSet {
			if sourceSettings.kernelSize != self.kernelSize {
				sourceSettings.kernelSize = self.kernelSize
			}
		}
	}

	@Published var imageSize: (Int, Int) {
		didSet {
			if sourceSettings.imageSize != self.imageSize {
				sourceSettings.imageSize = self.imageSize
			}
		}
	}

	@Published var camera: Camera {
		didSet {
			if sourceSettings.camera != self.camera {
				sourceSettings.camera = self.camera
			}
		}
	}

	@Published var progress: String {
		didSet {
			if sourceSettings.progress != self.progress {
				sourceSettings.progress = self.progress
			}
		}
	}
    
    @Published var renderMode: RenderMode {
        didSet {
            print("update render moe", oldValue, renderMode)
            if sourceSettings.renderMode != self.renderMode {
                sourceSettings.renderMode = self.renderMode
            }
        }
    }

	init(source: RenderSettings) {
		sourceSettings = source
		self.imageSize = sourceSettings.imageSize
		self.camera = sourceSettings.camera
		self.kernelSize = sourceSettings.kernelSize
		self.progress = sourceSettings.progress
        self.renderMode = sourceSettings.renderMode
	}
}

enum WindowView {
	case preview
	case rendering
    case paused
}

struct Settings_Previews: PreviewProvider {
	static var previews: some View {
		/*@START_MENU_TOKEN@*/Text("Hello, World!")/*@END_MENU_TOKEN@*/
	}
}
