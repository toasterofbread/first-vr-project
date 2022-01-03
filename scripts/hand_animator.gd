tool
class_name HandAnimator
extends Skeleton

const animation_export_path: String = "res://models/hand/animations/"

var previous_data: Array = null

enum SIDE {LEFT, RIGHT}
enum FINGER {THUMB, INDEX, MIDDLE, RING, PINK}
enum BONE {METACARPAL, PROXIMAL, INTERMEDIATE, DISTAL, TIP}
enum AXIS {X, Y, Z}
export(FINGER) var using_finger: int = FINGER.INDEX
export(BONE) var using_bone: int = BONE.INTERMEDIATE

const finger_names: Dictionary = {
	FINGER.THUMB: "Thumb",
	FINGER.INDEX: "Index",
	FINGER.MIDDLE: "Middle",
	FINGER.RING: "Ring",
	FINGER.PINK: "Little",
}

# Export functions
export(AXIS) var axis: int
export(float, -360.0, 360.0) var rotation_offset: float = 45.0
export var invert_rotation_offset: bool = false
export var apply_rotation: bool = false setget ex_apply_rotation
export var animation_player: NodePath
export var set_to_animation_start: bool = false setget ex_anim_start
export var set_to_animation_end: bool = false setget ex_anim_end
export var copy_data: bool = false setget ex_copy
export var paste_data: bool = false setget ex_paste
export var reset_to_left_default: bool = false setget ex_reset_left
export var reset_to_right_default: bool = false setget ex_reset_right
export var undo: bool = false setget ex_undo
export var export_animations: bool = false setget ex_export
export var export_name: String
export(SIDE) var export_side: int

func ex_export(value: bool):
	if not value:
		return
	
	if export_name.strip_edges().empty():
		print("Export name is empty")
		return
	elif not has_node(animation_player):
		print("No AnimationPlayer set")
		return
	
	var player: AnimationPlayer = get_node(animation_player)
	
	# Ensure save directory exists
	var dir: Directory = Directory.new()
	var path: String = animation_export_path.plus_file(export_name).plus_file("left" if export_side == SIDE.LEFT else "right")
	if not dir.dir_exists(path):
		dir.make_dir_recursive(path)
	dir = null
	
	for finger in FINGER.values():
		if player.has_animation(finger_names[finger]):
			ResourceSaver.save(path.plus_file(str(finger) + ".tres"), player.get_animation(finger_names[finger]))
			print("Exported to ", path.plus_file(str(finger) + ".tres"))

func ex_apply_rotation(value: bool):
	if not value:
		return
	
	for bone in get_bone_count():
		
		var name: String = get_bone_name(bone)
		if name.begins_with(finger_names[using_finger]) and BONE.keys()[using_bone].to_lower() in name.to_lower():
			
			var pose: Transform = get_bone_pose(bone)
			var axis_vector: Vector3 = Vector3.ZERO
			axis_vector[AXIS.keys()[axis].to_lower()] = 1
			
			previous_data = get_data()
			
			set_bone_pose(bone, pose.rotated(axis_vector, deg2rad(rotation_offset) * (-1.0 if invert_rotation_offset else 1.0)))
	
			print("Applied rotation offset")
			return
	
	print("Couldn't apply rotation offset")

func ex_anim_start(value: bool, end: bool = false):
	if not value:
		return
	
	if not has_node(animation_player):
		print("No AnimationPlayer set")
		return
	
	var player: AnimationPlayer = get_node(animation_player)
	var animation: Animation
	var finger: String = finger_names[using_finger]
	
	if player.has_animation(finger):
		animation = player.get_animation(finger)
	else:
		animation = Animation.new()
		animation.length = 1.0
		
		for bone in get_bone_count():
			if not get_bone_name(bone).begins_with(finger):
				continue
			
			var track: int = animation.add_track(Animation.TYPE_TRANSFORM)
			animation.track_set_path(track, str(get_parent().get_path_to(self)) + ":" + get_bone_name(bone))
		
		player.add_animation(finger, animation)
	
	for bone in get_bone_count():
		if not get_bone_name(bone).begins_with(finger):
			continue
		
		var track: int = animation.find_track(str(get_parent().get_path_to(self)) + ":" + get_bone_name(bone))
		
		var key_to_set: int = -1
		for key in animation.track_get_key_count(track):
			if animation.track_get_key_time(track, key) == (1.0 if end else 0.0):
				key_to_set = key
				break
		
		var pose: Transform = get_bone_pose(bone)
		var key_value: Dictionary = {
			"location": pose.origin, 
			"rotation": pose.basis.get_rotation_quat(),
			"scale": pose.basis.get_scale()
		}

		if key_to_set < 0:
			animation.track_insert_key(track, 1.0 if end else 0.0, key_value)
		else:
			animation.track_set_key_value(track, key_to_set, key_value)

