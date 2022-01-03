tool
class_name GameObjectGrabPoint
extends Area

signal grabbed(controller)
signal released(controller)
signal finger_position_changed(finger, position)

export var connect_finger_changed_signal: bool = false
export var hand_path: NodePath
export var get_hand_transform: bool = false setget ex_get_hand_transform
export var hand_transform: Transform
export var hand_animation_id: String = "default"
export var grab_thresholds: Dictionary = {
	Enums.FINGER.THUMB: -1,
	Enums.FINGER.INDEX: 0.7,
	Enums.FINGER.MIDDLE: 0.7,
	Enums.FINGER.RING: 0.7,
	Enums.FINGER.PINK: 0.7
}
export(Array, NodePath) var must_be_grabbed_after: Array = []

var host_object: Node = null #: GameObjectGrabbable
var grabbed_by: Node = null #: Controller

func ex_get_hand_transform(value: bool):
	
	if not value:
		return
	
	if not has_node(hand_path):
		print("No hand path set")
		return
	
	hand_transform = get_node(hand_path).transform

func _ready():
	
	if Engine.editor_hint:
		return
	
	for i in len(must_be_grabbed_after):
		must_be_grabbed_after[i] = get_node(must_be_grabbed_after[i])
	
	collision_layer = 8
	collision_mask = 0
	monitoring = false
	
	var collision_shape: CollisionShape = CollisionShape.new()
	collision_shape.shape = SphereShape.new()
	collision_shape.shape.radius = 0.05
	add_child(collision_shape)

func can_be_grabbed(controller) -> bool:
	
	for grab_point in must_be_grabbed_after:
		if not grab_point.is_grabbed():
			return false
	
	for finger in grab_thresholds:
		if grab_thresholds[finger] >= 0 and controller.finger_positions[finger] >= grab_thresholds[finger]:
			return true
	
	return false

func is_grabbed() -> bool:
	return grabbed_by != null

func grab(controller: Node):
	grabbed_by = controller
	if connect_finger_changed_signal:
		controller.connect("finger_position_changed", self, "on_finger_position_changed")
	emit_signal("grabbed", controller)

func release(controller: Node):
	grabbed_by = null
	if controller.is_connected("finger_position_changed", self, "on_finger_position_changed"):
		controller.disconnect("finger_position_changed", self, "on_finger_position_changed")
	emit_signal("released", controller)

func on_finger_position_changed(finger: int, position: float):
	emit_signal("finger_position_changed", finger, position)
