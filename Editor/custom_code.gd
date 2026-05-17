extends CodeEdit

@onready var main: Editor = $/root/Editor
@onready var view_calculation: Calculation = $"../View".calculation


func _on_visibility_changed () -> void:
	if is_visible_in_tree():
		update_from_main()
	else:
		push_to_main()


func update_from_main () -> void:
	text = main.slice.custom_code


func push_to_main () -> void:
	main.slice.custom_code = text


func _on_text_changed () -> void:
	view_calculation.custom_code_changed = true
