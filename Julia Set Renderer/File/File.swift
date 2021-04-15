//
//  File.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 3/28/21.
//  Copyright © 2021 Hezekiah Dombach. All rights reserved.
//

import Foundation
import Combine

class File: Codable, ObservableObject {
	
	
	enum CodingKeys: String, CodingKey {
		case test
	}
	required init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		test = try values.decode(Int.self, forKey: .test)
	}
	
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(test, forKey: .test)
	}
	
	
	func updateView() {
		//ACL
	}
	@Published var test: Int = 0
}

extension File {
}
