extends Node3D

@export var viewportTexture: Texture2D 

var out_uniform
var in_uniform
var shader_file := preload("res://compute_using_texture.glsl")
var shader_id
var pipeline
var compute_list
var uniform_set
var buffer_rid

func run_shader(rd:RenderingDevice, pl:RID, us:RID) -> void:
	if not buffer_rid:
		return
	var list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(list, pl)
	rd.compute_list_bind_uniform_set(list, us, 0)	
	rd.compute_list_dispatch(list, 4, 4, 1)
	rd.compute_list_end()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass	
	
var ignoreCount:=0

func make_uniform_set(rd):
	# make binding for input texture
	if not viewportTexture.get_rid().is_valid():
		print("No RID for viewport texture")
		return
	var tex_rid :RID
	tex_rid= RenderingServer.texture_get_rd_texture(viewportTexture.get_rid())
	if not rd.texture_is_valid(tex_rid):
		print("Invalid texture RID",tex_rid)
		return
	var sampler_state := RDSamplerState.new()
	var sampler = rd.sampler_create(sampler_state)
	in_uniform = RDUniform.new()
	in_uniform.binding=0
	in_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
	in_uniform.add_id(sampler)
	in_uniform.add_id(tex_rid)
	# make buffer for output - 4 bytes long because it stores a single float
	# make binding for output buffer (2 floats right now!)
	var output := PackedFloat32Array([7,7])
	var output_bytes := output.to_byte_array()
	
	buffer_rid = rd.storage_buffer_create(output_bytes.size(),output_bytes)
	out_uniform = RDUniform.new()
	out_uniform.binding = 1
	out_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	out_uniform.add_id(buffer_rid)
	var uniforms := [ in_uniform, out_uniform ]
	uniform_set = rd.uniform_set_create(uniforms, shader_id, 0)

	
func try_init_texture(rd):
	ignoreCount += 1
	if ignoreCount<20:
		return
	if not pipeline:
		print("Making pipeline")
		# build the shader
		var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
		shader_id= rd.shader_create_from_spirv(shader_spirv)
		if not shader_id.is_valid():
			print("Invalid Shader")
			return
		# uniforms - 
		make_uniform_set(rd)
		# make pipeline
		pipeline = rd.compute_pipeline_create(shader_id)
		print("Made pipeline")
		
		
	
var prevInternalTexture:int
var lastOut:float
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var rd := RenderingServer.get_rendering_device()
	if not pipeline:
		try_init_texture(rd)
		var rid = RenderingServer.texture_get_rd_texture(viewportTexture.get_rid())
		var internalTexture=rd.get_driver_resource(RenderingDevice.DRIVER_RESOURCE_TEXTURE,rid,0)
		prevInternalTexture= internalTexture
		return
	var rid = RenderingServer.texture_get_rd_texture(viewportTexture.get_rid())
	var internalTexture=rd.get_driver_resource(RenderingDevice.DRIVER_RESOURCE_TEXTURE,rid,0)
	if internalTexture!=prevInternalTexture:
		print(rid,"!",prevInternalTexture)
	if not rd.uniform_set_is_valid(uniform_set):
		print("Remaking set")
		rd.free_rid(uniform_set)
		make_uniform_set(rd)
		prevInternalTexture= internalTexture
		return
	# call compute shader on rendering device
	var fn = run_shader.bind(RenderingServer.get_rendering_device(),pipeline,uniform_set)
	RenderingServer.call_on_render_thread(fn)


	if not buffer_rid:
		return#
	var output_bytes := rd.buffer_get_data(buffer_rid,0,8)
	var output_floats:= output_bytes.to_float32_array()	
	var mean = output_floats[0]/output_floats[1]
	if abs(lastOut-mean)>0.001:
		lastOut=mean
		print(lastOut)
#		print("WOOO!",output_floats[0],",",output_floats[1],",",output_floats[0]/output_floats[1])
