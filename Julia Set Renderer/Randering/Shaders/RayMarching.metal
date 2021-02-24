//
//  RayMarching.metal
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 12/18/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

#include <metal_stdlib>
#include "MathContainer.metal"
using namespace metal;

struct RayMarchInfo {
	float d;
	float orbitLife;
	float3 orbit;
};

//Contains functions that are useful when calculation rayMarching distances
struct RayMarching {
	bool cubeContainsRay(Ray ray, device Voxel *voxel) {
		Voxel cube = *voxel;
		if (ray.position.x > cube.position.x && ray.position.x < cube.position.x + cube.width()) {
			if (ray.position.y > cube.position.y && ray.position.y < cube.position.y + cube.width()) {
				if (ray.position.z > cube.position.z && ray.position.z < cube.position.z + cube.width()) {
					return true;
				}
			}
		}
		return false;
	}
	
	
	float3 getNormal(Axis axis) {
		switch (axis) {
			case x:
				return float3(1, 0, 0);
			case y:
				return float3(0, 1, 0);
			case z:
				return float3(0, 0, 1);
			case na:
				return float3(0, 0, 0);
		}
	}
	
	
	VoxelAddress getVoxelChild2(bool3 position, device Voxel *voxel) {
		uint index = 0;
		if (position.x) {
			index += 1;
		}
		if (position.y) {
			index += 2;
		}
		if (position.z) {
			index += 4;
		}
		
		Voxel v = *voxel;
		return v.child(index);
	}
	VoxelAddress getVoxelChildAtRay(float4 rayPosition, device Voxel *voxel) {
		bool3 newChild;
		Voxel newVoxel = *voxel;
		float width = newVoxel.width() / 2;
		newChild.x = (rayPosition.x > newVoxel.position.x + width);
		newChild.y = (rayPosition.y > newVoxel.position.y + width);
		newChild.z = (rayPosition.z > newVoxel.position.z + width);
		
		return getVoxelChild2(newChild, voxel);
	}
	
	device Voxel * getVoxel(VoxelAddress voxelAddress, device Voxel *voxels, int voxelsLength) {
		// VoxelContainer container;
		return &voxels[voxelAddress.index];
	}
	
	device Voxel * getVoxel(Ray atRay, device Voxel *voxels, int voxelsLength) {
		device Voxel *currentVoxel = &voxels[1];
		
		while (!currentVoxel->isEnd) {
			VoxelAddress newAddress = getVoxelChildAtRay(atRay.position, currentVoxel);
			if (newAddress.isDefault()) {
				return currentVoxel;
			}
			currentVoxel = getVoxel(newAddress, voxels, voxelsLength);
		}
		
		return currentVoxel;
	}
	
	DistanceInfo getVoxelRayStep(Ray ray, device Voxel *voxels, int voxelsLength) {
		MathContainer maths;
		return maths.distanceToVoxel(ray, getVoxel(ray, voxels, voxelsLength));
	}
	
	RayMarchInfo newBulbDE(float3 pos, RayMarchingSettings settings) {
		float3 z = pos;
		float dr = 1;
		float r = 0;
		float power = settings.mandelbulbPower;
		uint iterations = settings.iterations;
		RayMarchInfo info;
		info.orbitLife = iterations;
		for (int i = 0; i < iterations; i++) {
			r = length(z);
			if (r > settings.bailout) {
				info.orbitLife = i;
				break;
			}
			
			//convert to polar
			float theta = acos(z.z / r);
			float phi = atan(z.y / z.x);
			dr = pow(r, power - 1) * power * dr + 1;
			
			//scale and rotate the point
			float zr = pow(r, power);
			theta = theta * power;
			phi = phi * power;
			
			//convert back to cartesian
			z = zr * float3(sin(theta) * cos(phi), sin(phi) * sin(theta), cos(theta));
			z += pos;
		}
		info.d = 0.5 * log(r) * r / dr;
		info.orbit = z;
		return info;
	}
	
	float3 mirror(float3 p, float3 normal) {
		return p - 2 * fmin(0, dot(p, normal)) * normal;
	}
	
	float TriangleDE(float3 z, RayMarchingSettings settings)
	{
		float Scale = 2;
		float Offset = 1;
		int n = 0;
		while (n < settings.iterations) {
			if(z.x+z.y<0) z.xy = -z.yx; // fold 1
			if(z.x+z.z<0) z.xz = -z.zx; // fold 2
			if(z.y+z.z<0) z.zy = -z.yz; // fold 3
			z = z*Scale - Offset*(Scale-1.0);
			n++;
		}
		return (length(z) ) * pow(Scale, -float(n));
	}
	
	RayMarchInfo SphereDE(float3 pos, float r, RayMarchingSettings settings) {
		RayMarchInfo info;
		float3 c = float3(0.5, 0.5, 0.5);
		info.d = length(pos - c) - r;
		//info.d = max(length(fmod(pos, float(1)) - c) - r, length(pos - c) - 10);
		info.orbitLife = settings.iterations;
		return info;
	}
	
	RayMarchInfo DE(float3 pos, RayMarchingSettings settings) {
		//RayMarchInfo info;
		//info.orbitLife = settings.iterations;
		//info.d = TriangleDE(mirror(pos, float3(0, 1, 0)), settings);
		return newBulbDE(pos, settings);
	}
	
	float3 DEnormal(float3 pos, RayMarchingSettings settings) {
		//e is an abitrary number
		//e can cause white specks to appear if chosen wrongly
		float e = 0.0001;
		float n = DE(pos, settings).d;
		float dx = DE(pos + float3(e, 0, 0), settings).d - n;
		float dy = DE(pos + float3(0, e, 0), settings).d - n;
		float dz = DE(pos + float3(0, 0, e), settings).d - n;
		
		return normalize(float3(dx, dy, dz) * -1);
	}
};
