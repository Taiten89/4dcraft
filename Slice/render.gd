class_name Render_Info
extends RefCounted

enum PERSPECTIVE {BIRD, PORTRAIT}

var perspective := PERSPECTIVE.BIRD
var poster := Poster_Info.new()
var portrait := Portrait_Info.new()
var movie := Movie_Info.new()

func copy () -> Render_Info:
	var info := Render_Info.new()
	info.perspective = perspective
	info.poster = poster.copy()
	info.portrait = portrait.copy()
	info.movie = movie.copy()
	return info

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

	func copy () -> Poster_Info:
		var info := Poster_Info.new()
		info.set_from_poster(self)
		return info

	func set_from_poster (info: Poster_Info) -> void:
		w = info.w
		h = info.h

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

	func copy () -> Portrait_Info:
		var info := Portrait_Info.new()
		info.set_from_portrait(self)
		return info

	func set_from_portrait (info: Portrait_Info) -> void:
		set_from_poster(info)
		layers = info.layers
		preview_layers = info.preview_layers

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
	var start := 0.0
	var stop := +1.0
	var images := 10_000
	var preview_images := 1_000
	var fps := 60.0
	var cc_enabled := false
	var cc_params := Find_Time_Params.Params.new_for_cc()

	func _init () -> void:
		preview_layers = 200

	func copy () -> Movie_Info:
		var info := Movie_Info.new()
		info.set_from_movie(self)
		return info

	func set_from_movie (info: Movie_Info) -> void:
		set_from_portrait(info)
		start = info.start
		stop = info.stop
		images = info.images
		preview_images = info.preview_images
		fps = info.fps
		cc_enabled = info.cc_enabled
		cc_params = info.cc_params.copy()

	func variant_for_storage () -> Dictionary[String,Variant]:
		var v := super.variant_for_storage()
		v['start'] = start
		v['stop'] = stop
		v['images'] = images
		v['preview_images'] = preview_images
		v['fps'] = fps
		v['cc_enabled'] = cc_enabled
		v['cc_params'] = cc_params.variant_for_storage()
		return v

	func set_from_storage_variant (v: Dictionary) -> void:
		super.set_from_storage_variant(v)
		start = v['start']
		stop = v['stop']
		images = v['images']
		preview_images = v['preview_images']
		fps = v['fps']
		cc_enabled = v['cc_enabled'] if 'cc_enabled' in v else false
		cc_params = Find_Time_Params.Params.new_for_cc()
		if 'cc_params' in v:
			cc_params.set_from_storage_variant(v['cc_params'])
