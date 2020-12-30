//
//  maths.metal
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 7/5/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

#include <metal_stdlib>
#include "RayMarching.metal"
using namespace metal;

struct RayTracer {
	struct VectorPair {
		float3 v1;
		float3 v2;
	};
	
	VectorPair orthogonalVectors(float3 n) {
		float3 axis;
		if (abs(n.x) < abs(n.y) && abs(n.x) < abs(n.z)) {
			axis = float3(1.0, 0.0, 0.0);
		} else if (abs(n.y) < abs(n.z)) {
			axis = float3(0.0, 1.0, 0.0);
		} else {
			axis = float3(0.0, 0.0, 1.0);
		}
		
		VectorPair result;
		result.v1 = normalize(cross(n, axis));
		result.v2 = normalize(cross(n, result.v1));
		
		return result;
	}
	
	float3 sampleUniformHemisphere(float3 n, int3 randomSeed) {
		MathContainer math;
		float3 p;
		int3 seed = randomSeed;
		do {
			p.z = math.rand(seed.x, seed.y, seed.z);
			p.x = math.rand(seed.y, seed.z, seed.x) * 2 - 1;
			p.y = math.rand(seed.z, seed.x, seed.y) * 2 - 1;
			seed += int3(512, 723, 152);
		} while (p.x * p.x + p.y * p.y + p.z * p.z > 1);
		
		p = normalize(p);
		
		VectorPair orthogonals = orthogonalVectors(n);
		
		p = p.x * orthogonals.v1 + p.y * orthogonals.v2 + p.z * n;
		return p;
	}
	
	float3 sampleUniformHemisphere2(float3 n, int3 randomSeed) {
		MathContainer math;
		float2 p;
		int3 seed = randomSeed;
		do {
			p.x = math.rand(seed.x, seed.y, seed.z) * 2 - 1;
			p.y = math.rand(seed.y, seed.z, seed.x) * 2 - 1;
			seed += int3(512, 723, 152);
		} while (p.x * p.x + p.y * p.y > 1);
		
		return projectToHemisphere(p, n);
	}
	
	float3 mapToHemisphere(float2 p, float3 normal) {
		float d = length(p);
		float shift = 1 - (1 - d) * (1 - d);
		p = p / d * shift;
		float z = sqrt(1 - shift * shift);
		
		VectorPair orthogonals = orthogonalVectors(normal);
		
		return orthogonals.v1 * p.x + orthogonals.v2 * p.y + normal * z;
	}
	
	float3 projectToHemisphere(float2 p, float3 normal) {
		float d = length(p);
		float z = sqrt(1 - d * d);
		
		VectorPair orthogonals = orthogonalVectors(normal);
		
		return orthogonals.v1 * p.x + orthogonals.v2 * p.y + normal * z;
	}
	
	float3 correctNormal(float3 normal, float3 vector) {
		if (dot(normal, vector) < 0) {
			return normal;
		} else {
			return normal * -1;
		}
	}

	float errorDifference = 0.00001;

	struct SingleResult {
		Ray ray;
		float distance;
		CollisionInfo collision;
        int steps;
	};

	//MARK: Skybox
	Colors getSkyBox(Ray ray, constant SkyBoxLight *lights, int lightsLength) {
		Colors color;
		for (uint c = 0; 8 > c; c++) {
			
			color.setChannel(c, float3(0, 0, 0));
		}
		
		for (int c = 0; lightsLength > c; c++) {
			SkyBoxLight light = lights[c];
			
			color.setChannel(light.channel, light.getColor(ray));
		}
		
		return color;
	}

	Ray reflect(Ray ray, float3 surfaceNormal, Material surfaceMaterial, uint3 _seed) {
		MathContainer math;

		Ray returnRay = ray;
		for (int c = 0; 8 > c; c++) {
			
			returnRay.colors.changeChannel(c, ray.colorAbsorption * surfaceMaterial.rgbEmitted);
		}
		returnRay.colorAbsorption *= surfaceMaterial.rgbAbsorption;

		int3 seed = int3(0, 0, 0);
		if (false) { //set false for more random bounces
			seed.x = round(returnRay.position.x * 1030);
			seed.y = round(returnRay.position.y * 1241);
			seed.z = round(returnRay.position.z * 1518);
		} else {

			seed.x = (returnRay.position.x * 1033594);
			seed.y = (returnRay.position.y * 1243421);
			seed.z = (returnRay.position.z * 1516648);
		}
		seed *= int3(_seed);
		
		returnRay.deriction.xyz = sampleUniformHemisphere(surfaceNormal, seed);
		return returnRay;
	}
	
