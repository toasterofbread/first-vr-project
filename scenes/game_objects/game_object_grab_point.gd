tool
class_name GameObjectGrabPoint
extends Area

signal grabbed(controller)
signal released(controller)
signal finger_position_changed(finger, position)

export var hand_position_id: String = "default"
export var hand_animation_id: String = "default"
export var connect_finger_changed_signal: bool = false
#export var left_hand_path: NodePath
#export var right_hand_path: NodePath
#var hand_nodes: Dictionary
#export var ex_get_hand_transform: bool = false setget ex_get_hand_transform
#export var hand_transforms: Dictionary = {0: Transform(), 1: Transform()} # Enums.SIDE.X
export var grab_thresholds: Dictionary = {
	Enums.FINGER.THUMB: -1,
	Enums.FINGER.INDEX: 0.7,
	Enums.FINGER.MIDDLE: 0.7,
	Enums.FINGER.RING: 0.7,
	Enums.FINGER.PINK: 0.7
}
export(Array, NodePath) var must_be_grabbed_after: Array = []
export var always_move_controller: bool = false
export var host_object_override: NodePath

var host_object: Node = null #: GameObjectGrabbable
var grabbed_by: Node = null #: Controller

var indicator_visible: bool = false setget set_indicator_visible
var indicator: MeshInstance = null

#func ex_get_hand_transform(value: bool):
#
#	if not value:
#		return
#
#	if has_node(left_hand_path):
#		hand_nodes[Enums.SIDE.LEFT] = get_node(left_hand_path)
#	if has_node(right_hand_path):
#		hand_nodes[Enums.SIDE.RIGHT] = get_node(right_hand_path)

func _ready():
	
	if Engine.editor_hint:
		return
	
	for i in len(must_be_grabbed_after):
		must_be_grabbed_after[i] = get_node(must_be_grabbed_after[i])
	
	collision_layer = 8
	collision_mask = 0
	monitoring = false
	
	# Create CollisionShape
	var collision_shape: CollisionShape = CollisionShape.new()
	collision_shape.shape = SphereShape.new()
	collision_shape.shape.radius = 0.05
	add_child(collision_shape)
	
	# Create indicator mesh
	indicator = MeshInstance.new()
	add_child(indicator)
	indicator.global_transform.basis = Basis(transform.basis.get_rotation_quat())
	
	indicator.mesh = SphereMesh.new()
	indicator.mesh.radius = 0.01
	indicator.mesh.height = indicator.mesh.radius * 2
	
	var material: SpatialMaterial = SpatialMaterial.new()
	material.flags_transparent = true
	material.flags_unshaded = true
	material.flags_no_depth_test = true
	material.albedo_color = Color.green
	material.albedo_color.a = 0.5
	indicator.mesh.material = material
	
	if has_node(host_object_override):
		host_object = get_node(host_object_override)
	
#	hand_nodes[Enums.SIDE.LEFT] = get_node(left_hand_path) if has_node(left_hand_path) else Spatial.new()
#	hand_nodes[Enums.SIDE.RIGHT] = get_node(right_hand_path) if has_node(right_hand_path) else Spatial.new()

func _notification(what: int):
	
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		# Reset indicator global scale
		indicator.global_transform.basis = Basis()

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

func grabbed(controller: Node):
	grabbed_by = controller
	if connect_finger_changed_signal:
		controller.connect("finger_position_changed", self, "on_finger_position_changed")
	emit_signal("grabbed", controller)

func released(controller: Node):
	grabbed_by = null
	if controller.is_connected("finger_position_changed", self, "on_finger_position_changed"):
		controller.disconnect("finger_position_changed", self, "on_finger_position_changed")
	emit_signal("released", controller)

func get_hand_grabbed_transform(controller) -> Dictionary:
#	ret.basis = ret.basis.scaled(ret.basis.inverse().get_scale()).scaled(host_object.global_transform.basis.get_scale())
	
	
#	ret.basis = ret.basis.rotated()
	
#	ret.origin = controller.hand_rigidbody.global_transform.origin# + (hand_transform.inverse().origin * host_object.scale)
	
#	var hand_transform: Transform = hand_transforms[controller.side]
#	var ret: Transform = controller.hand_rigidbody.global_transform
#	ret = ret.translated(hand_transform.inverse().origin * host_object.global_transform.basis.get_scale())
#
#	ret = ret.translated(Vector3(3 * (-1 if controller.side == Enums.SIDE.LEFT else 1), 4.5, 8.5) / host_object.global_transform.basis.get_scale() * 0.007)
	
	
#	var hand_transform: Transform = hand_nodes[controller.side].transform
#	var ret: Transform = controller.hand_rigidbody.global_transform
#	ret = ret.translated(hand_transform.origin * Vector3(1, -1, 1) * host_object.global_transform.basis.get_scale())
#	ret.basis = Basis(controller.hand_rigidbody.global_transform.basis.get_rotation_quat() * hand_transform.basis.get_rotation_quat().inverse()).scaled(host_object.global_transform.basis.get_scale())
	
#	return {"global_transform": ret, "local_translation_offset": Vector3.ZERO, "sc": host_object.global_transform.basis.get_scale() }
	return {}

func on_finger_position_changed(finger: int, position: float):
	emit_signal("finger_position_changed", finger, position)

func set_indicator_visible(value: bool):
	indicator_visible = value
	if indicator:
		indicator.visible = indicator_visible
