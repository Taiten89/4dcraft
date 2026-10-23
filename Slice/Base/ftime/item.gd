class_name Find_Time_Item

class Item \
extends RefCounted:

	var base: Base
	var aberration := 0

	func _init (new_base: Base) -> void:
		base = new_base.copy()
