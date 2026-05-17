class_name Slice_Paint
extends RefCounted

var calculation: Calculation
var params: Calculation.Params
var interpolation := Slice_Paint_Interpolate.new()
var alpha := 1.0
var result: Texture2DRD

const IMG_N := 3
var img_back := 0
var img_targ := 1
var img_rds: Array[Texture2DRD] = []
var img_uniforms: Array[RDUniform] = []
var palette_texture_rd: Texture2DRD
var rd: RenderingDevice
var shader: RID
var pipeline: RID


func _init (new_calculation: Calculation) -> void:
	calculation = new_calculation
	RenderingServer.call_on_render_thread(init_func)
func init_func () -> void:
	rd = RenderingServer.get_rendering_device()
	var rdss := RDShaderSource.new()
	var path := "res://Slice/Paint/paint.glsl"
	rdss.source_compute = FileAccess.open(path, FileAccess.READ).get_as_text()
	var shader_spirv := rd.shader_compile_spirv_from_source(rdss)
	Calculation.handle_any_errors(rdss.source_compute, shader_spirv)
	shader = rd.shader_create_from_spirv(shader_spirv)
	pipeline = rd.compute_pipeline_create(shader)


func paint
(slice: Slice, new_params: Calculation.Params, clear_bg := true) \
-> void:
	RenderingServer.call_on_render_thread \
		(paint_func.bind(slice, new_params, clear_bg))


func paint_func
(slice: Slice,
 new_params: Calculation.Params,
 clear_bg := true) \
-> void:
	reinit_if_needed(new_params)
	calculation.calculate(slice, new_params)
	do_paint(slice, clear_bg)
	result = img_rds[img_targ]
	img_back = img_targ
	img_targ = (img_back+1) % IMG_N


func interpolate () -> void:
	interpolation.interpolate(params, result)
	result = interpolation.target


func reinit_if_needed (new_params: Calculation.Params) -> void:
	var P := params == null
	var b := P or [params.w,params.h] != [new_params.w,new_params.h]
	var needed := P or b

	if needed:
		free_sized_resources()
		params = new_params.copy()
		create_sized_resources()
	else:
		params = new_params.copy()


func do_paint (slice: Slice, clear: bool) -> void:

	var uniforms := \
		[make_uniform_struct(slice, clear),
		 make_uniform_data(),
		 make_uniform_palette(slice),
		 img_uniforms[img_back],
		 img_uniforms[img_targ]]
	img_uniforms[img_back].binding = 3
	img_uniforms[img_targ].binding = 4
	var uniform_set := rd.uniform_set_create(uniforms, shader, 0)

	# group sizes incl. round-up division
	@warning_ignore("integer_division")
	var x_groups := (params.w + 16-1) / 16
	@warning_ignore("integer_division")
	var y_groups := (params.h + 16-1) / 16

	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	rd.compute_list_dispatch(compute_list, x_groups, y_groups, 1)
	rd.compute_list_end()

	rd.free_rid(uniforms[0].get_ids()[0])
	rd.free_rid(uniforms[2].get_ids()[0])
	uniform_set = RID()


func make_uniform_struct (slice: Slice, clear: bool) -> RDUniform:
	var bytes := bytes_for_uniform_struct(slice, clear)
	var buffer := rd.storage_buffer_create(bytes.size(), bytes)
	var uniform := RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniform.binding = 0
	uniform.add_id(buffer)
	return uniform


func make_uniform_data () -> RDUniform:
	var uniform := RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	uniform.binding = 1
	uniform.add_id(calculation.result_texture_rd.texture_rd_rid)
	return uniform


func make_uniform_palette (slice: Slice) -> RDUniform:
	var texture := slice.palette.create_texture()
	var uniform := RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	uniform.binding = 2
	uniform.add_id(texture.texture_rd_rid)
	return uniform


func create_sized_resources () -> void:
	RenderingServer.call_on_render_thread(create_sized_resources_func)
func create_sized_resources_func () -> void:
	for i in range(IMG_N):
		var img_rd := Texture2DRD.new()
		img_rd.texture_rd_rid = rd.texture_create \
			(make_texture_format(), RDTextureView.new(), [])
		img_rds.append(img_rd)
		var img_uniform := RDUniform.new()
		img_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
		img_uniform.add_id(img_rd.texture_rd_rid)
		img_uniforms.append(img_uniform)


func free_sized_resources () -> void:
	if params == null:
		return
	RenderingServer.call_on_render_thread(free_sized_resources_func)
func free_sized_resources_func () -> void:
	for i in range(IMG_N):
		if img_rds[i].texture_rd_rid.is_valid():
			rd.free_rid(img_rds[i].texture_rd_rid)
	img_rds = []
	img_uniforms = []


func bytes_for_uniform_struct (slice: Slice, clear: bool) -> PackedByteArray:
	var palette_size := slice.palette.items.size()
	var w := params.w
	var h := params.h
	var subsampling := params.subsampling
	var subsampling_step := params.subsampling_step

	var bytes := PackedInt32Array([slice.max_n]).to_byte_array()
	bytes += PackedInt32Array([palette_size]).to_byte_array()
	bytes += PackedInt32Array([w, h]).to_byte_array()
	bytes += PackedInt32Array([int(clear)]).to_byte_array()
	bytes += PackedFloat32Array([alpha]).to_byte_array()
	bytes += PackedInt32Array([subsampling, subsampling_step]).to_byte_array()
	return bytes


func make_texture_format () -> RDTextureFormat:
	var tf := RDTextureFormat.new()
	tf.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT
	tf.texture_type = RenderingDevice.TEXTURE_TYPE_2D
	tf.width = params.w
	tf.height = params.h
	tf.depth = 1
	tf.array_layers = 1
	tf.mipmaps = 1
	tf.usage_bits = \
		(RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT |
		 RenderingDevice.TEXTURE_USAGE_STORAGE_BIT |
		 RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT |
		 RenderingDevice.TEXTURE_USAGE_CAN_COPY_TO_BIT)
	return tf
