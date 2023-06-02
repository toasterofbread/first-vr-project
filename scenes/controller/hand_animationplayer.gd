tool
class_name HandAnimationPlayer
extends AnimationPlayer

const animations_directory: String = "res://models/hand/animations/"

export(Enums.SIDE) var side: int
export var animation_id_to_load: String = "default"
export var load_animation: bool = false setget ex_load_animation

var animations_loaded: bool = false
var animations: Dictionary = {}

func ex_load_animation(value: bool):
	if not value:
		return
	
	var dir: Directory = Directory.new()
	if not dir.dir_exists(animations_directory.plus_file(animation_id_to_load)):
		print("Animation ID does not exist")
		return
	
	dir.open(animations_directory.plus_file(animation_id_to_load))
	
	if dir.dir_exists(Enums.SIDE.keys()[side].to_lower()):
		dir.open(dir.get_current_dir().plus_file(Enums.SIDE.keys()[side].to_lower()))
	elif dir.dir_exists("any"):
		dir.open(dir.get_current_dir().plus_file("any"))
	else:
		print("The animation has no ", Enums.SIDE.keys()[side].to_lower(), " side, and no 'any' directory exists")
		return
	
	for finger in Enums.FINGER.values():
		
		if Enums.FINGER.keys()[finger] in get_animation_list():
			remove_animation(Enums.FINGER.keys()[finger])
		
		if dir.file_exists(str(finger) + ".tres"):
			add_animation(Enums.FINGER.keys()[finger], load(dir.get_current_dir().plus_file(str(finger) + ".tres")))
			print("Added animation for finger: ", Enums.FINGER.keys()[finger])
		else:
			print("No animation for finger: ", Enums.FINGER.keys()[finger])

#func _init():
#	load_animations()

func load_animations():
	if animations_loaded or Engine.editor_hint:
		return
	
	for animation in Utils.get_dir_items(animations_directory):
	
		animations[animation] = {}
		var items = Utils.get_dir_items(animations_directory.plus_file(animation))
		if items is int:
			break
		for finger in items:
			animations[animation][int(finger.split(".")[0])] = load(animations_directory.plus_file(animation).plus_file(finger))
	
	animations_loaded = true


