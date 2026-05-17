extends TextureRect

@onready var editor: Editor = $/root/Editor
@onready var album_edit: Album_Edit = $/root/Editor/Album


func _draw () -> void:
	var album := album_edit.album
	var bg_i := editor.background_intensity
	var bg_c := Color(bg_i, bg_i, bg_i)

	var cr: ColorRect = get_parent()
	cr.color = bg_c

	const CURSOR_W := 5
	const CURSOR_WW := Vector2(CURSOR_W,CURSOR_W)
	var cursor_c := Color(1.0,1.0,1.0) - bg_c
	cursor_c.a = 1.0
	var xy_i := Vector2(album_edit.xi, album_edit.yi)
	var l_e_wh := Vector2(album.ew, album.eh) * get_local_to_texture_size_ratio()
	var cursor_pos := get_texture_offset() + xy_i * l_e_wh - CURSOR_WW
	var cursor_rect := Rect2(cursor_pos, CURSOR_WW + l_e_wh + CURSOR_WW)
	draw_rect(cursor_rect, cursor_c, false, CURSOR_W)


func _on_gui_input (event: InputEvent) -> void:
	var album := album_edit.album
	if event is InputEventMouseButton and event.pressed:
		var xy := get_mouse_position_in_texture() / Vector2(album.ew, album.eh)
		album_edit.xi = int(clamp(xy.x, 0, album.nx-1))
		album_edit.yi = int(clamp(xy.y, 0, album.ny-1))


func get_mouse_position_in_texture () -> Vector2:
	var l_pos_no_offset := get_local_mouse_position() - get_texture_offset()
	return l_pos_no_offset / get_local_to_texture_size_ratio()


func get_texture_offset () -> Vector2:
	var l_ar := size.x / size.y
	var t_ar := texture.get_size().x / texture.get_size().y
	var l_t := get_local_to_texture_size_ratio()
	if l_ar > t_ar:
		var delta_x := size.x - l_t * texture.get_size().x
		return Vector2(delta_x, 0) / 2
	else:
		var delta_y := size.y - l_t * texture.get_size().y
		return Vector2(0, delta_y) / 2


func get_local_to_texture_size_ratio () -> float:
	var l_ar := size.x / size.y
	var t_ar := texture.get_size().x / texture.get_size().y
	if l_ar > t_ar:
		return size.y / texture.get_size().y
	else:
		return size.x / texture.get_size().x
