tool
class_name Controller
extends ARVRController

# Signals
signal finger_position_changed(finger, position)

# Enums
enum SIDE {LEFT, RIGHT}

# Constants
var hand_models: Dictionary = {
#	SIDE.LEFT: preload("res://models/hand/HandLeft.tscn"),
	SIDE.LEFT: preload("res://models/hand/HandRight.tscn"),
	SIDE.RIGHT: preload("res://models/hand/HandRight.tscn"),
}
const finger_animation_duration: float = 0.1
var animations: Dictionary = {}

# Nodes
onready var anchor: Node = Utils.anchor
onready var player: Player = get_node(player_path_export)
var finger_tweens: Dictionary = {}
var hand: Spatial = null
var hand_skeleton: Skeleton = null
var hand_rigidbody: RigidBody = null

# Exports
export var player_path_export: NodePath
export(SIDE) var side: int setget set_side

# Status
var grabbed_point: GameObjectGrabPoint = null
var finger_positions: Dictionary = {}
var finger_override: Dictionary = {
#	Enums.FINGER.INDEX: Enums.FINGER.MIDDLE,
#	Enums.FINGER.MIDDLE: Enums.FINGER.INDEX,
}
var _dummy: float = 0.0

# Unneeded?
var previous_transform: Transform = null
var velocity_linear: Vector3 = Vector3.ZERO
var velocity_angular: Vector3 = Vector3.ZERO

func _ready():
	
	if Engine.editor_hint:
		return
	
	for finger in Enums.FINGER.values():
		# Add finger to finger_positions
		finger_positions[finger] = 0.0
		
		# Create tween for finger and register to finger_tweens
		var tween: Tween = Tween.new()
		finger_tweens[finger] = tween
		add_child(tween)
		tween.connect("tween_step", self, "finger_tween_step", [finger])
	
	# Load animations
	var side_string: String = "left" if side == SIDE.LEFT else "right"
	for animation in Utils.get_dir_items("res://models/hand/animations/"):
		
		animations[animation] = {}
		var items = Utils.get_dir_items("res://models/hand/animations/".plus_file(animation).plus_file(side_string))
		if items is int:
			break
		for finger in items:
			animations[animation][int(finger.split(".")[0])] = load("res://models/hand/animations/".plus_file(animation).plus_file(side_string).plus_file(finger))
	
	connect("button_pressed", self, "on_button_pressed")
	connect("button_release", self, "on_button_released")
	
	if hand and hand.get_parent() != anchor:
		# Move hand to global anchor
		hand_rigidbody.mode = RigidBody.MODE_RIGID
		var hand_transform: Transform = hand.global_transform
		Utils.reparent_node(hand, anchor)
		hand.global_transform = hand_transform

func _process(delta: float):
	
	if Engine.editor_hint:
		return
	
	if not previous_transform:
		previous_transform = global_transform
	else:
		velocity_linear = global_transform.origin - previous_transform.origin
		velocity_angular = global_transform.basis.y - previous_transform.basis.y
		
		previous_transform = global_transform
	
	if is_button_pressed(Enums.CONTROLLER_BUTTON.TOUCH_INDEX_TRIGGER):
		set_finger_position(Enums.FINGER.INDEX, 0.3 + (0.7 * ((get_joystick_axis(Enums.CONTROLLER_AXIS.INDEX_TRIGGER) + 1.0) / 2.0)))
	
	var grip_magnitude: float = (get_joystick_axis(Enums.CONTROLLER_AXIS.GRIP_TRIGGER) + 1.0) / 2.0
	set_finger_position(Enums.FINGER.MIDDLE, grip_magnitude)
	set_finger_position(Enums.FINGER.RING, grip_magnitude)
	set_finger_position(Enums.FINGER.PINK, grip_magnitude)

func _physics_process(delta: float):
	
	if Engine.editor_hint:
		return
	
	var linear_velocity: Vector3 = (global_transform.origin - hand_rigidbody.global_transform.origin) / delta
#	rigidbody.linear_velocity = rigidbody.linear_velocity.move_toward(linear_velocity, max_position_change * delta)
	if Utils.is_number_normal(linear_velocity.x):
		hand_rigidbody.vel = linear_velocity
#		hand_rigidbody.linear_velocity = linear_velocity
	
	# IDK?
	
	var diff: Vector3 = ((global_transform.basis.get_rotation_quat() * Quat(Vector3(PI/2, 0, 0))) * hand_rigidbody.global_transform.basis.get_rotation_quat().inverse()).get_euler()
	var angular_velocity: Vector3 = diff / delta
	if Utils.is_number_normal(angular_velocity.x):
#		rigidbody.angular_velocity = rigidbody.angular_velocity.move_toward(angular_velocity, max_rotation_change * delta)
#		hand_rigidbody.angular_velocity = angular_velocity
		hand_rigidbody.ang = angular_velocity

func set_side(value: int):
	side = value
	
	if is_inside_tree():
		$GrabArea/CollisionShape.translation.x = abs($GrabArea/CollisionShape.translation.x) * (-1 if side == SIDE.RIGHT else 1)
	
	# Add hand model
	if hand:
		hand.queue_free()
		hand = null
	
	hand = hand_models[side].instance()
	add_child(hand)
	hand_skeleton = hand.get_held_node("skeleton")
	hand_rigidbody = hand.get_held_node("rigidbody")
	
	if Engine.editor_hint:
		controller_id = side + 1
	elif is_inside_tree():
		# Move hand to global anchor
		hand_rigidbody.mode = RigidBody.MODE_RIGID
		var hand_transform: Transform = hand.global_transform
		Utils.reparent_node(hand, anchor)
		hand.global_transform = hand_transform

