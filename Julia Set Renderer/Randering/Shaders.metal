//
//  Shaders.metal
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 7/2/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

#include <metal_stdlib>
#include "raytracing.metal"
using namespace metal;

struct VertexIn {
	float3 position [[ attribute(0) ]];
	float4 color [[ attribute(1) ]];
	float2 texCoord [[ attribute(2) ]];
};

struct RasterizerData {
	float4 position [[ position ]];
	float4 color;
	float2 texCoord;
};
vertex RasterizerData basic_vertex_shader(const VertexIn vIn [[ stage_in ]],
										  constant float &viewRatio [[ buffer(1) ]],
										  constant float &imageRatio [[ buffer(2) ]]) {
	RasterizerData rd;
	if (imageRatio < viewRatio) {
		rd.position = float4(vIn.position.x * imageRatio / viewRatio, vIn.position.y, vIn.position.z, 1);
	} else {
		rd.position = float4(vIn.position.x, vIn.position.y / imageRatio * viewRatio, vIn.position.z, 1);
	}
	//rd.position = float4(vIn.position.x / 2, vIn.position.y / 2, 0, 1);
	rd.color = vIn.color;
	rd.texCoord = vIn.texCoord;

	return rd;
}

fragment float4 basic_fragment_shader(RasterizerData rd [[ stage_in ]],
												 sampler sampler2d [[ sampler(0) ]],
												 texture2d_array<float> texture [[ texture(0) ]],
												 constant int &exposure [[buffer(2)]]) {
	float4 color;// = texture.sample(sampler2d, rd.texCoord) / exposure / 100;
	color.r = texture.sample(sampler2d, rd.texCoord, 0).x;
	color.g = texture.sample(sampler2d, rd.texCoord, 1).x;
	color.b = texture.sample(sampler2d, rd.texCoord, 2).x;
	color.a = 1;

	return color / exposure;
}



fragment float4 depth_fragment_shader(RasterizerData rd [[ stage_in ]],
								   constant Camera &camera [[buffer(0)]],
								   device Voxel *voxels [[buffer(1)]],
								   constant int &voxelsLength [[buffer(4)]],
                                   constant bool &isJulia [[buffer(5)]]) {
	RayTracer yeet;
	Camera myCamera = camera;
	return float4(yeet.depthMap(rd.texCoord, myCamera, voxels, voxelsLength, isJulia));
	//return float4(yeet.rayCast(rd.texCoord, myCamera, 4, voxels));
}

fragment float4 sample_fragment_shader(RasterizerData rd [[ stage_in ]],
									  constant Camera &camera [[buffer(0)]],
									  device Voxel *voxels [[buffer(1)]],
									  constant int &voxelsLength [[buffer(4)]],
                                      constant bool &isJulia [[buffer(5)]]) {
	//MathContainer maths;
	RayTracer rayShooter;

	Camera myCamera = camera;

	return float4(rayShooter.rayCast(rd.texCoord, myCamera, 2, voxels, uint3(0, 0, 0), false, voxelsLength, isJulia));
}

