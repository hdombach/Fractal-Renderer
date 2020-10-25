//
//  BufferTests.swift
//  Julia Set RendererTests
//
//  Created by Hezekiah Dombach on 10/22/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

import XCTest

@testable import Julia_Set_Renderer

class BufferTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        var voxels = [Voxel.init(), Voxel.init(), Voxel.init()]
        voxels.withUnsafeMutableBufferPointer { (pointer) -> () in
            pointer[0]
        }
        
        
    }

}
