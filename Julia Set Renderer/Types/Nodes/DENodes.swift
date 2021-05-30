//
//  DENodes.swift
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 4/21/21.
//  Copyright © 2021 Hezekiah Dombach. All rights reserved.
//

import SwiftUI

func MandelbulbDENode() -> Node {
	var result = Node()
	result.type = .mandelbulbDE
	result.name = "Mandelbulb DE"
	result.functionName = "mandelbulbDE"
	result.color = .nodeDE
	
	result.inputs = [NodeFloat3(0, 0, 0, name: "Position"), NodeFloat(12, name: "Power"), NodeFloat(20, name: "Iterations"), NodeFloat(2, name: "Bailout")]
	result.outputs = [NodeFloat(0, name: "Distance"), NodeFloat3(0, 0, 0, name: "Orbit"), NodeFloat("Orbit Life")]
	
	return result
}

func SphereDENode() -> Node {
	var result = Node()
	result.type = .sphereDE
	result.name = "Sphere DE"
	result.functionName = "sphereDE"
	result.color = .nodeDE
	
	result.inputs = [NodeFloat3(0, 0, 0, name: "Position"), NodeFloat3(0, 0, 0, name: "Center"), NodeFloat(1, name: "Radius")]
	result.outputs = [NodeFloat(0, name: "Distance")]
	
	return result
}

func BoxDENode() -> Node {
	var result = Node()
	result.type = .boxDE
	result.name = "Box DE"
	result.functionName = "boxDE"
	result.color = .nodeDE
	
	result.inputs = [NodeFloat3("position"), NodeFloat3("Center"), NodeFloat3(Float3(1), name: "Size")]
	result.outputs = [NodeFloat("Distance")]
	
	return result
}

func IntersectNode() -> Node {
	var result = Node()
	result.type = .intersect
	result.name = "Intersect"
	result.functionName = "intersect"
	result.color = .nodeDE
	
	result.inputs = [NodeFloat("value"), NodeFloat("value")]
	result.outputs = [NodeFloat("Value")]
	
	return result
}

func UnionNode() -> Node {
	var result = Node()
	result.type = .union
	result.name = "Union"
	result.functionName = "unionNode"
	result.color = .nodeDE
	
	result.inputs = [NodeFloat("value"), NodeFloat("value")]
	result.outputs = [NodeFloat("value")]
	
	return result
}

func DifferenceNode() -> Node {
	var result = Node()
	result.type = .difference
	result.name = "Difference"
	result.functionName = "difference"
	result.color = .nodeDE
	
	result.inputs = [NodeFloat("value"), NodeFloat("value")]
	result.outputs = [NodeFloat("value")]
	
	return result
}

func SmoothIntersectNode() -> Node {
	var result = Node()
	result.type = .smoothIntersect
	result.name = "Smooth Intersect"
	result.functionName = "smoothIntersect"
	result.color = .nodeDE
	
	result.inputs = [NodeFloat("value"), NodeFloat("value"), NodeFloat("Smoothness")]
	result.outputs = [NodeFloat("value")]
	
	return result
}

func SmoothUnionNode() -> Node {
	var result = Node()
	result.type = .smoothUnion
	result.name = "Smooth Union"
	result.functionName = "smoothUnion"
	result.color = .nodeDE
	
	result.inputs = [NodeFloat("value"), NodeFloat("value"), NodeFloat("Smoothness")]
	result.outputs = [NodeFloat("value")]
	
	return result
}

func SmoothDifferenceNode() -> Node {
	var result = Node()
	result.type = .smoothDifference
	result.name = "Smooth Difference"
	result.functionName = "smoothDifference"
	result.color = .nodeDE
	
	result.inputs = [NodeFloat("value"), NodeFloat("value"), NodeFloat("Smoothness")]
	result.outputs = [NodeFloat("value")]
	
	return result
}

func MirrorNode() -> Node {
	var result = Node()
	result.type = .mirror
	result.name = "Mirror"
	result.functionName = "mirror"
	result.color = .nodeDE
	
	result.inputs = [NodeFloat3("Position"), NodeInt("Axis"), NodeFloat("Offset")]
	result.outputs = [NodeFloat3("Position")]
	
	return result
}

func RotateNode() -> Node {
	var result = Node()
	result.type = .rotate
	result.name = "Rotate"
	result.functionName = "rotate"
	result.color = .nodeDE
	
	result.inputs = [NodeFloat3("Position"), NodeFloat("Ange"), NodeFloat3("Axis")]
	result.outputs = [NodeFloat3("Position")]
	
	return result
}
