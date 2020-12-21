//
//  Types.metal
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 12/18/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;


enum Axis {x, y, z, na};

struct Plane {
	Axis axis;
	float value;
};

//MARK: RayMarcingSettings
struct RayMarchingSettings {
	float mandelbulbPower;
	int bundleSize;
	float quality;
	uint iterations;
	float bailout;
	float3 colorBase;
	float3 colorVariation;
	float3 colorFrequency;
	float3 colorOffset;
};

//MARK: Colors
struct Colors {
	float3 channel0;
	float3 channel1;
	float3 channel2;
	float3 channel3;
	float3 channel4;
	float3 channel5;
	float3 channel6;
	float3 channel7;
	
	float3 channel(int index) {
		switch (index) {
			case 0:
				return channel0;
			case 1:
				return channel1;
			case 2:
				return channel2;
			case 3:
				return channel3;
			case 4:
				return channel4;
			case 5:
				return channel5;
			case 6:
				return channel6;
			case 7:
				return channel7;
		}
	}
	
	void setChannel(int index, float3 newColor) {
		switch(index) {
			case 0:
				channel0 = newColor;
			case 1:
				channel1 = newColor;
			case 2:
				channel2 = newColor;
			case 3:
				channel3 = newColor;
			case 4:
				channel4 = newColor;
			case 5:
				channel5 = newColor;
			case 6:
				channel6 = newColor;
			case 7:
				channel7 = newColor;
		}
	}
	
	void changeChannel(int index, float3 offsetColor) {
		float3 oldColor = channel(index);
		setChannel(index, oldColor + offsetColor);
	}
	
	uint channels() {
		return 8;
	}
};

struct Channel {
	uint index;
	float3 color;
	float strength;
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
	
	float3 sin(float3 value) {
		return float3(metal::precise::sin(value.x), metal::precise::sin(value.y), metal::precise::sin(value.z));
	}
	
	void init(float3 position, RayMarchingSettings settings) {
		rgbEmitted = float3(0, 0, 0);
		//rgbAbsorption = float3(rand(position.x * 2.1, position.y * 2.31, position.z * 2.1), rand(position.x * 2.1, position.y * 3.1, position.z * 5.23), rand(position.x * 2.21, position.y * 1.24, position.z * 2.09));
		//rgbAbsorption = float3(0.5, 0.5, 0.5);
		if (rand(x * 12059812, y * 98213, z * 5091283) > 0.5) {
			diffuse = 0.1;
		} else {
			diffuse = 0.9;
		}
		float distanceFromCenter = distance(position, float3(0, 0, 0));
		
		rgbAbsorption = clamp(settings.colorBase + settings.colorVariation * sin(distanceFromCenter * settings.colorFrequency + settings.colorOffset), float3(0), float3(1));
		//rgbAbsorption = float3(0.4 + 0.4 * metal::precise::sin(distanceFromCenter * 100), 0.4 + 0.4 * metal::precise::cos(distanceFromCenter * 40), 0.4 + 0.4 * metal::precise::cos(distanceFromCenter * 30));//(10 + 5 * sin(distanceFromCenter * 30));
	}
};

//MARK: Ray
struct Ray {
	float4 position;
	float4 deriction;
	
	float3 colorAbsorption;
	Colors colors;
	
	void normalize() {
		deriction = metal::normalize(deriction);
	};
	
	void march(float distance) {
		position += deriction * distance;
	}
};

//MARK: SkyBoxLight
struct SkyBoxLight {
	float3 color;
	float strength;
	float size;
	float3 position;
	uint channel;
	uint id;
	
	float3 getColor(Ray ray) {
		if (size < dot(normalize(ray.deriction.xyz), normalize(position))) {
			return color * strength;
		}
		return float3(0);
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
		for (int c = 0; 8 > c; c++) {
			ray.colors.setChannel(c, float3(0, 0, 0));
		}
		return ray;
	}
};

//MARK: ShaderInfo
struct ShaderInfo {
	RayMarchingSettings rayMarchingSettings;
	Camera camera;
	uint4 realIndex;
	uint3 randomSeed;
	uint voxelsLength;
	uint isJulia;
	uint lightsLength;
	uint exposure;
	uint channelsLength;
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
	bool isDefault() {
		return (index == 0);
	}
};

struct Voxel {
	float opacity;
	bool isEnd;
	float3 position;
	uint layer;
	
	float width() {
		return pow(0.5, float(layer)) * 1;
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
};
