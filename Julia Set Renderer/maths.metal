//
//  maths.metal
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 7/15/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;


struct Ray {
	float4 position;
	float4 deriction;

	float3 colorAbsorption;
	float3 colorSource;

	void normalize() {
		deriction = metal::normalize(deriction);
	};

	void march(float distance) {
		position += deriction * distance;
	}
};


enum Axis {x, y, z, na};

struct Plane {
	Axis axis;
	float value;
};

/*void yeet() {
	return;
	//return 5;
}*/

/*float distanceToPlane(Ray ray, Plane plane) {
	if (plane.axis == x) {
		return (plane.value - ray.position.x) / ray.deriction.x;
	} else if (plane.axis == y) {
		return (plane.value - ray.position.y) / ray.deriction.y;
	} else if (plane.axis == z) {
		return (plane.value - ray.position.z) / ray.deriction.z;
	}
	return 1000009140924;
}
*/
