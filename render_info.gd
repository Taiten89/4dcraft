class_name Render_Info
extends RefCounted

enum PERSPECTIVE {BIRD, PORTRAIT}

var perspective := PERSPECTIVE.BIRD
var poster := Poster_Info.new()
var portrait := Portrait_Info.new()
var movie := Movie_Info.new()

func variant_for_storage () -> Dictionary[String,Variant]:
	var v: Dictionary[String,Variant] = {}
	v['perspective'] = PERSPECTIVE.find_key(perspective)
	v['poster'] = poster.variant_for_storage()
	v['portrait'] = portrait.variant_for_storage()
	v['movie'] = movie.variant_for_storage()
	return v

func set_from_storage_variant (v: Dictionary) -> void:
	var perspective_k: String = v['perspective']
	perspective = PERSPECTIVE[perspective_k]
	poster.set_from_storage_variant(v['poster'])
	portrait.set_from_storage_variant(v['portrait'])
	movie.set_from_storage_variant(v['movie'])


class Poster_Info:
	var w := 1920
	var h := 1080

	func variant_for_storage () -> Dictionary[String,Variant]:
		var v: Dictionary[String,Variant] = {}
		v['w'] = w
		v['h'] = h
		return v

	func set_from_storage_variant (v: Dictionary) -> void:
		w = v['w']
		h = v['h']


class Portrait_Info \
extends Poster_Info:
	var layers := 5000
	var preview_layers := 100

	func variant_for_storage () -> Dictionary[String,Variant]:
		var v := super.variant_for_storage()
		v['layers'] = layers
		v['preview_layers'] = preview_layers
		return v

	func set_from_storage_variant (v: Dictionary) -> void:
		super.set_from_storage_variant(v)
		layers = v['layers']
		preview_layers = v['preview_layers']


class Movie_Info \
extends Portrait_Info:
	var start := -1.0
	var stop := +1.0
	var images := 10_000
	var preview_images := 1_000
	var fps := 60.0

	func variant_for_storage () -> Dictionary[String,Variant]:
		var v := super.variant_for_storage()
		v['start'] = start
		v['stop'] = stop
		v['images'] = images
		v['preview_images'] = preview_images
		v['fps'] = fps
		return v

	func set_from_storage_variant (v: Dictionary) -> void:
		super.set_from_storage_variant(v)
		start = v['start']
		stop = v['stop']
		images = v['images']
		preview_images = v['preview_images']
		fps = v['fps']