func ex_anim_end(value: bool):
	ex_anim_start(value, true)

func ex_copy(value: bool):
	if not value:
		return
	
	OS.set_clipboard(var2str(get_data()))
	print("Copied data")

func ex_paste(value: bool):
	if not value:
		return
	
	previous_data = get_data()
	set_data(str2var(OS.get_clipboard()))
	print("Pasted data")

func ex_reset_left(value: bool, right: bool = false):
	if not value:
		return
	
	previous_data = get_data()
	
	set_data(str2var(default_data[SIDE.RIGHT if right else SIDE.LEFT].replace("'", '"')))
	
	print("Reset to ", "right" if right else "left", " default")

func ex_reset_right(value: bool):
	ex_reset_left(value, true)

func ex_undo(value: bool):
	if not value:
		return
	
	if not previous_data:
		print("No undo data stored")
	else:
		var data: Array = get_data()
		set_data(previous_data)
		previous_data = data
		print("Undid")

func get_data() -> Array:
	
	var ret: Array = []
	for bone in get_bone_count():
		
		ret.append({
			"rest": get_bone_rest(bone),
			"pose": get_bone_pose(bone),
			"rest_disabled": is_bone_rest_disabled(bone),
		})
	
	return ret

func set_data(data: Array):
	for bone in len(data):
		set_bone_rest(bone, data[bone]["rest"])
		set_bone_pose(bone, data[bone]["pose"])
		set_bone_disable_rest(bone, data[bone]["rest_disabled"])

