//
//  maths.metal
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 7/5/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

enum Axis {x, y, z, na};

struct Plane {
	Axis axis;
	float value;
};

//MARK: Material
struct Material {
	float3 rgbAbsorption, rgbEmitted;
	float diffuse;

	float rand(int x, int y, int z)
	{
		 int seed = x + y * 57 + z * 241;
		 seed= (seed<< 13) ^ seed;
		 return (( 1.0 - ( (seed * (seed * seed * 15731 + 789221) + 1376312589) & 2147483647) / 1073741824.0f) + 1.0f) / 2.0f;
	}

	void init(float3 position) {
		rgbEmitted = float3(0, 0, 0);
		//rgbAbsorption = float3(rand(position.x * 2.1, position.y * 2.31, position.z * 2.1), rand(position.x * 2.1, position.y * 3.1, position.z * 5.23), rand(position.x * 2.21, position.y * 1.24, position.z * 2.09));
		//rgbAbsorption = float3(0.5, 0.5, 0.5);
		diffuse = 1;
		float distanceFromCenter = distance(position, float3(0.5, 0.5, 0.5));
		rgbAbsorption = float3(0.3 + 0.18 * metal::precise::sin(distanceFromCenter * 30), 0.4 + 0.15 * metal::precise::sin(distanceFromCenter * 40), 0.8 + 0.15 * metal::precise::sin(distanceFromCenter * 50));//(10 + 5 * sin(distanceFromCenter * 30));

		if (0.02 > distanceFromCenter) {
			//rgbEmitted = float3((0.02 - distanceFromCenter) * 20, 0, 0);
		}


		if (position.x < 0.5 && position.y < 0.5 && position.z < 0.5) {
			//rgbEmitted = float3(0.4, 0.2, 0);
			//rgbAbsorption = float3(0.1, 0.1, 0.1);
		}
	}
};

//MARK: Ray
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

//MARK: Camera
struct Camera {
	float4 position;
	float4 deriction;
	float zoom;
	float depth;
	float4x4 rotateMatrix;
	float2 resolution;

	//text coord is from -1 to 1
	Ray spawnRay(float2 texCoord) {
		float4 rayDeriction = normalize(float4((texCoord.x - 0.5) * resolution.x * zoom, (texCoord.y - 0.5) * resolution.y * zoom, 1, 1));
		rayDeriction *= rotateMatrix;
		Ray ray;
		ray.deriction = normalize(rayDeriction);
		ray.position = position;
		ray.colorAbsorption = float3(1, 1, 1);
		ray.colorSource = float3(0, 0, 0);
		return ray;
	}
};

struct VoxelInfo {
	float3 position;
	float size;
	uint index;
};

struct CollisionInfo {
	float3 position;
	float3 surfaceNormal;
	Material surfaceMaterial;
};

struct DistanceInfo {
	float distance;
	Axis collisionAxis;
};

//Int allows numbers from 0 to 4294967295(2^32)
//MARK: Voxel
struct VoxelAddress {
	uint index;
	uint id;
	bool isDefault() {
		return (index == 0 && id == 0);
	}
};

struct Voxel {
	uint id = 0;
	float opacity;
	bool isEnd;
	bool isDeleted;
	float3 position;
	uint layer;

	float width() {
		return pow(0.5, float(layer));
	}

	VoxelAddress _p;
	VoxelAddress _0;
	VoxelAddress _1;
	VoxelAddress _2;
	VoxelAddress _3;
	VoxelAddress _4;
	VoxelAddress _5;
	VoxelAddress _6;
	VoxelAddress _7;

	//uint children[8];

	VoxelAddress child(int number) {
		switch(number) {
			case 0:
				return _0;
			case 1:
				return _1;
			case 2:
				return _2;
			case 3:
				return _3;
			case 4:
				return _4;
			case 5:
				return _5;
			case 6:
				return _6;
			case 7:
				return _7;
			default:
				return _p;
		}
	}

	void setChild(int number, VoxelAddress newAddress) {
		switch(number) {
			case 0:
				_0 = newAddress;
			case 1:
				_1 = newAddress;
			case 2:
				_2 = newAddress;
			case 3:
				_3 = newAddress;
			case 4:
				_4 = newAddress;
			case 5:
				_5 = newAddress;
			case 6:
				_6 = newAddress;
			case 7:
				_7 = newAddress;
			default:
				_p = newAddress;
		}
	}
    
