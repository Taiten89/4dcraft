class_name Palette_Edit
extends HBoxContainer

var rgba_inputs: Array[SpinBox]
var palette: Palette
var selected_i := 0


func _ready() -> void:
	rgba_inputs = \
		[$Input_Box/R_Input,
		 $Input_Box/G_Input,
		 $Input_Box/B_Input,
		 $Input_Box/A_Input]


func update (new_palette: Palette) -> void:
	palette = new_palette.copy()
	do_update()


func pull () -> Palette:
	return palette.copy()


func do_update () -> void:
	if selected_i >= palette.items.size():
		selected_i = palette.items.size() - 1
	for ci in range(4):
		rgba_inputs[ci].set_value_no_signal(palette.items[selected_i].rgba[ci])

	$Gradient.material.set_shader_parameter(&"selected_i", selected_i)
	$Gradient.material.set_shader_parameter(&"palette_size", palette.items.size())
	$Gradient.material.set_shader_parameter(&"palette", palette.create_texture())


func _on_rgba_value_changed (_value: float) -> void:
	for ci in range(4):
		palette.items[selected_i].rgba[ci] = int(rgba_inputs[ci].value)
	do_update()


func _on_gradient_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var t: float = event.position.x / $Gradient.size.x
		selected_i = round(t * (palette.items.size()-1))
		do_update()


func _on_add_pressed() -> void:
	var selected_str := str(palette.items[selected_i])
	var new_item := Palette.Item.new(selected_str)
	palette.items.insert(selected_i, new_item)
	do_update()


func _on_remove_pressed() -> void:
	if palette.items.size() <= 2:
		return
	palette.items.remove_at(selected_i)
	do_update()
