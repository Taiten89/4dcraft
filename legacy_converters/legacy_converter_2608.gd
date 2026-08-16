extends SceneTree


func _init () -> void:
	var a_str := FileAccess.open('a.json', FileAccess.READ).get_as_text()
	var a: Variant = JSON.parse_string(a_str)

	var r := Render_Info.new().variant_for_storage()
	for item in a['items']:
		if item:
			item['render'] = r

	var b_str := JSON.stringify(a)
	var b_file := FileAccess.open('b.json', FileAccess.WRITE)
	b_file.store_string(b_str)
	b_file.close()