	float rideRay(Ray primaryRay, Ray secondaryRay, RayMarchingSettings settings) {
		RayMarching rayMarcher;
		//float tempDot = dot(normalize(primaryRay.deriction.xyz), normalize(secondaryRay.deriction.xyz));
		//float k = sqrt(1 - tempDot * tempDot) / tempDot;
		float k = length(normalize(secondaryRay.deriction.xyz) - normalize(primaryRay.deriction.xyz));
		float rLast = 0;
		float r = 0;
		float t = 0;
		
		while (100000 > t) {
			rLast = r;
			r = rayMarcher.DE(primaryRay.position.xyz + t * normalize(primaryRay.deriction.xyz), settings).d;
			float thing = 0.5 * r * r / rLast;
			float tSphereIntersection = t - thing;
			float rSphereIntersection = sqrt(r * r - thing);
			if (rSphereIntersection < k * tSphereIntersection || t / settings.quality > r) {
				return t;
			}
			t += r;
		}
		return t;
	}
    
    SingleResult mandelBulb(Ray rayIn, uint3 seed, float fog, RayMarchingSettings settings) {
		RayMarching rayMarcher;
		
        Ray ray = rayIn;
		
        int steps = 0;
        DistanceInfo d = {0, na};
		RayMarchInfo bulbResut;
        while (100000 > d.distance) {
            bulbResut = rayMarcher.DE(ray.position.xyz, settings);
            float step = bulbResut.d;
            ray.march(step);
            /*float3 offset;
            offset.x = maths.rand(seed.x * uint(ray.position.y * 451245), seed.y, seed.z);
            offset.y = maths.rand(seed.y * uint(ray.position.x * 5019823), seed.z, seed.x);
            offset.z = maths.rand(seed.z * uint(ray.position.z * 502814), seed.x, seed.y);
            ray.position += float4(fog * offset.x * step, fog * offset.y * step, fog * offset.z * step, 0);*/
            d.distance += step;
            steps ++;
            if (1 * d.distance / settings.quality > step || 500 < steps) {
				if (steps > 500 && false) {
					ray.march(100000);
					d.distance += 100000;
				}
                break;
            }
        }
		ray.march(errorDifference * -1);
        //ray.march(-1 * errorDifference);
        SingleResult result;
        result.distance = d.distance;
        result.steps = steps;
        result.collision.surfaceNormal = rayMarcher.DEnormal(ray.position.xyz, settings);
		result.collision.surfaceNormal = correctNormal(result.collision.surfaceNormal, ray.deriction.xyz);
        
        Material material;
        material.init(float3(bulbResut.orbitLife, 0, 0) / 3, settings);
        
        result.collision.surfaceMaterial = material;
        result.collision.position = ray.position.xyz;
        //result.collision.orbitPosition = bulbResut.orbitPosition;
        result.ray = ray;
        return result;
    }

	SingleResult shootRay(Ray rayIn, device Voxel *voxels, bool showVoxels, int voxelsLength, RayMarchingSettings settings) {
		MathContainer math;
		RayMarching rayMarcher;
		
		Ray ray = rayIn;

		device Voxel *rootVoxel = &voxels[1];

		DistanceInfo distance = {0, na};
        int steps = 0;
		while (10000 > distance.distance) {
			DistanceInfo step = {0, na};
			if (rayMarcher.cubeContainsRay(ray, rootVoxel)) {
				device Voxel *intersectedVoxel = rayMarcher.getVoxel(ray, voxels, voxelsLength);
				if (intersectedVoxel->opacity > 0.5) {
					ray.march(errorDifference * -2);
					break;
				}
				if (showVoxels) {
					ray.colorAbsorption *= float3(0.9);
				}
				step = math.distanceToVoxel(ray, intersectedVoxel);
			} else {
				step = math.distanceToCube(ray, rootVoxel);
			}
			step.distance += errorDifference;
			ray.march(step.distance);
			distance.distance += step.distance;
			distance.collisionAxis = step.collisionAxis;
            steps++;
		}

		Material material;
		material.init(float3(ray.position.x, ray.position.y, ray.position.z), settings);

		CollisionInfo collide;
		collide.position = float3(ray.position.x, ray.position.y, ray.position.z);
		collide.surfaceMaterial = material;
		collide.surfaceNormal = rayMarcher.getNormal(distance.collisionAxis);
		collide.surfaceNormal = correctNormal(collide.surfaceNormal, ray.deriction.xyz);


		SingleResult result;
		result.distance = distance.distance;
		result.ray = ray;
		result.collision = collide;
        result.steps = steps * 10;

		return result;
	}
    
