class_name Movie_Exporter
extends Process_With_N_Steps

var slice: Slice
var output: String
var image_i := 0


static func create (new_slice: Slice, new_output: String) -> Movie_Exporter:
	var exporter: Movie_Exporter
	if new_slice.render.perspective == Render_Info.PERSPECTIVE.BIRD:
		exporter = Bird_Movie_Exporter.new()
	if new_slice.render.perspective == Render_Info.PERSPECTIVE.PORTRAIT:
		exporter = Portrait_Movie_Exporter.new()
	exporter.output = new_output
	exporter.slice = new_slice.copy()
	exporter.modify_slice_to_start()
	exporter.init()
	exporter.write_info()
	return exporter

func output_fn () -> String:
	return output + "/%05d.png" % image_i

func prepare_for_next_image () -> void:
	modify_slice_by_image()
	image_i += 1

func write_info () -> void:
	var fps := str(slice.render.movie.fps)
	var fps_fn := output + "/00000_fps.txt"
	var fps_file = FileAccess.open(fps_fn, FileAccess.WRITE)
	fps_file.store_string(fps)

func modify_slice_to_start () -> void:
	var info := slice.render.movie
	var time_translation := info.start * slice.base.column(3)
	slice.position.translate_inplace(time_translation)

func modify_slice_by_image () -> void:
	var info := slice.render.movie
	var full_time_span := info.stop - info.start
	var time_factor := full_time_span / info.images
	var time_translation := time_factor * slice.base.column(3)

	if info.is_cc:
		slice.correct_continuously()
	slice.position.translate_inplace(time_translation)


class Bird_Movie_Exporter \
extends Movie_Exporter:

	func _init () -> void:
		pass

	func init () -> void:
		n_steps = slice.render.movie.images

	func step_impl () -> void:
		var poster := Poster.new(slice, slice.render.movie)
		for _i in range(poster.n_steps()):
			poster.step()
		poster.output(output_fn())

		prepare_for_next_image()


class Portrait_Movie_Exporter \
extends Movie_Exporter:

	var paint := Portrait_Paint.new(Calculation.new())

	func _init () -> void:
		pass

	func init () -> void:
		var images := slice.render.movie.images
		var layers := slice.render.movie.layers
		n_steps = images * layers
		paint.i = layers  # provoke start_portrait()

	func step_impl () -> void:
		var layers := slice.render.movie.layers
		if paint.i == layers:
			start_portrait()
		paint.step()
		if paint.i == layers:
			complete_portrait()

	func start_portrait () -> void:
		var info := slice.render.movie
		var portrait := Portrait.new(slice, info.layers)
		paint.start(portrait, info)

	func complete_portrait () -> void:
		var img := Image.new()
		img.copy_from(paint.result.get_image())
		img.convert(Image.FORMAT_RGBA8)
		img.save_png(output_fn())

		prepare_for_next_image()
