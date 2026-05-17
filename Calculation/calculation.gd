class_name Calculation
extends Node


var slice: Slice
var params: Params
var mode: String
var custom_code_changed := false
var precision: int

var preprocessor := Calculation_Preprocessor.new()

var result_texture_rd: Texture2DRD
var result_uniform: RDUniform
var rd: RenderingDevice
var shader: RID
var pipeline: RID


class Params:

	var w: int
	var h: int
	var subsampling := 1
	var subsampling_step := 0
	var workgroup_w: int
	var workgroup_h: int

	func bytes_for_uniform_struct (slice: Slice) -> PackedByteArray:
		var own_bytes := PackedByteArray()
		own_bytes += PackedInt32Array([subsampling_step,0,0,0]).to_byte_array()

		var aspect_ratio := float(w) / float(h)
		return own_bytes + slice.bytes_for_uniforms(aspect_ratio)

	func copy () -> Params:
		var params := Params.new()
		params.w = w
		params.h = h
		params.subsampling = subsampling
		params.subsampling_step = subsampling_step
		params.workgroup_w = workgroup_w
		params.workgroup_h = workgroup_h
		return params


func compile (new_params: Params, new_mode: String, new_precision: int) -> void:
	params = new_params.copy()
	mode = new_mode
	precision = new_precision
	RenderingServer.call_on_render_thread(compile_func)
func compile_func () -> void:
	rd = RenderingServer.get_rendering_device()

	var rdss := RDShaderSource.new()
	rdss.source_compute = make_code()
	var shader_spirv := rd.shader_compile_spirv_from_source(rdss)
	handle_any_errors(rdss.source_compute, shader_spirv)
	shader = rd.shader_create_from_spirv(shader_spirv)
	pipeline = rd.compute_pipeline_create(shader)

	create_sized_resources()


static func handle_any_errors (source: String, spirv: RDShaderSPIRV) -> void:
	if spirv.compile_error_compute:
		print(spirv.compile_error_compute)
		var lines := source.split("\n")
		for i in range(lines.size()):
			print(i+1, "   \t", lines[i])


func uncompile () -> void:
	RenderingServer.call_on_render_thread(uncompile_func)
func uncompile_func () -> void:
	free_sized_resources()
	rd.free_rid(shader)


func calculate (new_slice: Slice, new_params: Params) -> void:
	RenderingServer.call_on_render_thread(calculate_func.bind(new_slice, new_params))
func calculate_func (new_slice: Slice, new_params: Params) -> void:
	recompile_if_needed(new_slice, new_params)

	var uniform_struct := make_uniform_struct()
	var uniforms := [uniform_struct, result_uniform]
	var uniform_set := rd.uniform_set_create(uniforms, shader, 0)

	# group sizes incl. round-up division
	var local_size_x := params.workgroup_w
	var local_size_y := params.workgroup_h
	@warning_ignore("integer_division")
	var x_groups := (params.w + local_size_x-1) / local_size_x
	@warning_ignore("integer_division")
	var y_groups := (params.h + local_size_y-1) / local_size_y

	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	rd.compute_list_dispatch(compute_list, x_groups, y_groups, 1)
	rd.compute_list_end()

	rd.free_rid(uniform_struct.get_ids()[0])
	uniform_set = RID()


func recompile_if_needed (new_slice: Slice, new_params: Params) -> void:
	var P := params == null
	var a := new_slice.mode != mode
	var b := new_slice.mode == "custom" and custom_code_changed
	var c := new_slice.position.precision != precision
	var d := P or \
		[new_params.w,new_params.h] != [params.w,params.h]
	var e := P or \
		new_params.subsampling != params.subsampling
	var f := P or \
		[new_params.workgroup_w, new_params.workgroup_h] != \
		[params.workgroup_w, params.workgroup_h]

	if not (a or b or c or d or e or f):
		slice = new_slice.copy()
		params = new_params.copy()
		return

	if pipeline:
		uncompile()
	slice = new_slice.copy()
	#params = new_params.copy()  # done in compile(...)
	compile(new_params, new_slice.mode, new_slice.position.precision)

	custom_code_changed = false


func create_sized_resources () -> void:
	RenderingServer.call_on_render_thread(create_sized_resources_func)
func create_sized_resources_func () -> void:
	result_texture_rd = Texture2DRD.new()
	result_texture_rd.texture_rd_rid = rd.texture_create \
		(make_texture_format(), RDTextureView.new(), [])
	result_uniform = RDUniform.new()
	result_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	result_uniform.binding = 1
	result_uniform.add_id(result_texture_rd.texture_rd_rid)


func free_sized_resources () -> void:
	RenderingServer.call_on_render_thread(free_sized_resources_func)
func free_sized_resources_func () -> void:
	if result_texture_rd.texture_rd_rid.is_valid():
		rd.free_rid(result_texture_rd.texture_rd_rid)
	result_texture_rd = Texture2DRD.new()


func make_uniform_struct () -> RDUniform:
	var bytes := params.bytes_for_uniform_struct(slice)
	var buffer := rd.storage_buffer_create(bytes.size(), bytes)
	var uniform := RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniform.binding = 0
	uniform.add_id(buffer)
	return uniform


func make_code () -> String:
	var path := "res://Calculation/compute.glsl"
	var raw_code := FileAccess.open(path, FileAccess.READ).get_as_text()
	var includes: Dictionary[String,String] = \
		{"Includes/defines.glslinc": make_defines(),
		 "Modes/default.glslinc": make_mode_code()}
	return preprocessor.preprocess(raw_code, includes)


func make_defines () -> String:
	var code := ""

	code += '#define W ' + str(params.w) + '\n'
	code += '#define H ' + str(params.h) + '\n'
	code += '#define SUBSAMPLING ' + str(params.subsampling) + '\n\n'

	code += '#define LOCAL_SIZE_X ' + str(params.workgroup_w) + '\n'
	code += '#define LOCAL_SIZE_Y ' + str(params.workgroup_h) + '\n\n'

	if precision == Position.PRECISION_FLOATS:
		code += '#define USE_FLOATS\n'
	if precision == Position.PRECISION_DOUBLES:
		code += '#define USE_DOUBLES\n'
	if precision >= Position.PRECISION_ARBITRARY:
		code += '#define USE_FIXED\n'
		code += '#define PRECISION ' + str(precision) + '\n'

	return code


func make_mode_code () -> String:
	if mode == "custom":
		return slice.custom_code

	var path := "res://Calculation/Modes/" + mode + ".glslinc"
	return FileAccess.open(path, FileAccess.READ).get_as_text()


func make_texture_format () -> RDTextureFormat:
	var tf := RDTextureFormat.new()
	tf.format = RenderingDevice.DATA_FORMAT_R32_SFLOAT
	tf.texture_type = RenderingDevice.TEXTURE_TYPE_2D
	tf.width = params.w
	tf.height = params.h
	tf.depth = 1
	tf.array_layers = 1
	tf.mipmaps = 1
	tf.usage_bits = \
		(RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT |
		 RenderingDevice.TEXTURE_USAGE_STORAGE_BIT |
		 RenderingDevice.TEXTURE_USAGE_CAN_COPY_TO_BIT)
	return tf
