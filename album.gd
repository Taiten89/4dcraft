class_name Album
extends RefCounted

const MAX_EW := 256
const MAX_EH := 256

var nx: int
var ny: int
var ew: int
var eh: int
var items: Array[Slice] = []

var image: Image
const IMAGE_FORMAT := Image.FORMAT_RGBAF

var paint: Slice_Paint
var aa_factor := 4


func _init (new_nx := 10, new_ny := 10, new_ew := 128, new_eh := 128) -> void:
	nx = new_nx
	ny = new_ny
	ew = new_ew
	eh = new_eh
	make_new()


func make_new () -> void:
	items.resize(nx*ny)
	items.fill(null)
	image = Image.create(nx*ew, ny*eh, false, IMAGE_FORMAT)


func get_item (x: int, y: int) -> Slice:
	var item := items[x + y*nx]
	if item == null:
		return null
	return item.copy()
func set_item (x: int, y: int, item: Slice) -> void:
	items[x + y*nx] = null
	if item != null:
		items[x + y*nx] = item.copy()


func variant_for_storage () -> Dictionary[String,Variant]:
	var v: Dictionary[String,Variant] = {}
	v['nx'] = nx
	v['ny'] = ny
	v['ew'] = ew
	v['eh'] = eh
	v['items'] = []
	for item in items:
		if item == null:
			v['items'].append(null)
			continue
		v['items'].append(item.variant_for_storage())
	return v


func set_from_storage_variant (v: Dictionary) -> void:
	nx = v['nx']
	ny = v['ny']
	ew = v['ew']
	eh = v['eh']
	items.resize(v['items'].size())
	for i in range(v['items'].size()):
		var v_item: Variant = v['items'][i]
		if v_item == null:
			items[i] = null
			continue
		var item := Slice.new()
		item.set_from_storage_variant(v_item)
		items[i] = item


func render (x: int, y: int) -> void:
	var item := get_item(x, y)
	var rect := Rect2i(x*ew, y*eh, ew, eh)

	if item == null:
		image.fill_rect(rect, Color(0,0,0, 0))
		return

	var params := Calculation.Params.new()
	params.w = ew * aa_factor
	params.h = eh * aa_factor
	params.workgroup_w = 16
	params.workgroup_h = 16
	paint.paint(item, params)

	var paint_image := paint.result.get_image()
	paint_image.resize(ew, eh, Image.INTERPOLATE_BILINEAR)

	var src_rect := Rect2i(0, 0, rect.size.x, rect.size.y)
	image.blit_rect(paint_image, src_rect, rect.position)


func extend (xy: Vector2i, axis: int, signum: int) -> bool:
	var size :=  nx if axis == 0  else ny
	var ia := xy[axis]
	var source := get_item(xy.x, xy.y)
	var ia_ := ia + signum
	var xy_ := Vector2i(xy)
	xy_[axis] += signum

	if ia_ >= size:
		return false
	if ia_ < 0:
		return false
	if source == null:
		return false

	var result := source.copy()
	var aspect_ratio := float(ew) / float(eh)
	var translation_xy := result.render_xy_for_aspect_ratio(aspect_ratio)
	var translation := 2 * signum * translation_xy[0] if axis == 0 \
		else 2 * signum * -translation_xy[1]  # respect Y/Fore inconsistency
	result.position.translate_inplace(translation)
	set_item(xy_.x, xy_.y, result)
	render(xy_.x, xy_.y)

	return true
