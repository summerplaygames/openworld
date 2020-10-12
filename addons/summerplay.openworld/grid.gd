tool
extends Resource

class_name OWGrid

export var offset : Vector2 = Vector2.ZERO setget set_offset
export var cell_size : Vector2 = Vector2(128, 128) setget set_cell_size
export var columns : int = 1 setget set_columns

signal grid_changed

func set_offset(val : Vector2) -> void:
	offset = val
	emit_signal("grid_changed")

func set_cell_size(val : Vector2) -> void:
	cell_size = val
	emit_signal("grid_changed")

func set_columns(val : int) -> void:
	columns = val
	emit_signal("grid_changed")

func get_cell(pos : Vector2) -> int:
	var r = Rect2(offset, cell_size)
	var i = 0
	while true:
		var col = i % columns
		var row = i / columns
		r.position.x = offset.x + (col * cell_size.x)
		r.position.y = offset.y + (row * cell_size.y)
		if r.has_point(pos):
			return i
		i+=1
	return -1

func get_cell_pos(cell : int) -> Vector2:
	var col = cell % columns
	var row = cell / columns
	return Vector2(offset.x + (col * cell_size.x), offset.y + (row * cell_size.y))

func cell_column(cell : int) -> int:
	return cell % columns

func cell_row(cell : int) -> int:
	return cell / columns
