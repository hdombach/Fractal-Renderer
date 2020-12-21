//
//  MathContainer.metal
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 12/18/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

#include <metal_stdlib>
#include "Types.metal"
using namespace metal;

struct MathContainer {
	// Generate a random float in the range [0.0f, 1.0f] using x, y, and z (based on the xor128 algorithm)
	float rand(int x, int y, int z) {
		int seed = x + y * 57 + z * 241;
		seed= (seed<< 13) ^ seed;
		return (( 1.0 - ( (seed * (seed * seed * 15731 + 789221) + 1376312589) & 2147483647) / 1073741824.0f) + 1.0f) / 2.0f;
	}
	
	//MARK: Problem
	float2 getAngle(float3 normal) {
		float2 angle;
		angle.x = atan(normal.y / normal.z);
		float distance = sqrt(normal.y * normal.y + normal.z * normal.z);
		angle.y = atan(normal.x / distance);
		
		return angle;
	}
	
	//MARK: Problem
	float3 getNormal(float2 angle) {
		
		float3x3 xRotation = float3x3 {
			float3(1, 0, 0),
			float3(0, cos(angle.x), -sin(angle.x)),
			float3(0, sin(angle.x), cos(angle.x))
		};
		
		float3x3 yRotation = float3x3 {
			float3(cos(angle.y), 0, sin(angle.y)),
			float3(0, 1, 0),
			float3(-sin(angle.y), 0, cos(angle.y))
		};
		
		return xRotation * yRotation * float3(0, 0, 1);
	}
	
	//MARK: Problem
	DistanceInfo distanceToPlane(Ray ray, Plane plane) {
		if (plane.axis == x) {
			float xDistance = (plane.value - ray.position.x) / ray.deriction.x;
			if (xDistance > 0) {
				return {xDistance, x};
			} else {
				return {FLT_MAX, x};
			}
		} else if (plane.axis == y) {
			float yDistance =  (plane.value - ray.position.y) / ray.deriction.y;
			if (yDistance > 0) {
				return {yDistance, y};
			} else {
				return {FLT_MAX, y};
			}
		} else if (plane.axis == z) {
			float zDistance = (plane.value - ray.position.z) / ray.deriction.z;
			if (zDistance > 0) {
				return {zDistance, z};
			} else {
				return {FLT_MAX, z};
			}
		}
		return {FLT_MAX, na};
	}
	
	//MARK: Problem
	float4 intersectionOnPlane(Ray ray, Plane plane) {
		return ray.position + distanceToPlane(ray, plane).distance * ray.deriction;
	}
	
	//this function assumes the ray is already inside a voxel
	//MARK: Problem
	DistanceInfo distanceToVoxel(Ray ray, device Voxel *voxel) {
		Voxel newVoxel = *voxel;
		float3 planes;
		if (ray.deriction.x > 0) {
			planes.x = newVoxel.position.x + newVoxel.width();
		} else {
			planes.x = newVoxel.position.x;
		}
		if (ray.deriction.y > 0) {
			planes.y = newVoxel.position.y + newVoxel.width();
		} else {
			planes.y = newVoxel.position.y;
		}
		if (ray.deriction.z > 0) {
			planes.z = newVoxel.position.z + newVoxel.width();
		} else {
			planes.z = newVoxel.position.z;
		}
		
		DistanceInfo lengthX = distanceToPlane(ray, {x, planes.x});
		DistanceInfo lengthY = distanceToPlane(ray, {y, planes.y});
		DistanceInfo lengthZ = distanceToPlane(ray, {z, planes.z});
		
		if (lengthX.distance < lengthY.distance && lengthX.distance < lengthZ.distance) {
			return lengthX;
		} else if (lengthY.distance < lengthZ.distance) {
			return lengthY;
		} else {
			return lengthZ;
		}
	}
	
	//this function assumes ray is outside the voxel/cube
	//MARK: Problem
	DistanceInfo distanceToCube(Ray ray, device Voxel *voxel) {
		Voxel cube = *voxel;
		float3 planes;
		if (ray.deriction.x > 0) {
			planes.x = cube.position.x;
		} else {
			planes.x = cube.position.x + cube.width();
		}
		if (ray.deriction.y > 0) {
			planes.y = cube.position.y;
		} else {
			planes.y = cube.position.y + cube.width();
		}
		if (ray.deriction.z > 0) {
			planes.z = cube.position.z;
		} else {
			planes.z = cube.position.z + cube.width();
		}
		
		float3 intersectionX = intersectionOnPlane(ray, {x, planes.x}).xyz;
		float3 intersectionY = intersectionOnPlane(ray, {y, planes.y}).xyz;
		float3 intersectionZ = intersectionOnPlane(ray, {z, planes.z}).xyz;
		
		if (intersectionX.y > cube.position.y && intersectionX.y < cube.position.y + cube.width() && intersectionX.z > cube.position.z && intersectionX.z < cube.position.z + cube.width()) {
			return distanceToPlane(ray, {x, planes.x});
		}
		if (intersectionY.x > cube.position.x && intersectionY.x < cube.position.x + cube.width() && intersectionY.z > cube.position.z && intersectionY.z < cube.position.z + cube.width()) {
			return distanceToPlane(ray, {y, planes.y});
		}
		if (intersectionZ.x > cube.position.x && intersectionZ.x < cube.position.x + cube.width() && intersectionZ.y > cube.position.y && intersectionZ.y < cube.position.y + cube.width()) {
			return distanceToPlane(ray, {z, planes.z});
		}
		return {FLT_MAX, na};
	}
};
