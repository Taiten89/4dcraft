extends TabContainer


func _ready() -> void:
	const controls_p := "res://Editor/Info/controls.txt"
	$Controls.text = FileAccess.open(controls_p, FileAccess.READ).get_as_text()

	const readme_p := "res://README.md"
	$Readme.text = "Contents of README.md;\n"
	$Readme.text += "visit project homepage for better representation.\n\n\n"
	$Readme.text += FileAccess.open(readme_p, FileAccess.READ).get_as_text()

	const license_p := "res://LICENSE.txt"
	$License.text = FileAccess.open(license_p, FileAccess.READ).get_as_text()
