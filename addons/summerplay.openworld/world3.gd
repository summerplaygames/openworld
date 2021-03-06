# MIT License
#
# Copyright (c) 2020 SummerPlay L.L.C.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

tool
extends Spatial

class_name OWWorld3D

export(Array, String, FILE) var scenes : Array = [] setget set_scenes
export var actor : NodePath

var _actor : Spatial

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
		pos = Vector2(_actor.global_transform.origin.x, _actor.global_transform.origin.z)

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
			var new_child = Spatial.new()
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
	var pos : Vector2 = grid.get_cell_pos(cell)
	new_node.transform.origin = Vector3(pos.x, new_node.transform.origin.y, pos.y)

func _populate() -> void:
	print("populate")
	for child in get_children():
		remove_child(child)
		child.queue_free()
	print(len(scenes))
	for scene in scenes:
		if scene:
			var node := Spatial.new()
			node.add_to_group("ow_dummy_cell")
			add_child(node)
