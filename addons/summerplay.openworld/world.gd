tool
extends Node2D

class_name OWWorld2D

export(Array, String, FILE) var scenes : Array = [] setget set_scenes
export var actor : NodePath

var _actor : Node2D

export var grid : Resource setget set_grid

var _scene_loader := _OWSceneLoader.new()

func set_grid(val : Resource) -> void:
	if not (val is OWGrid):
		push_warning("grid must be a OWGrid")
		return
	grid = val
	if not grid.is_connected("grid_changed", self, "_populate"):
		grid.connect("grid_changed", self, "_populate")

func set_scenes(val : Array) -> void:
	scenes = val
	_populate()

func _ready() -> void:
	_populate()
	var err := _scene_loader.start()
	if err != OK:
		push_error("failed to start openworld load thread. Error:" + str(err))

func _process(delta: float) -> void:
	if not grid:
		return
	var pos = Vector2.ZERO
	if _actor:
		pos = _actor.global_position

	var cell : int = grid.get_cell(pos)
	if cell < 0:
		return
	var col : int = grid.cell_column(cell)
	var row : int = grid.cell_row(cell)
	for i in range(get_child_count()):
		if i >= scenes.size():
			return
		var n = get_child(i)
		var c : int = grid.cell_column(i)
		var r : int = grid.cell_row(i)
		if ((c >= col-1 and c <= col+1 and r >= row-1 and r <= row +1) and n.is_in_group("ow_dummy_cell") and not n.is_in_group("marked")):
			n.add_to_group("marked")
			var req := _OWSceneLoader.LoadRequest.new(scenes[i], n, i)
			_scene_loader.request_load(req)
		elif ((c < col-1 or c > col+1 or r < row-1 or r > row +1) and n.is_in_group("ow_cell")):
			var new_child = Node2D.new()
			new_child.add_to_group("ow_dummy_cell")
			_replace_node(n, new_child, i)
			for ch in new_child.get_children():
				ch.queue_free() 
	
	var next : _OWSceneLoader.LoadResult = _scene_loader.poll()
	if next:
		var new_node = next.loaded_scene.instance()
		new_node.add_to_group("ow_cell")
		_replace_node(next.old_node, new_node, next.cell)

func _exit_tree() -> void:
	_scene_loader.stop()

func _replace_node(old_node, new_node, cell : int) -> void:
	old_node.replace_by(new_node)
	new_node.position = grid.get_cell_pos(cell)

func _populate() -> void:
	print("populate")
	for child in get_children():
		remove_child(child)
		child.queue_free()
	print(len(scenes))
	for scene in scenes:
		if scene:
			var node := Node2D.new()
			node.add_to_group("ow_dummy_cell")
			add_child(node)
		
