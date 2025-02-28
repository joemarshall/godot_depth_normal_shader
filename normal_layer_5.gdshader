shader_type spatial;
varying uint camera_visible_layers;
void vertex() {
	
}

void fragment() {
	int pixelX=int(FRAGCOORD.x);//*VIEWPORT_SIZE.x);
	// Called for every pixel the material is visible on.
	if ( (int(CAMERA_VISIBLE_LAYERS)& (1)) ==0)
	{
		// output normal
		if( (pixelX&1)==1 )
		{
			ALBEDO.r=FRAGCOORD.z;
			ALBEDO.g=0.;
			ALBEDO.b=0.;
		}else
		{
			ALBEDO=NORMAL;
		}
	}else{
		// show shaded colour
		ALBEDO=COLOR.rgb;
	}
	camera_visible_layers=CAMERA_VISIBLE_LAYERS;
}

void light() 
{
	if((int(camera_visible_layers)&(1))==0){
		DIFFUSE_LIGHT=ALBEDO;
		SPECULAR_LIGHT=vec3(0,0,0);		
	}
}
