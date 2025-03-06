#[compute]
#version 450
#extension GL_KHR_shader_subgroup_arithmetic:enable
#extension GL_EXT_shader_atomic_float:enable
 
layout (binding=0) uniform sampler2D normalAndDepth;
layout (binding = 1, std430) restrict writeonly buffer OutputBlock { float finalResult[]; } resultBuf;

layout(local_size_x = 32, local_size_y = 32, local_size_z = 1) in;

void main()
{
// zero the output buffer first
	if (subgroupElect()) {
	resultBuf.finalResult[0]=0.0;
	resultBuf.finalResult[1]=0.0;
	}
	memoryBarrier();
	barrier();
	vec2 samplePos = gl_GlobalInvocationID.xy;
	samplePos/= vec2(textureSize(normalAndDepth,0));
	vec4 pixelData=texture(normalAndDepth,samplePos);
		
	float thisDepth = pixelData.b;
	vec3 normal;
	normal.rg = pixelData.rg;
	normal.z = sqrt(1 - normal.r*normal.r + normal.g*normal.g);
	if(thisDepth>0.5){
		thisDepth=(thisDepth-0.5)*2.;
	}else{
		thisDepth=thisDepth*2.;
		normal.z=-normal.z;
	}
	float subgroupDepth = subgroupAdd(normal.z);
	float subgroupCount=subgroupAdd(1.0);
	// write mean value to output value after subgroup add operation
	if (subgroupElect()) {
		// add the 
		atomicAdd(resultBuf.finalResult[0],subgroupDepth);
		atomicAdd(resultBuf.finalResult[1],subgroupCount);
	}
	
}

