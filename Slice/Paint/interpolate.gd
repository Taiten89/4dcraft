class_name Slice_Paint_Interpolate
extends RefCounted

var params: Calculation.Params
var source: Texture2DRD
var target: Texture2DRD

var source_uniform: RDUniform
var target_uniform: RDUniform
var rd: RenderingDevice
var shader: RID
var pipeline: RID


func _init () -> void:
	RenderingServer.call_on_render_thread(init_func)
func init_func () -> void:
	rd = RenderingServer.get_rendering_device()
	var rdss := RDShaderSource.new()
	var path := "res://Slice/Paint/interpolate.glsl"
	rdss.source_compute = FileAccess.open(path, FileAccess.READ).get_as_text()
	var shader_spirv := rd.shader_compile_spirv_from_source(rdss)
	Calculation.handle_any_errors(rdss.source_compute, shader_spirv)
	shader = rd.shader_create_from_spirv(shader_spirv)
	pipeline = rd.compute_pipeline_create(shader)

	source_uniform = RDUniform.new()
	source_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	source_uniform.binding = 1
	target_uniform = RDUniform.new()
	target_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	target_uniform.binding = 2


func interpolate
(new_params: Calculation.Params, new_source: Texture2DRD) \
-> void:
	source = new_source
	RenderingServer.call_on_render_thread(reinit_if_needed.bind(new_params))
	RenderingServer.call_on_render_thread(interpolate_func)


func reinit_if_needed (new_params: Calculation.Params) -> void:
	if target == null:
		params = new_params.copy()
		create_sized_resources()
		return
	if [new_params.w,new_params.h] != [params.w,params.h]:
		free_sized_resources()
		params = new_params.copy()
		create_sized_resources()
		return
	params = new_params.copy()


func create_sized_resources () -> void:
	var tf := RDTextureFormat.new()
	tf.format = RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM
	tf.width = params.w
	tf.height = params.h
	tf.usage_bits = \
		(RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT |
		 RenderingDevice.TEXTURE_USAGE_STORAGE_BIT)
	target = Texture2DRD.new()
	target.texture_rd_rid = rd.texture_create(tf, RDTextureView.new())


func free_sized_resources () -> void:
	rd.free_rid(target.texture_rd_rid)


func interpolate_func () -> void:
	source_uniform.clear_ids()
	source_uniform.add_id(source.texture_rd_rid)
	target_uniform.clear_ids()
	target_uniform.add_id(target.texture_rd_rid)

	var uniforms := \
		[make_uniform_struct(),
		 source_uniform,
		 target_uniform]
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
	uniform_set = RID()


func make_uniform_struct () -> RDUniform:
	var bytes := bytes_for_uniforms()
	var buffer := rd.storage_buffer_create(bytes.size(), bytes)
	var uniform := RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniform.binding = 0
	uniform.add_id(buffer)
	return uniform


func bytes_for_uniforms () -> PackedByteArray:
	var w := params.w
	var h := params.h
	var subsampling := params.subsampling
	var subsampling_step := params.subsampling_step
	var bytes := PackedInt32Array([w, h]).to_byte_array()
	bytes += PackedInt32Array([subsampling, subsampling_step]).to_byte_array()
	return bytes
