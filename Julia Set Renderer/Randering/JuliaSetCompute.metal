//
//  JuliaSetCompute.metal
//  Julia Set Renderer
//
//  Created by Hezekiah Dombach on 8/23/20.
//  Copyright © 2020 Hezekiah Dombach. All rights reserved.
//

#include <metal_stdlib>
#include "raytracing.metal"
using namespace metal;

struct Complex {
	float real;
	float imaginary;

	Complex operator+(const Complex rhs) const {
		return { real + rhs.real, imaginary + rhs.imaginary };
	}

	Complex operator-(const Complex rhs) const {
		return { real - rhs.real, imaginary - rhs.imaginary };
	}

	Complex operator*(const Complex rhs) const {
		return  {real * rhs.real - imaginary * rhs.imaginary, imaginary * rhs.real + real * rhs.imaginary};
	}

	Complex squared() {
		return *this * *this;
	}

	float magnitude() {
		return sqrt(real * real + imaginary * imaginary);
	}
};

struct JuliaSet {
	float realSlope;
	float realIntercept;
	float imaginarySlope;
	float imaginaryIntercept;
	int iterations;

	void updateVoxel(VoxelAddress voxelAddress, device Voxel *voxels, int voxelsLength) {
		VoxelContainer container;
		device Voxel *currentVoxel = container.getVoxel(voxelAddress, voxels, voxelsLength);
		//if (currentVoxel->isEnd) {
			currentVoxel->opacity = opacityAtPoint(currentVoxel->position);
		//}
	}

	/*void updateVoxel(QueueItem item, float relativeIndex, device Voxel *voxels, Camera camera) {
		int realIndex = int(relativeIndex + item.voxelIndex);
		float3 position = getPosition(item, relativeIndex);
		float voxelSize = getVoxelSize(position, getCurrentLayer(relativeIndex), camera);
		if (item.finalSize > voxelSize) {
			voxels[realIndex].isEnd = true;
		}
		if (voxels[realIndex].isEnd) {
			voxels[realIndex].opacity = opacityAtPoint(position);
		}
	}*/
    
	void updateAddress(device Voxel *voxels, int index, int voxelsLength) {
        VoxelContainer container;
        voxels[index]._0.index = container.firstIndex(voxels[index]._0, voxels, voxelsLength);
        voxels[index]._1.index = container.firstIndex(voxels[index]._1, voxels, voxelsLength);
        voxels[index]._2.index = container.firstIndex(voxels[index]._2, voxels, voxelsLength);
        voxels[index]._3.index = container.firstIndex(voxels[index]._3, voxels, voxelsLength);
        voxels[index]._4.index = container.firstIndex(voxels[index]._4, voxels, voxelsLength);
        voxels[index]._5.index = container.firstIndex(voxels[index]._5, voxels, voxelsLength);
        voxels[index]._6.index = container.firstIndex(voxels[index]._6, voxels, voxelsLength);
        voxels[index]._7.index = container.firstIndex(voxels[index]._7, voxels, voxelsLength);
        voxels[index]._p.index = container.firstIndex(voxels[index]._p, voxels, voxelsLength);
	}

	/*void shrinkVoxel(device VoxelAddress *voxelAddress, device Voxel *voxels, int voxelsLength) {
		VoxelContainer container;
		device Voxel *starter = container.getVoxel(voxelAddress, voxels, voxelsLength);
		device VoxelAddress *currentAddress = &starter->_p;
		uint childIndex = voxelAddress->index;
		while (currentAddress->id != 0) {
			device Voxel *voxel = container.getVoxel(currentAddress, voxels, voxelsLength);
			Voxel child0 = *container.getVoxel(&voxel->_0, voxels, voxelsLength);
			if (childIndex != voxel->_7.index) {
				//return;
			}

			for (int c = 0; 8 > c; c++) {
				device VoxelAddress currentChildAddress = container.getVoxelChild(voxel, c);
				if (currentChildAddress->id == 0) {
					return;
				}
				Voxel currentChild = *container.getVoxel(currentChildAddress, voxels, voxelsLength);
				if (!currentChild.isEnd || currentChild.opacity != child0.opacity || currentChild.opacity == -1) {
					return;
				}
			}
			for (int c = 0; 8 > c; c++) {

				container.getVoxel(container.getVoxelChild(voxel, c), voxels, voxelsLength)->isDeleted = true;
			}
			voxel->opacity = child0.opacity;
			voxel->isEnd = true;
			childIndex = currentAddress->id;
			currentAddress = &voxel->_p;
		}

	}*/

private: Complex generatePoint(float value) {
		return {value * realSlope + realIntercept, value * imaginarySlope + imaginaryIntercept};
	}

private: bool testPoint(Complex point, Complex c) {
		Complex x = point;

		for (int i = 0; iterations > i; i++) {
			x = x.squared() + c;
			if (x.magnitude() > 2) {
				return false;
			}
		}

		return true;
	}

private: float opacityAtPoint(float3 point) {

	//return real - round(real);
        /*if (0.5 > distance(point, float3(0.5, 0.5, 0.5))) {
            return 1;
        } else{
            return 0;
        }*/
    float width = 3;
		return testPoint({point.x * width - width / 2, point.y * width - width / 2}, generatePoint(point.z * width - width / 2));
	}

	///turns child index (0-7) into child offset
private: float3 getOffset(float index) {
		float z = floor(index / 4);
		float y = floor(fmod(index, 4) / 2);
		float x = fmod(index, 2);
		return float3(x, y, z);
	}

private: float getVoxelSize(float3 position, float voxelLayer, Camera camera) {
		float width = pow(0.5, voxelLayer);

		float voxelSize = (camera.depth * width / distance(camera.position, float4(position, 0))) / camera.zoom;
		if (0 > dot(float4(0, 0, 1, 0) * camera.rotateMatrix, float4(position, 0) - camera.position)) {
			voxelSize = voxelSize / 4;
		}

		return voxelSize;
	}

};

kernel void julia_set_compute_shader(device VoxelAddress *queue [[buffer(0)]],
									 constant JuliaSet &jSetContainer [[buffer(1)]],
									 device Voxel *voxels [[buffer(2)]],
									 constant Camera &camera [[buffer(3)]],
									 constant int &voxelsLength [[buffer(4)]],
									 uint index [[ thread_position_in_grid ]]) {
	JuliaSet jSet = jSetContainer;

	jSet.updateVoxel(queue[index], voxels, voxelsLength);
}

kernel void julia_set_shrink_Shader(device VoxelAddress *queue [[buffer(0)]],
									constant JuliaSet &jSetContainer [[buffer(1)]],
									device Voxel *voxels [[buffer(2)]],
									constant int &voxelsLength [[buffer(4)]],
									uint index [[ thread_position_in_grid]]) {
	JuliaSet jSet = jSetContainer;

	jSet.updateAddress(voxels, index, voxelsLength);
}


//MARK: Tests

struct TestItem {
	Complex v1;
	Complex v2;
	Complex answer;
};

kernel void add_test(device TestItem *questions [[buffer(0)]],
					 uint index [[ thread_position_in_grid ]]) {
	//if (index < questions.size()) {
		TestItem v = questions[index];
	questions[index].answer = v.v1.squared();
	//}
}

