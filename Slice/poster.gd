class_name Poster
extends RefCounted

const AA_W := 4
const CHUNK_W := 256

var slice: Slice
var paint := Slice_Paint.new(Calculation.new())
# raw measures (final output will be scaled down)
var rw: int
var rh: int
# raw output
var r_output: Image
# translations per raw pixel in fractal space
var render_x_prp: Vector4
var render_y_prp: Vector4
# n chunks = ncx * ncy
var ncx: int
var ncy: int
# state
var cxi := 0
var cyi := 0


func _init (new_slice: Slice, w: int, h: int) -> void:
	slice = new_slice.copy()
	rw = AA_W * w
	rh = AA_W * h
	r_output = Image.create_empty(rw, rh, false, Image.FORMAT_RGBAF)
	var render_xy := slice.render_xy_for_aspect_ratio(float(w)/float(h))
	render_x_prp = render_xy[0] / (rw / 2.0)
	render_y_prp = -render_xy[1] / (rh / 2.0)
	# n chunks = ncx * ncy
	@warning_ignore("integer_division")
	ncx = (rw + CHUNK_W-1) / CHUNK_W  # round-up division
	@warning_ignore("integer_division")
	ncy = (rh + CHUNK_W-1) / CHUNK_W


func n_steps () -> int:
	return ncx * ncy


func step () -> void:
	var rx := cxi * CHUNK_W
	var ry := cyi * CHUNK_W
	var cw := CHUNK_W
	if rx + cw > rw:
		cw = rw - rx
	var ch := CHUNK_W
	if ry + ch > rh:
		ch = rh - ry

	var translation_x_p := -rw / 2.0 + rx + cw / 2.0
	var translation_y_p := -rh / 2.0 + ry + ch / 2.0
	var translation := translation_x_p * render_x_prp \
		+ translation_y_p * render_y_prp
	var c_slice := slice.copy()
	c_slice.position.translate_inplace(translation)

	var scale: float
	if cw > ch:
		if rw > rh:
			scale = float(ch) / float(rh)
		else:
			scale = float(ch) / float(rw)
	else:
		if rw > rh:
			scale = float(cw) / float(rh)
		else:
			scale = float(cw) / float(rw)
	c_slice.base.scale_inplace(scale)

	var params := Calculation.Params.new()
	params.w = cw
	params.h = ch
	params.workgroup_w = 16
	params.workgroup_h = 16
	paint.paint(c_slice, params)

	var src_rect := Rect2i(Vector2i(0,0), Vector2i(cw,ch))
	var dst := Vector2i(rx,ry)
	r_output.blit_rect(paint.result.get_image(), src_rect, dst)

	cxi += 1
	if cxi == ncx:
		cxi = 0
		cyi += 1


func output (fn: String) -> void:
	var png := Image.new()
	png.copy_from(r_output)
	@warning_ignore("integer_division")
	png.resize(rw/AA_W, rh/AA_W, Image.INTERPOLATE_BILINEAR)
	png.convert(Image.FORMAT_RGBA8)
	png.save_png(fn)
