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

func write_info () -> void:
	var fps := str(slice.render.movie.fps)
	var fps_fn := output + "/00000_fps.txt"
	var fps_file = FileAccess.open(fps_fn, FileAccess.WRITE)
	fps_file.store_string(fps)

func modify_slice_to_start () -> void:
	var info := slice.render.movie
	var time_translation := info.start * slice.base.column(3)
	slice.position.translate_inplace(time_translation)
	if info.cc_enabled:
		slice.begin_cc()

func after_image_completed () -> void:
	var info := slice.render.movie
	slice.modify_for_1_image()
	image_i += 1
	if image_i == info.images:
		after_movie_completed()

func after_movie_completed () -> void:
	save_end_album()

func save_end_album () -> void:
	const ALBUM_SIZE := 256
	var fn := output + '/00000_end_album' + Album.FN_EXT
	var info := slice.render.movie
	var w_h := float(info.w) / float(info.h)
	var ew: int
	var eh: int
	if w_h > 1.0:
		ew = int(w_h * ALBUM_SIZE)
		eh = ALBUM_SIZE
	else:
		ew = ALBUM_SIZE
		eh = int(ALBUM_SIZE / w_h)

	var album := Album.new(1, 1, ew, eh)
	album.set_item(0, 0, slice)
	album.render(0, 0)
	album.save_as_files(fn)


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

		after_image_completed()


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

		after_image_completed()