func get_joystick_vector() -> Vector2:
	return Vector2(get_joystick_axis(Enums.CONTROLLER_AXIS.JOYSTICK_X), get_joystick_axis(Enums.CONTROLLER_AXIS.JOYSTICK_Y))

func on_finger_position_changed(_finger: int, _position: float):
	
	if grabbed_point and grabbed_point.grabbed_by != self:
		grabbed_point = null
	
	if grabbed_point:
		if not grabbed_point.can_be_grabbed(self):
			grabbed_point.release(self)
			grabbed_point = null
			animation_changed()
	else:
		for grab_point in $GrabArea.get_overlapping_areas():
			if grab_point is GameObjectGrabPoint and grab_point.can_be_grabbed(self):
				
				grabbed_point = grab_point
				grabbed_point.grab(self)
				animation_changed()
				break
	
	emit_signal("finger_position_changed", _finger, _position)

func set_finger_position(finger: int, target_position: float, instant: bool = false):
	
	if finger in finger_override:
		finger = finger_override[finger]
	
	if instant:
		finger_positions[finger] = target_position
		finger_tween_step(null, null, null, target_position, finger)
	else:
		var tween: Tween = finger_tweens[finger]
		tween.interpolate_property(self, "_dummy", finger_positions[finger], target_position, abs(target_position - finger_positions[finger]) * finger_animation_duration)
		tween.start()

func animation_changed():
	for finger in Enums.FINGER.values():
		finger_tween_step(null, null, null, finger_positions[finger], finger)

func finger_tween_step(_object: Object, _key: NodePath, _elapsed: float, position, finger: int):
	if is_nan(position):
		return
	
	finger_positions[finger] = position
	
	if not finger in animations["default"]:
#		# TEMP
#		var bones: Dictionary = finger_values[finger]
#		for bone in bones:
#			for mutation in bones[bone]:
#
#				var rotate_by: float = deg2rad(lerp(mutation["initial"], mutation["final"], position))
#				if controller.side == Controller.SIDE.LEFT and mutation["axis"].y == 1:
#					rotate_by *= -1
#
#				skeleton.set_bone_pose(bone, base_pose.rotated(mutation["axis"], rotate_by))
		return
	else:
	
		var animation: Animation = animations["default" if grabbed_point == null else grabbed_point.hand_animation_id][finger]
		
		for track in animation.get_track_count():
			
	#		"location": pose.origin, 
	#		"rotation": pose.basis.get_rotation_quat(),
	#		"scale": pose.basis.get_scale()
			
			# TODO: Pre-cache bone IDs in a dictionary
			var bone: int = hand_skeleton.find_bone(animation.track_get_path(track).get_concatenated_subnames())
			
			var pose_data: Array = animation.transform_track_interpolate(track, position)
			hand_skeleton.set_bone_pose(bone, Transform(Basis(pose_data[1]).scaled(pose_data[2]), pose_data[0]))
	
	on_finger_position_changed(finger, position)

func on_button_pressed(button: int):
	match button:
		Enums.CONTROLLER_BUTTON.TOUCH_INDEX_TRIGGER:
			set_finger_position(Enums.FINGER.INDEX, 0.3)
		Enums.CONTROLLER_BUTTON.TOUCH_AX, Enums.CONTROLLER_BUTTON.TOUCH_BY, Enums.CONTROLLER_BUTTON.TOUCH_THUMB_UP, Enums.CONTROLLER_BUTTON.AX, Enums.CONTROLLER_BUTTON.BY, Enums.CONTROLLER_BUTTON.STICK:
			update_thumb_position()
#		Enums.CONTROLLER_BUTTON.INDEX_TRIGGER:
#			set_finger_position(Enums.FINGER.INDEX, 1.0)

func on_button_released(button: int):
	match button:
		Enums.CONTROLLER_BUTTON.TOUCH_INDEX_TRIGGER:
			set_finger_position(Enums.FINGER.INDEX, 0.0)
		Enums.CONTROLLER_BUTTON.TOUCH_AX, Enums.CONTROLLER_BUTTON.TOUCH_BY, Enums.CONTROLLER_BUTTON.TOUCH_THUMB_UP, Enums.CONTROLLER_BUTTON.AX, Enums.CONTROLLER_BUTTON.BY, Enums.CONTROLLER_BUTTON.STICK:
			update_thumb_position()

func update_thumb_position():
	if is_button_pressed(Enums.CONTROLLER_BUTTON.AX) or is_button_pressed(Enums.CONTROLLER_BUTTON.BY) or is_button_pressed(Enums.CONTROLLER_BUTTON.STICK) or is_button_pressed(Enums.CONTROLLER_BUTTON.TOUCH_AX) or is_button_pressed(Enums.CONTROLLER_BUTTON.TOUCH_BY) or not is_button_pressed(Enums.CONTROLLER_BUTTON.TOUCH_THUMB_UP):
		set_finger_position(Enums.FINGER.THUMB, 1.0)
	else:
		set_finger_position(Enums.FINGER.THUMB, 0.0)