    void setChildIndex(int number, int newIndex) {
        switch(number) {
            case 0:
                _0.index = newIndex;
            case 1:
                _1.index = newIndex;
            case 2:
                _2.index = newIndex;
            case 3:
                _3.index = newIndex;
            case 4:
                _4.index = newIndex;
            case 5:
                _5.index = newIndex;
            case 6:
                _6.index = newIndex;
            case 7:
                _7.index = newIndex;
            default:
                _p.index = newIndex;
        }
    }

	VoxelAddress getChild(bool3 position) {
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

		return child(index);
	}

	VoxelAddress getChildRay(float4 rayPosition) {
		bool3 newChild;
		float selfWidth = width();
		newChild.x = (rayPosition.x > position.x + selfWidth);
		newChild.y = (rayPosition.y > position.y + selfWidth);
		newChild.z = (rayPosition.z > position.z + selfWidth);


		return getChild(newChild);
	}

	void updateAddress(device Voxel *voxels, int voxelsLength) {
		for (int c = 0; 7 > c; c++) {
			VoxelAddress currentAddress = child(c);
            if (voxels[currentAddress.index].id != currentAddress.id) {
                for (int index = 0; voxelsLength > index; index++) {
                    if (voxels[index].id == currentAddress.id) {
                        //currentAddress.index = index;
                        setChildIndex(c, index);
                        break;
                    }
                }
            }
		}
	}
};

//MARK: Maths
struct MathContainer {
	float rand(int x, int y, int z)
	{
		int seed = x + y * 57 + z * 241;
		seed= (seed<< 13) ^ seed;
		return (( 1.0 - ( (seed * (seed * seed * 15731 + 789221) + 1376312589) & 2147483647) / 1073741824.0f) + 1.0f) / 2.0f;
	}

	float2 getAngle(float3 normal) {
		float2 angle;
		angle.x = atan(normal.y / normal.z);
		float distance = sqrt(normal.y * normal.y + normal.z * normal.z);
		angle.y = atan(normal.x / distance);

		return angle;
	}

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

	float4 intersectionOnPlane(Ray ray, Plane plane) {
		return ray.position + distanceToPlane(ray, plane).distance * ray.deriction;
	}

	//this function assumes the ray is already inside a voxel
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
};

//MARK: Voxel Container
struct VoxelContainer {
	//Voxel voxels[5];
	MathContainer maths;

	/*VoxelAddress getVoxelChild(device Voxel *voxel, int number) {
		switch(number) {
			case 0:
				return voxel->_0;
			case 1:
				return voxel->_1;
			case 2:
				return voxel->_2;
			case 3:
				return voxel->_3;
			case 4:
				return voxel->_4;
			case 5:
				return voxel->_5;
			case 6:
				return voxel->_6;
			case 7:
				return voxel->_7;
			default:
				return voxel->_p;
		}
	}*/
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
		if (voxels[voxelAddress.index].id != voxelAddress.id) {
			//voxelsLength = 900;
			//voxels[0].opacity = voxelsLength;
			for (int index = 0; voxelsLength > index; index++) {
				if (voxels[index].id == voxelAddress.id) {
					return &voxels[index];
				}
			}
			//voxelAddress->id = 0;
			//voxelAddress->index = 0;
			return &voxels[0];
		} else {
			return &voxels[voxelAddress.index];
		}
	}

	DistanceInfo getRayStep(Ray ray, device Voxel *voxels, int voxelsLength) {
		return maths.distanceToVoxel(ray, getVoxel(ray, voxels, voxelsLength));
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
};

//MARK: Raytracing
struct RayTracer {

	float errorDifference = 0.00001;

	struct SingleResult {
		Ray ray;
		float distance;
		CollisionInfo collision;
	};

	//MARK: Skybox
	float3 getSkyBox(Ray ray) {
		MathContainer maths;

		float2 der = maths.getAngle(float3(ray.deriction.x, ray.deriction.y, ray.deriction.z));

		if (der.x > 0.3 && der.x < 0.7) {
			/*if (fmod(der.y, 0.2) < 0.05) {
				return float3(1);
			}*/
			if (der.y > 0.3 && der.y < 0.7 && ray.deriction.y > 0){
				return float3(10);
			}
		}
		return float3(0.5);
	}

