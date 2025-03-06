shader_type spatial;

render_mode depth_draw_always, cull_back,depth_prepass_alpha;

varying uint camera_visible_layers;
void vertex() {
	
}

void fragment() {

	// Called for every pixel the material is visible on.
	if ( (int(CAMERA_VISIBLE_LAYERS)& (1)) ==0)
	{
		// first two components of normal are in r,g
		// depth in range 0-0.5 is packed into z, along with
		// the sign of the normal Z, so we can reconstruct
		// n.b. assuming the normal is a unit vector
		// could normalise the normal here, but I don't bother 
		// because I'm assuming the mesh is well formed
		EMISSION.rg = NORMAL.xy;
		float packedDepth=(FRAGCOORD.z*0.5);
		if(NORMAL.z>0.){
			packedDepth+=0.5;
		}
		EMISSION.b=packedDepth;
	}else{
		// show shaded colour
		ALBEDO=COLOR.rgb;		
	}
//	ALBEDO=COLOR.rgb;
	camera_visible_layers=CAMERA_VISIBLE_LAYERS;
}

void light() 
{
	if((int(camera_visible_layers)&(1))==0){
		DIFFUSE_LIGHT=vec3(0,0,0);
		SPECULAR_LIGHT=vec3(0,0,0);		
	}
}
