class_name Palette
extends RefCounted

const DEFAULT := "f0f0"+"00ff"+"0f0f"+"f00f"+"f0ff"+"000f"

var items: Array[Item] = []


class Item:

	# 15 corresponds to 255 elsewhere
	var rgba: Array[int] = [0, 0, 0, 15]

	func _init (rgba_str: String) -> void:
		assert(rgba_str.length() == 4)
		for i in range(4):
			rgba[i] = rgba_str[i].hex_to_int()

	func _to_string () -> String:
		return "%X%X%X%X" % rgba

	func to_bytes () -> PackedByteArray:
		var result: PackedByteArray = []
		for i in range(4):
			var value := 17 * rgba[i]
			result.append(value)
		return result


func _init (rgba_str := DEFAULT) -> void:
	assert(rgba_str.length() % 4 == 0)
	@warning_ignore("integer_division")
	for i in range(rgba_str.length() / 4):
		var item_str := rgba_str.substr(i*4, 4)
		items.append(Item.new(item_str))


func _to_string () -> String:
	var result := ""
	for item in items:
		result += str(item)
	return result


func to_bytes () -> PackedByteArray:
	var result: PackedByteArray = []
	for item in items:
		result.append_array(item.to_bytes())
	return result


func variant_for_storage () -> String:
	return str(self)


func set_from_storage_variant (v: String) -> void:
	var tmp := Palette.new(v)
	items = tmp.items


func create_texture () -> Texture2D:
	var W := items.size()
	var H := 1
	var rd := RenderingServer.get_rendering_device()

	var tf := RDTextureFormat.new()
	tf.format = RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM
	tf.texture_type = RenderingDevice.TEXTURE_TYPE_2D
	tf.width = W
	tf.height = H
	tf.depth = 1
	tf.array_layers = 1
	tf.mipmaps = 1
	tf.usage_bits = \
		(RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT |
		 RenderingDevice.TEXTURE_USAGE_STORAGE_BIT)

	var texture := Texture2DRD.new()
	texture.texture_rd_rid = rd.texture_create \
		(tf, RDTextureView.new(), [to_bytes()])

	return texture


func copy () -> Palette:
	return Palette.new(str(self))
