extends Node

var requests : Dictionary[String, Dictionary]
var completed_requests : Array[String]

func _process(_delta: float) -> void:
	for request in requests:
		var progress := []
		var status := ResourceLoader.load_threaded_get_status(request, progress)
		if status == ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED:
			var on_complete := requests[request]["complete"] as Callable
			on_complete.call(ResourceLoader.load_threaded_get(request))
			completed_requests.push_back(request)
			continue
		var set_progress := requests[request]["progress"] as Callable
		if set_progress:
			set_progress.call(progress[0])
	
	for req in completed_requests:
		requests.erase(req)
	completed_requests.clear()
	
	if requests.is_empty():
		process_mode = Node.PROCESS_MODE_DISABLED

func load_map(resource_path: String, on_complete: Callable, set_progress: Callable = Callable()) -> bool:
	var error := ResourceLoader.load_threaded_request(resource_path)
	if error:
		return false
	
	requests[resource_path] = {
		"complete": on_complete,
		"progress": set_progress
	}
	
	process_mode = Node.PROCESS_MODE_ALWAYS
	return true