kernel void ray_compute_shader(texture2d_array<float, access::read> readTexture [[texture(0)]],
										 texture2d_array<float, access::write> writeTexture [[texture(1)]],
										 uint index [[ thread_position_in_grid ]],
										 constant Camera &camera [[buffer(0)]],
										 device Voxel *voxels [[buffer(1)]],
										 constant uint4 &realIndex [[buffer(2)]],
										 constant uint3 &randomSeed [[buffer(3)]],
										 constant int &voxelsLength [[buffer(4)]],
                                         constant int &isJulia [[buffer(5)]]) {
	MathContainer maths;
	RayTracer rayShooter;

	Camera myCamera = camera;

	float anIndex = realIndex.x + index;

	if (anIndex > realIndex.w) {
		return;
	}
	anIndex = fmod(anIndex, realIndex.y * realIndex.z);

	float2 pos;
	pos.x = floor(fmod(anIndex, float(realIndex.y * realIndex.z)) / float(realIndex.z));
	pos.y = fmod(anIndex, float(realIndex.z));
	uint2 textureIndex = uint2(pos.x, pos.y);

    uint3 seed = randomSeed;
    seed.x += index * 402;
    seed.y += index * 503;
    seed.z += index * 305;
    
    
	float2 randomOffset;
	randomOffset.x = maths.rand(randomSeed.x, pos.x * 983414, anIndex * 33429);
	randomOffset.y = maths.rand(randomSeed.y, pos.y * 754239, anIndex * 46523);

	pos.x = (pos.x + randomOffset.x) / readTexture.get_width();
	pos.y = (pos.y + randomOffset.y) / readTexture.get_height();


	float4 color = float4(0, 0, 0, 0);
	/*int a;
	for( a = 0; a < 10; a++ ){
		color += rayShooter.rayCast(pos, myCamera, 10, voxels, randomSeed);
	}
	color = color / 10;*/

	color = rayShooter.rayCast(pos, myCamera, 4, voxels, randomSeed, false, voxelsLength, isJulia);
	//float4 color = float4(pos.x + 0.00001, pos.y + 0.0000001, 0.5, 1) * 100;
	float4 oldColor;
	oldColor.x = readTexture.read(textureIndex, 0).x;
	oldColor.y = readTexture.read(textureIndex, 1).x;
	oldColor.z = readTexture.read(textureIndex, 2).x;

	writeTexture.write(float4(oldColor.x + color.x, 0, 0, 0), textureIndex, 0);
	writeTexture.write(float4(oldColor.y + color.y, 0, 0, 0), textureIndex, 1);
	writeTexture.write(float4(oldColor.z + color.z, 0, 0, 0), textureIndex, 2);
	//writeTexture.write(color + oldColor, textureIndex);
	//writeTexture.write(float4(randomOffset.x, randomOffset.y, 0, 1), textureIndex);
	return;
}

kernel void reset_compute_shader(texture2d_array<float, access::write> writeTexture [[texture(0)]],
											uint2 index [[ thread_position_in_grid]]) {
	writeTexture.write(float4(0, 0, 0, 0), index, 0);
	writeTexture.write(float4(0, 0, 0, 0), index, 1);
	writeTexture.write(float4(0, 0, 0, 0), index, 2);
	return;
}




/*kernel void blank_compute_shader(texture2d<float, access::read> readTexture [[texture(0)]],
								 texture2d<float, access::write> writeTexture [[texture(1)]],
								 uint2 index [[ thread_position_in_grid ]],
								 constant Camera &camera [[buffer(0)]],
								 constant VoxelContainer &containerIn [[buffer(1)]],
								 constant uint2 &realIndex [[ buffer(2) ]]) {

	uint2 iiindex = realIndex + index;
	//iiindex.x = realIndex.y;

	float c = 0;
	while (c < iiindex.x * iiindex.y) {
		c++;
		if (c > 10000) {
			break;
		}
	}
	float4 color = float4(float(iiindex.x) / 1920, float(iiindex.y) / 1080, 0, 1);

	writeTexture.write(color, iiindex);
	return;
}*/



/*kernel void basic_compute_shader(texture2d<float, access::read> readTexture [[texture(0)]],
								 texture2d<float, access::write> writeTexture [[texture(1)]],
								 uint2 index [[ thread_position_in_grid ]],
								 constant Camera &camera [[buffer(0)]],
								 constant Voxel *voxels [[buffer(1)]],
								 constant uint2 &offsetIndex [[ buffer(2)]]) {

	uint2 realIndex = index + offsetIndex;
	if (realIndex.x > readTexture.get_width() - 1 || realIndex.y > readTexture.get_height() - 1) {
		writeTexture.write(float4(0, 1, 0, 1), realIndex);
		return;
	}
	Camera myCamera = camera;
	RayTracer yaboii;

	float indexX = realIndex.x;
	float indexY = realIndex.y;
	indexX = indexX / myCamera.resolution.x * 2 - 1;
	indexY = indexY / myCamera.resolution.y * 2 - 1;

	float4 color = yaboii.depthMap(float2(indexX, indexY), myCamera, voxels);
	//float4 color = yaboii.rayCast(float2(indexX, indexY), myCamera, 1, voxels);

	writeTexture.write(color, realIndex);
	return;
}*/