const default_data: Dictionary = {
	SIDE.RIGHT: """[ {
"pose": Transform( 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0 ),
"rest": Transform( 0, 1, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0 ),
"rest_disabled": false
}, {
"pose": Transform( 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0 ),
"rest": Transform( 0.0177277, -0.780951, 0.62434, 0.937346, 0.230287, 0.261438, -0.347948, 0.580588, 0.736104, -0.029178, -0.0179138, -0.0252983 ),
"rest_disabled": false
}, {
"pose": Transform( 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0 ),
"rest": Transform( 0.999996, 0.000557879, -0.00268927, 0.000794155, 0.878596, 0.477564, 0.00262921, -0.477565, 0.878592, -2.8248e-07, 3.17944e-08, -0.0404058 ),
"rest_disabled": false
}, {
"pose": Transform( 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0 ),
"rest": Transform( 0.999996, -0.000623179, 0.00274269, -0.00023728, 0.952977, 0.303043, -0.00280257, -0.303043, 0.952973, 4.99587e-07, 2.52726e-07, -0.0325173 ),
"rest_disabled": false
}, {
"pose": Transform( 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0 ),
"rest": Transform( 1, 2.8871e-08, 4.65661e-09, -2.8871e-08, 1, 3.25963e-09, -4.65661e-09, -3.25963e-09, 1, -6.42496e-07, -1.20653e-06, -0.0304639 ),
"rest_disabled": false
}, {
"pose": Transform( 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0 ),
"rest": Transform( 0.964, -0.146, 0.221, 0.186, 0.968, -0.053, -0.189, 0.206, 0.96, -0.021, -0.002, -0.015 ),
"rest_disabled": false
}, {
"pose": Transform( 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0 ),
"rest": Transform( 0.994, 0.022, -0.103, 0.029, 0.883, 0.245, 0.102, -0.468, 0.878, 0, 0, -0.074 ),
"rest_disabled": false
}, {
"pose": Transform( 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0 ),
"rest": Transform( 1, -0.002, 0.01, -0.002, 0.932, 0.005, -0.01, -0.363, 0.932, 0, 0, -0.043 ),
"rest_disabled": false
}, {
"pose": Transform( 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0 ),
"rest": Transform( 0.999997, 0.000115875, -0.00232981, 0.000240702, 0.988308, 0.152468, 0.00232024, -0.152468, 0.988306, 1.74279e-07, -4.84116e-07, -0.0282749 ),
"rest_disabled": false
}, {
"pose": Transform( 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0 ),
"rest": Transform( 1, -5.21541e-08, 8.19564e-08, 5.21541e-08, 1, -2.95229e-07, -8.19564e-08, 2.95229e-07, 1, -7.40401e-08, -1.43424e-07, -0.0228214 ),
"rest_disabled": false
}, {
"pose": Transform( 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0 ),
"rest": Transform( 0.996362, -0.0785602, 0.0330307, 0.083606, 0.97618, -0.200207, -0.0165156, 0.20224, 0.979197, -0.00711951, 0.0021773, -0.0163189 ),
"rest_disabled": false
}, {
"pose": Transform( 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0 ),
"rest": Transform( 1, 8.501e-05, -0.000361163, 8.50438e-05, 0.894969, 0.446129, 0.000361155, -0.446128, 0.894969, 2.82672e-08, -8.90363e-08, -0.0708864 ),
"rest_disabled": false
}, {
"pose": Transform( 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0 ),
"rest": Transform( 1, 0.001, -0.007, 0.001, 0.95, 0.057, 0.007, -0.311, 0.95, 0, 0, -0.043 ),
"rest_disabled": false
}, {
"pose": Transform( 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0 ),
"rest": Transform( 0.999966, -0.00095298, 0.00819843, -0.00137834, 0.960082, 0.279716, -0.00813773, -0.279718, 0.960048, 1.32807e-08, 9.12432e-07, -0.033266 ),
"rest_disabled": false
}, {
"pose": Transform( 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0 ),
"rest": Transform( 1, 6.98492e-09, 1.39698e-09, -6.98492e-09, 1, 4.19444e-07, -1.39698e-09, -4.19444e-07, 1, 5.58794e-09, 9.09495e-08, -0.0258924 ),
"rest_disabled": false
}, {
"pose": Transform( 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0 ),
"rest": Transform( 0.99457, 0.025077, -0.101005, -0.0390913, 0.989484, -0.139257, 0.096451, 0.14245, 0.985092, 0.00654516, 0.000513446, -0.0163477 ),
"rest_disabled": false
}, {
"pose": Transform( 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0 ),
"rest": Transform( 0.996643, 0.0198081, -0.0794323, 0.0162945, 0.902873, 0.429598, 0.0802268, -0.429451, 0.89952, -6.75946e-08, -3.38796e-07, -0.0659752 ),
"rest_disabled": false
}, {
"pose": Transform( 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0 ),
"rest": Transform( 1, -0.001, 0.005, -0.001, 0.964, 0.002, -0.005, -0.265, 0.964, 0, 0, -0.04 ),
"rest_disabled": false
}, {
"pose": Transform( 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0 ),
"rest": Transform( 0.999964, 0.000760279, -0.00850133, 0.00154782, 0.963358, 0.268215, 0.00839374, -0.268218, 0.963322, 1.26099e-07, 2.36287e-07, -0.0284901 ),
"rest_disabled": false
}, {
"pose": Transform( 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0 ),
"rest": Transform( 1, 1.01514e-07, 1.95577e-08, -1.01514e-07, 1, -5.76023e-07, -1.95578e-08, 5.76023e-07, 1, -9.96516e-08, -1.50595e-06, -0.0224277 ),
"rest_disabled": false
}, {
"pose": Transform( 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0 ),
"rest": Transform( 0.927157, 0.22841, -0.296999, -0.240122, 0.970738, -0.00304433, 0.287613, 0.0741386, 0.954873, 0.0189813, -0.00247817, -0.0152136 ),
"rest_disabled": false
}, {
"pose": Transform( 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0 ),
"rest": Transform( 0.998382, -0.0140467, 0.0550918, 0.00161984, 0.975633, 0.219401, -0.0568312, -0.218957, 0.974078, 2.16701e-08, 5.01389e-08, -0.0628552 ),
"rest_disabled": false
}, {
"pose": Transform( 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0 ),
"rest": Transform( 0.999737, 0.00227805, -0.0228097, 0.00379467, 0.964875, 0.262682, 0.0226069, -0.262699, 0.964613, 2.50406e-07, -1.50485e-07, -0.0298734 ),
"rest_disabled": false
}, {
"pose": Transform( 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0 ),
"rest": Transform( 0.999677, -0.00168805, 0.0253695, -0.00382892, 0.97642, 0.215847, -0.0251357, -0.215874, 0.976098, -2.88622e-07, 2.54939e-07, -0.0179782 ),
"rest_disabled": false
}, {
"pose": Transform( 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0 ),
"rest": Transform( 1, -1.2666e-07, 3.19363e-15, 1.2666e-07, 1, -8.61473e-08, 7.71779e-15, 8.61473e-08, 1, -6.42613e-08, -2.98023e-08, -0.018018 ),
"rest_disabled": false
}, {
"pose": Transform( 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0 ),
"rest": Transform( 0.996362, -0.0785602, 0.0330307, 0.083606, 0.97618, -0.200207, -0.0165157, 0.20224, 0.979197, -0.00829025, 0.00927338, -0.0510245 ),
"rest_disabled": false
} ]""",
SIDE.LEFT: """[ {
"pose": Transform( 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0 ),
"rest": Transform( 0, 1, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0 ),
"rest_disabled": false
}, {
"pose": Transform( 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0 ),
"rest": Transform( 0.0177277, -0.780951, 0.62434, 0.937346, 0.230287, 0.261438, -0.347948, 0.580588, 0.736104, -0.029178, -0.0179138, -0.0252983 ),
"rest_disabled": false
}, {
"pose": Transform( 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0 ),
"rest": Transform( 0.999996, 0.000557879, -0.00268927, 0.000794155, 0.878596, 0.477564, 0.00262921, -0.477565, 0.878592, -2.8248e-07, 3.17944e-08, -0.0404058 ),
"rest_disabled": false
}, {
"pose": Transform( 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0 ),
"rest": Transform( 0.999996, -0.000623179, 0.00274269, -0.00023728, 0.952977, 0.303043, -0.00280257, -0.303043, 0.952973, 4.99587e-07, 2.52726e-07, -0.0325173 ),
"rest_disabled": false
}, {
"pose": Transform( 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0 ),
"rest": Transform( 1, 2.8871e-08, 4.65661e-09, -2.8871e-08, 1, 3.25963e-09, -4.65661e-09, -3.25963e-09, 1, -6.42496e-07, -1.20653e-06, -0.0304639 ),
"rest_disabled": false
}, {
"pose": Transform( 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0 ),
"rest": Transform( 0.964, -0.146, 0.221, 0.186, 0.968, -0.053, -0.189, 0.206, 0.96, -0.021, -0.002, -0.015 ),
"rest_disabled": false
}, {
"pose": Transform( 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0 ),
"rest": Transform( 0.994, 0.022, -0.103, 0.029, 0.883, 0.245, 0.102, -0.468, 0.878, 0, 0, -0.074 ),
"rest_disabled": false
}, {
"pose": Transform( 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0 ),
"rest": Transform( 1, -0.002, 0.01, -0.002, 0.932, 0.005, -0.01, -0.363, 0.932, 0, 0, -0.043 ),
"rest_disabled": false
}, {
"pose": Transform( 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0 ),
"rest": Transform( 0.999997, 0.000115875, -0.00232981, 0.000240702, 0.988308, 0.152468, 0.00232024, -0.152468, 0.988306, 1.74279e-07, -4.84116e-07, -0.0282749 ),
"rest_disabled": false
}, {
"pose": Transform( 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0 ),
"rest": Transform( 1, -5.21541e-08, 8.19564e-08, 5.21541e-08, 1, -2.95229e-07, -8.19564e-08, 2.95229e-07, 1, -7.40401e-08, -1.43424e-07, -0.0228214 ),
"rest_disabled": false
}, {
"pose": Transform( 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0 ),
"rest": Transform( 0.996362, -0.0785602, 0.0330307, 0.083606, 0.97618, -0.200207, -0.0165156, 0.20224, 0.979197, -0.00711951, 0.0021773, -0.0163189 ),
"rest_disabled": false
}, {
"pose": Transform( 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0 ),
"rest": Transform( 1, 8.501e-05, -0.000361163, 8.50438e-05, 0.894969, 0.446129, 0.000361155, -0.446128, 0.894969, 2.82672e-08, -8.90363e-08, -0.0708864 ),
"rest_disabled": false
}, {
"pose": Transform( 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0 ),
"rest": Transform( 1, 0.001, -0.007, 0.001, 0.95, 0.057, 0.007, -0.311, 0.95, 0, 0, -0.043 ),
"rest_disabled": false
}, {
"pose": Transform( 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0 ),
"rest": Transform( 0.999966, -0.00095298, 0.00819843, -0.00137834, 0.960082, 0.279716, -0.00813773, -0.279718, 0.960048, 1.32807e-08, 9.12432e-07, -0.033266 ),
"rest_disabled": false
}, {
"pose": Transform( 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0 ),
"rest": Transform( 1, 6.98492e-09, 1.39698e-09, -6.98492e-09, 1, 4.19444e-07, -1.39698e-09, -4.19444e-07, 1, 5.58794e-09, 9.09495e-08, -0.0258924 ),
"rest_disabled": false
}, {
"pose": Transform( 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0 ),
"rest": Transform( 0.99457, 0.025077, -0.101005, -0.0390913, 0.989484, -0.139257, 0.096451, 0.14245, 0.985092, 0.00654516, 0.000513446, -0.0163477 ),
"rest_disabled": false
}, {
"pose": Transform( 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0 ),
"rest": Transform( 0.996643, 0.0198081, -0.0794323, 0.0162945, 0.902873, 0.429598, 0.0802268, -0.429451, 0.89952, -6.75946e-08, -3.38796e-07, -0.0659752 ),
"rest_disabled": false
}, {
"pose": Transform( 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0 ),
"rest": Transform( 1, -0.001, 0.005, -0.001, 0.964, 0.002, -0.005, -0.265, 0.964, 0, 0, -0.04 ),
"rest_disabled": false
}, {
"pose": Transform( 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0 ),
"rest": Transform( 0.999964, 0.000760279, -0.00850133, 0.00154782, 0.963358, 0.268215, 0.00839374, -0.268218, 0.963322, 1.26099e-07, 2.36287e-07, -0.0284901 ),
"rest_disabled": false
}, {
"pose": Transform( 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0 ),
"rest": Transform( 1, 1.01514e-07, 1.95577e-08, -1.01514e-07, 1, -5.76023e-07, -1.95578e-08, 5.76023e-07, 1, -9.96516e-08, -1.50595e-06, -0.0224277 ),
"rest_disabled": false
}, {
"pose": Transform( 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0 ),
"rest": Transform( 0.927157, 0.22841, -0.296999, -0.240122, 0.970738, -0.00304433, 0.287613, 0.0741386, 0.954873, 0.0189813, -0.00247817, -0.0152136 ),
"rest_disabled": false
}, {
"pose": Transform( 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0 ),
"rest": Transform( 0.998382, -0.0140467, 0.0550918, 0.00161984, 0.975633, 0.219401, -0.0568312, -0.218957, 0.974078, 2.16701e-08, 5.01389e-08, -0.0628552 ),
"rest_disabled": false
}, {
"pose": Transform( 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0 ),
"rest": Transform( 0.999737, 0.00227805, -0.0228097, 0.00379467, 0.964875, 0.262682, 0.0226069, -0.262699, 0.964613, 2.50406e-07, -1.50485e-07, -0.0298734 ),
"rest_disabled": false
}, {
"pose": Transform( 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0 ),
"rest": Transform( 0.999677, -0.00168805, 0.0253695, -0.00382892, 0.97642, 0.215847, -0.0251357, -0.215874, 0.976098, -2.88622e-07, 2.54939e-07, -0.0179782 ),
"rest_disabled": false
}, {
"pose": Transform( 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0 ),
"rest": Transform( 1, -1.2666e-07, 3.19363e-15, 1.2666e-07, 1, -8.61473e-08, 7.71779e-15, 8.61473e-08, 1, -6.42613e-08, -2.98023e-08, -0.018018 ),
"rest_disabled": false
}, {
"pose": Transform( 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0 ),
"rest": Transform( 0.996362, -0.0785602, 0.0330307, 0.083606, 0.97618, -0.200207, -0.0165157, 0.20224, 0.979197, -0.00829025, 0.00927338, -0.0510245 ),
"rest_disabled": false
} ]"""
}
