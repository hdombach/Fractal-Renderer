//
//  Shaders.metal
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 7/2/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

#include "Rendering.metal"
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
									  constant ShaderInfo &info [[buffer(0)]],
									  constant Channel *channels [[buffer(3)]]) {
	float4 color = float4(0);
	for (uint c = 0; info.channelsLength > c; c++) {
		float3 channelColor;
		Channel channel = channels[c];
		channelColor.r = texture.sample(sampler2d, rd.texCoord, 0 + c * 3).x * channel.color.r;
		channelColor.g = texture.sample(sampler2d, rd.texCoord, 1 + c * 3).x * channel.color.g;
		channelColor.b = texture.sample(sampler2d, rd.texCoord, 2 + c * 3).x * channel.color.b;
		
		channelColor *= channel.strength;
		
		color.r += channelColor.r;
		color.g += channelColor.g;
		color.b += channelColor.b;
	}
	color.a = 1;

	return color / info.exposure;
}



fragment float4 depth_fragment_shader(RasterizerData rd [[ stage_in ]],
									  constant ShaderInfo &shaderInfo [[buffer(0)]],
									  device Voxel *voxels [[buffer(1)]],
									  constant SkyBoxLight *lights [[buffer(2)]]) {
	RayTracer yeet;
	ShaderInfo info = shaderInfo;
	return float4(yeet.depthMap(rd.texCoord, info.camera, voxels, info.voxelsLength, info.isJulia, lights, info.lightsLength, info.rayMarchingSettings, info));
	//return float4(yeet.rayCast(rd.texCoord, myCamera, 4, voxels));
}

fragment float4 sample_fragment_shader(RasterizerData rd [[ stage_in ]],
									   constant ShaderInfo &shaderInfo [[buffer(0)]],
									   device Voxel *voxels [[buffer(1)]],
									   constant SkyBoxLight *lights [[buffer(2)]]) {
	//MathContainer maths;
	RayTracer rayShooter;

	ShaderInfo info = shaderInfo;
	info.rayMarchingSettings.bundleSize = 0;

	return float4(rayShooter.rayCast(rd.texCoord, 2, voxels, false, lights, float2(0), info).channel(0), 1);
}

kernel void ray_compute_shader(texture2d_array<float, access::read> readTexture [[texture(0)]],
							   texture2d_array<float, access::write> writeTexture [[texture(1)]],
							   uint index [[ thread_position_in_grid ]],
							   constant ShaderInfo &shaderInfo [[buffer(0)]],
							   device Voxel *voxels [[buffer(1)]],
							   constant SkyBoxLight *lights [[buffer(2)]]) {
	RayTracer rayShooter;
	MathContainer math;
	
	ShaderInfo info = shaderInfo;

	float anIndex = info.realIndex.x + index;

	if (anIndex > info.realIndex.w) {
		return;
	}
	anIndex = fmod(anIndex, info.realIndex.y * info.realIndex.z);

	float2 pos;
	pos.x = floor(fmod(anIndex, float(info.realIndex.y * info.realIndex.z)) / float(info.realIndex.z));
	pos.y = fmod(anIndex, float(info.realIndex.z));
	uint2 textureIndex = uint2(pos.x, pos.y);

    uint3 seed = info.randomSeed;
    seed.x += index * 402;
    seed.y += index * 503;
    seed.z += index * 305;
    
    
	float2 randomOffset;
	randomOffset.x = math.rand(info.randomSeed.x, pos.x * 983414, anIndex * 33429);
	randomOffset.y = math.rand(info.randomSeed.y, pos.y * 754239, anIndex * 46523);

	pos.x = (pos.x + 0) / readTexture.get_width();
	pos.y = (pos.y + 0) / readTexture.get_height();
	/*int a;
	for( a = 0; a < 10; a++ ){
		color += rayShooter.rayCast(pos, myCamera, 10, voxels, randomSeed);
	}
	color = color / 10;*/
	Colors colors = rayShooter.rayCast(pos, 4, voxels, false, lights, float2(readTexture.get_width(), readTexture.get_height()), info);
	//float4 color = float4(pos.x + 0.00001, pos.y + 0.0000001, 0.5, 1) * 100;
	for (uint c = 0; info.channelsLength > c; c++) {
		float3 oldColor;
		oldColor.x = readTexture.read(textureIndex, 3 * c).x;
		oldColor.y = readTexture.read(textureIndex, 3 * c + 1).x;
		oldColor.z = readTexture.read(textureIndex, 3 * c + 2).x;
		
		float3 color = colors.channel(c);
		writeTexture.write(float4(oldColor.x + color.x, 0, 0, 0), textureIndex, 3 * c);
		writeTexture.write(float4(oldColor.y + color.y, 0, 0, 0), textureIndex, 3 * c + 1);
		writeTexture.write(float4(oldColor.z + color.z, 0, 0, 0), textureIndex, 3 * c + 2);
	}
	//writeTexture.write(color + oldColor, textureIndex);
	//writeTexture.write(float4(randomOffset.x, randomOffset.y, 0, 1), textureIndex);
	return;
}

kernel void reset_compute_shader(texture2d_array<float, access::write> writeTexture [[texture(0)]],
											uint2 index [[ thread_position_in_grid]],
											constant ShaderInfo &info [[buffer(0)]]) {
	for (int c = 0; c < info.channelsLength * 3; c++) {
		writeTexture.write(float4(0, 0, 0, 0), index, c);
	}
	return;
}
