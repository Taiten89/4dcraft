class_name Calculation_Preprocessor
extends Node

var includes: Dictionary[String, String]


@warning_ignore("shadowed_variable")
func preprocess
(raw_code: String, includes: Dictionary[String, String]) \
-> String:
	self.includes = includes
	return do_preprocess(raw_code)


func do_preprocess (raw_code: String) -> String:
	var result_lines: Array[String] = []
	for source_line in raw_code.split('\n'):
		var result_line := do_line(source_line)
		if source_line == '#[compute]':
			continue
		result_lines.append(result_line)
	return '\n'.join(result_lines)


func do_line (source_line: String) -> String:
	if source_line.begins_with('#include '):
		return do_include(source_line)
	else:
		return source_line


func do_include (source_line: String) -> String:
	var quot_begin := source_line.find('"')
	var filename_ := source_line.substr(quot_begin + 1)
	var quot_end := filename_.find('"')
	var filename := filename_.substr(0, quot_end)
	if filename in includes:
		return includes[filename]
	else:
		return do_include_file(filename)


func do_include_file (filename: String) -> String:
	var res_name := "res://Calculation/" + filename
	var code := FileAccess.open(res_name, FileAccess.READ).get_as_text()
	return do_preprocess(code)