	Ray reflect(Ray ray, float3 surfaceNormal, Material surfaceMaterial, uint3 _seed) {
		MathContainer maths;

		Ray returnRay = ray;
		returnRay.colorSource += ray.colorAbsorption * surfaceMaterial.rgbEmitted;
		returnRay.colorAbsorption *= surfaceMaterial.rgbAbsorption;

		int3 seed = int3(0, 0, 0);
		if (false) { //set false for more random bounces
			seed.x = round(returnRay.position.x * 1030);
			seed.y = round(returnRay.position.y * 1241);
			seed.z = round(returnRay.position.z * 1518);
		} else {

			seed.x = (returnRay.position.x * 10335949);
			seed.y = (returnRay.position.y * 12434217);
			seed.z = (returnRay.position.z * 15166486);
		}
		seed += int3(_seed);

		float originalDifference = dot(surfaceNormal, float3(ray.deriction.x, ray.deriction.y, ray.deriction.z));

		float difference;;

		int c = 20;

		do {
			seed -= int3(123, 233, 1212);
			float3 newNormal;
			newNormal.x = surfaceNormal.x + (maths.rand(seed.z, seed.x, seed.y) * 92 - 31) * surfaceMaterial.diffuse;
			newNormal.y = surfaceNormal.y + (maths.rand(seed.x - 47, seed.y + 21, seed.z - 34) * 82 - 31) * surfaceMaterial.diffuse;
			newNormal.z = surfaceNormal.z + (maths.rand(seed.y + 12, seed.z + 64, seed.x - 58) * 32 - 21) * surfaceMaterial.diffuse;
			newNormal = normalize(newNormal);
			returnRay.deriction = metal::reflect(ray.deriction, float4(newNormal, 0));
			difference = dot(surfaceNormal, float3(returnRay.deriction.x, returnRay.deriction.y, returnRay.deriction.z));
			c--;
		} while (0 < difference * originalDifference);
		return returnRay;
	}

	SingleResult shootRay(Ray rayIn, device Voxel *voxels, bool showVoxels, int voxelsLength) {
		VoxelContainer container;
		MathContainer maths;
		Ray ray = rayIn;


		device Voxel *rootVoxel = &voxels[1];

		DistanceInfo distance = {0, na};
		while (10000 > distance.distance) {
			DistanceInfo step = {0, na};
			if (maths.cubeContainsRay(ray, rootVoxel)) {
				device Voxel *intersectedVoxel = container.getVoxel(ray, voxels, voxelsLength);
				if (intersectedVoxel->opacity > 0.5) {
					ray.march(errorDifference * -2);
					break;
				}
				if (showVoxels) {
					ray.colorAbsorption *= float3(0.9);
				}
				step = maths.distanceToVoxel(ray, intersectedVoxel);
			} else {
				step = maths.distanceToCube(ray, rootVoxel);
			}
			step.distance += errorDifference;
			ray.march(step.distance);
			distance.distance += step.distance;
			distance.collisionAxis = step.collisionAxis;
		}

		Material material;
		material.init(float3(ray.position.x, ray.position.y, ray.position.z));

		CollisionInfo collide;
		collide.position = float3(ray.position.x, ray.position.y, ray.position.z);
		collide.surfaceMaterial = material;
		collide.surfaceNormal = maths.getNormal(distance.collisionAxis);


		SingleResult result;
		result.distance = distance.distance;
		result.ray = ray;
		result.collision = collide;

		return result;
	}

	float4 rayCast(float2 pos, Camera camera, int bounceLimit, device Voxel *voxels, uint3 seed, bool showVoxels, int voxelsLength) {
		MathContainer maths;
		Ray ray = camera.spawnRay(pos);

		//return float4(maths.rand(89, 1325, 34), maths.rand(12549018243, -78958, 1982741), maths.rand(12509, 105981823, -1093582123), maths.rand(15901283, 1509825, 1029851));

		int bounces = 0;
		while (bounces < bounceLimit) {
			SingleResult result = shootRay(ray, voxels, showVoxels, voxelsLength);
			ray = result.ray;
			if (result.distance > 100000) {
				ray.colorSource += ray.colorAbsorption * getSkyBox(ray);
				break;
			}
			ray.colorAbsorption = ray.colorAbsorption * (1 - result.distance / 10);
			if (result.collision.surfaceNormal.x == 0 && result.collision.surfaceNormal.y == 0 && result.collision.surfaceNormal.z == 0) {
				//return float4(1, 0, 0, 1);
			}
			ray = reflect(ray, result.collision.surfaceNormal, result.collision.surfaceMaterial, seed);
			bounces ++;
		}
		return float4((ray.colorSource), 1);
	}

	float4 depthMap(float2 pos, Camera camera, device Voxel *voxels, int voxelsLength) {
		Ray ray = camera.spawnRay(pos);

		SingleResult result = shootRay(ray, voxels, false, voxelsLength);

		float4 color = float4(result.distance);
		if (result.distance > 100) {
			color = float4(getSkyBox(ray), 1);
			return color;
		}
		color = 1 - (color - 0.2) / color;
		return color;
	}
};
