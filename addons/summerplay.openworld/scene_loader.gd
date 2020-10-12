class_name _OWSceneLoader

var _mu := Mutex.new()
var _mu2 := Mutex.new()

var _in_queue := []
var _out_queue := []

var _thread := Thread.new()
var _done : bool


func start() -> int:
	return _thread.start(self, "_bg_process")

func stop() -> void:
	if _thread.is_active():
		_done = true
		_thread.wait_to_finish()

func request_load(req : LoadRequest) -> void:
	_mu.lock()
	_in_queue.push_back(req)
	_mu.unlock()

func poll() -> LoadResult:
	var next : LoadResult
	_mu2.lock()
	next = _out_queue.pop_front()
	_mu2.unlock()
	return next

func _bg_process(userdata):
	while not _done:
		_mu.lock()
		var next : LoadRequest = _in_queue.pop_front()
		_mu.unlock()
		if not next:
			continue
		var scene = load(next.scene_path)
		_mu2.lock()
		_out_queue.push_back(LoadResult.new(next.old_node, scene, next.cell))
		_mu2.unlock()

class LoadRequest:
	var scene_path : String
	var old_node : Node
	var cell : int
	
	func _init(scene_path : String, old_node : Node, cell : int) -> void:
		self.scene_path = scene_path
		self.old_node = old_node
		self.cell = cell
		

class LoadResult:
	var old_node : Node
	var loaded_scene : PackedScene
	var cell : int
	
	func _init(old_node : Node, loaded_scene : PackedScene, cell : int) -> void:
		self.old_node = old_node
		self.loaded_scene = loaded_scene
		self.cell = cell
	
