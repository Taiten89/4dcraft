class_name Movie_Exporter
extends Process_With_N_Steps

var mid: Slice
var output: String
var image_i := 0

static func create (new_mid: Slice, new_output: String) -> Movie_Exporter:
	var exporter: Movie_Exporter
	if new_mid.render.perspective == Render_Info.PERSPECTIVE.BIRD:
		exporter = Bird_Movie_Exporter.new()
	if new_mid.render.perspective == Render_Info.PERSPECTIVE.PORTRAIT:
		exporter = Portrait_Movie_Exporter.new()
	exporter.output = new_output
	exporter.mid = new_mid.copy()
	exporter.init()
	return exporter

func output_fn () -> String:
	return output + "/%05d.png" % image_i

func modified_slice () -> Slice:
	var mod := mid.copy()
	var info := mod.render.movie
	var full_time_span := info.stop - info.start
	var rel_time := float(image_i) / float(info.images)
	var time := info.start + rel_time * full_time_span
	mod.position.translate_inplace(time * mod.base.column(3))
	return mod


class Bird_Movie_Exporter \
extends Movie_Exporter:

	func _init () -> void:
		pass

	func init () -> void:
		n_steps = mid.render.movie.images

	func step_impl () -> void:
		var mod := modified_slice()
		var poster := Poster.new(mod, mid.render.movie)
		for _i in range(poster.n_steps()):
			poster.step()
		poster.output(output_fn())
		image_i += 1


class Portrait_Movie_Exporter \
extends Movie_Exporter:

	var paint := Portrait_Paint.new(Calculation.new())

	func _init () -> void:
		pass

	func init () -> void:
		var images := mid.render.movie.images
		var layers := mid.render.movie.layers
		n_steps = images * layers
		paint.i = layers  # provoke start_portrait()

	func step_impl () -> void:
		var layers := mid.render.movie.layers
		if paint.i == layers:
			start_portrait()
		paint.step()
		if paint.i == layers:
			complete_portrait()

	func start_portrait () -> void:
		var mod := modified_slice()
		var info := mod.render.movie
		var portrait := Portrait.new(mod, info.layers)
		paint.start(portrait, info)

	func complete_portrait () -> void:
		var img := Image.new()
		img.copy_from(paint.result.get_image())
		img.convert(Image.FORMAT_RGBA8)
		img.save_png(output_fn())
		image_i += 1
