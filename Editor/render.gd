extends HBoxContainer

@onready var editor: Editor = $/root/Editor

@onready var perspective: OptionButton = find_child("Perspective")

@onready var poster_w: SpinBox = $Poster.find_child("W")
@onready var poster_h: SpinBox = $Poster.find_child("H")

@onready var portrait_w: SpinBox = $Portrait.find_child("W")
@onready var portrait_h: SpinBox = $Portrait.find_child("H")
@onready var portrait_layers: SpinBox = $Portrait.find_child("Layers")
@onready var portrait_preview_layers: SpinBox = $Portrait.find_child("Preview_Layers")

@onready var movie_w: SpinBox = $Movie.find_child("W")
@onready var movie_h: SpinBox = $Movie.find_child("H")
@onready var movie_layers: SpinBox = $Movie.find_child("Layers")
@onready var movie_preview_layers: SpinBox = $Movie.find_child("Preview_Layers")
@onready var movie_start: SpinBox = $Movie.find_child("Start")
@onready var movie_stop: SpinBox = $Movie.find_child("Stop")
@onready var movie_is_cc: CheckBox = $Movie.find_child("Is_CC")
@onready var movie_images: SpinBox = $Movie.find_child("Images")
@onready var movie_preview_images: SpinBox = $Movie.find_child("Preview_Images")
@onready var movie_fps: SpinBox = $Movie.find_child("FPS")


func _ready () -> void:
	for p in Render_Info.PERSPECTIVE:
		perspective.add_item(p)


func _on_visibility_changed () -> void:
	if is_visible_in_tree():
		update_from_main()
	else:
		push_to_main()


func update_from_main () -> void:
	perspective.select(editor.slice.render.perspective)

	var poster := editor.slice.render.poster
	poster_w.set_value_no_signal(poster.w)
	poster_h.set_value_no_signal(poster.h)

	var portrait := editor.slice.render.portrait
	portrait_w.set_value_no_signal(portrait.w)
	portrait_h.set_value_no_signal(portrait.h)
	portrait_layers.set_value_no_signal(portrait.layers)
	portrait_preview_layers.set_value_no_signal(portrait.preview_layers)

	var movie := editor.slice.render.movie
	movie_w.set_value_no_signal(movie.w)
	movie_h.set_value_no_signal(movie.h)
	movie_layers.set_value_no_signal(movie.layers)
	movie_preview_layers.set_value_no_signal(movie.preview_layers)
	movie_start.set_value_no_signal(movie.start)
	movie_stop.set_value_no_signal(movie.stop)
	movie_is_cc.set_pressed_no_signal(movie.is_cc)
	movie_images.set_value_no_signal(movie.images)
	movie_preview_images.set_value_no_signal(movie.preview_images)
	movie_fps.set_value_no_signal(movie.fps)


func push_to_main () -> void:
	var selected_perspective := perspective.selected as Render_Info.PERSPECTIVE
	editor.slice.render.perspective = selected_perspective

	poster_w.apply()
	poster_h.apply()
	var poster := editor.slice.render.poster
	poster.w = int(poster_w.value)
	poster.h = int(poster_h.value)

	portrait_w.apply()
	portrait_h.apply()
	portrait_layers.apply()
	portrait_preview_layers.apply()
	var portrait := editor.slice.render.portrait
	portrait.w = int(portrait_w.value)
	portrait.h = int(portrait_h.value)
	portrait.layers = int(portrait_layers.value)
	portrait.preview_layers = int(portrait_preview_layers.value)

	movie_w.apply()
	movie_h.apply()
	movie_layers.apply()
	movie_preview_layers.apply()
	movie_start.apply()
	movie_stop.apply()
	movie_images.apply()
	movie_preview_images.apply()
	movie_fps.apply()
	var movie := editor.slice.render.movie
	movie.w = int(movie_w.value)
	movie.h = int(movie_h.value)
	movie.layers = int(movie_layers.value)
	movie.preview_layers = int(movie_preview_layers.value)
	movie.start = movie_start.value
	movie.stop = movie_stop.value
	movie.is_cc = movie_is_cc.button_pressed
	movie.images = int(movie_images.value)
	movie.preview_images = int(movie_preview_images.value)
	movie.fps = movie_fps.value

	editor.slice_changed = true