    void bundle(texture2d_array<float, access::read> readTexture [[texture(0)]],
                texture2d_array<float, access::write> writeTexture [[texture(1)]],
                uint index [[ thread_position_in_grid ]],
                constant uint &groupSize [[buffer(5)]]) {
        
    }

	Colors rayCast(float2 pos, int bounceLimit, device Voxel *voxels, bool showVoxels, constant SkyBoxLight *lights, float2 textureSize, ShaderInfo info) {
		MathContainer math;
		
		float skip = 0;
		if (info.isJulia == 1 && info.rayMarchingSettings.bundleSize > 1) {
			Ray primary = info.camera.spawnRay(pos + float2(0.5 / textureSize.x, 0.5 / textureSize.y));
			Ray secondary = info.camera.spawnRay(pos);
			skip = rideRay(primary, secondary, info.rayMarchingSettings);
		}
		
		uint3 seed2 = info.randomSeed;
		
		//for (int c = 0; info.rayMarchingSettings.bundleSize > c; c++) {
			seed2 += uint3(5129,312,5021);
			float2 randomOffset;
			if (info.rayMarchingSettings.bundleSize > 0) {
				randomOffset.x = math.rand(seed2.x, pos.x * 983414, seed2.z * 33429);
				randomOffset.y = math.rand(seed2.y, pos.y * 754239, seed2.z * 46523);
			} else {
				randomOffset = float2(0);
			}
			
			float2 newPos = pos + randomOffset / textureSize;
			Ray ray = info.camera.spawnRay(newPos);
			ray.march(skip);
			
			int bounces = 0;
			while (bounces < bounceLimit) {
				SingleResult result;
				if (info.isJulia == 0) {
					result = shootRay(ray, voxels, showVoxels, info.voxelsLength, info.rayMarchingSettings);
				} else {
					result = mandelBulb(ray, info.randomSeed, 0.01, info.rayMarchingSettings);
				}
				//return float4(result.collision.surfaceNormal, 1);
				ray = result.ray;
				if (result.distance >= 100000) {
					if (bounces > 0) {
						Colors colors = getSkyBox(ray, lights, info.lightsLength);
						for (int c = 0; 8 > c; c++) {
							float3 oldColor = colors.channel(c);
							ray.colors.setChannel(c, oldColor * ray.colorAbsorption);
							//ray.colors.changeChannel(c, ray.colorAbsorption * colors.channel(c));
						}
					}
					break;
				}
				ray.colorAbsorption = ray.colorAbsorption * (1 - result.distance / 10);
				
				ray = reflect(ray, result.collision.surfaceNormal, result.collision.surfaceMaterial, info.randomSeed);
				bounces ++;
			}
		//}
		//return getSkyBox(ray, lights, info.lightsLength);
		return ray.colors;
	}

	float4 depthMap(float2 pos, Camera camera, device Voxel *voxels, int voxelsLength, int isJulia, constant SkyBoxLight *lights, int lightsLength, RayMarchingSettings settings, ShaderInfo info) {
		Ray ray = camera.spawnRay(pos);
		float3 originalDirection = normalize(ray.deriction.xyz);
		
        SingleResult result;
        if (isJulia == 0) {
            result = shootRay(ray, voxels, false, voxelsLength, settings);
        } else {
            result = mandelBulb(ray, uint3(0, 0, 0), 0, settings);
            if (result.distance < 10000) {
                ray.march(result.distance);
                //return float4(bulb.normal(ray.position.xyz), 0);
            }
        }
		
		//return float4(result.collision.surfaceNormal, 1);

		//float4 color = float4(log(result.distance)) + 0.2;
        float4 color = float4(1, 1, 1, 1) * float4(result.collision.surfaceMaterial.rgbAbsorption, 0);
        color *= pow(0.995, float(result.steps));
		color *= abs(dot(normalize(originalDirection), normalize(result.collision.surfaceNormal)));
		if (result.distance > 100) {
			float3 tempColor = float3(0);
			Colors colors = getSkyBox(ray, lights, lightsLength);
			for (uint c = 0; c < info.channelsLength; c++) {
				tempColor += colors.channel(c);
			}
			color = float4(tempColor, 1);
			return color;
		}
		//color = 1 - (color - 0.2) / color;
		return color;
	}
};
