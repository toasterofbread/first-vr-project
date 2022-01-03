class_name GameObjectGrabbable
extends GameObject

signal point_grabbed(controller, point)
signal point_released(controller, point)

# Nodes
export(Array, NodePath) var grab_point_containers: Array = []
var collision_shapes: Dictionary = {}

# Constants
onready var original_data: Dictionary = {
	"parent": get_parent(),
	"collision_layer": 4,
	"collision_mask": 7
}

# Status
var grabbed: bool = false
var grab_points: Dictionary = {
	# grab_point: grabbing controller or null
}
var previous_transform: Transform = null
var monitored_velocity_linear: Vector3 = Vector3.ZERO
var monitored_velocity_angular: Vector3 = Vector3.ZERO
var collision_exception_times: Dictionary = {}

func _process(_delta: float):
	
	# While grabbed, monitor velocity so that it can be used when released 
	if grabbed:
		if not previous_transform:
			previous_transform = global_transform
		else:
			monitored_velocity_linear = global_transform.origin - previous_transform.origin
			monitored_velocity_angular = global_transform.basis.y - previous_transform.basis.y
			previous_transform = global_transform

func _ready():
	
	# Set physics parameters
	collision_layer = original_data["collision_layer"]
	collision_mask = original_data["collision_mask"]
	continuous_cd = true
	can_sleep = false
	
	# Register GrabPoints that are children of self and any specified containers
	for nodepath in ["."] + grab_point_containers:
		for node in get_node(nodepath).get_children():
			if node is GameObjectGrabPoint:
				grab_points[node] = null
				node.host_object = self
				node.connect("grabbed", self, "point_grabbed", [node])
				node.connect("released", self, "point_released", [node])
	
	# Register CollisionShapes and CollisionPolygons
	for node in get_children():
		if node is CollisionShape or node is CollisionPolygon:
			collision_shapes[node] = node.transform

# Called when a GrabPoint of this object is grabbed
func point_grabbed(controller, point):
	grabbed = true
	grab_points[point] = controller
	
	# Disable rigidbody physics
	collision_layer = 0
	collision_mask = 0
	mode = MODE_STATIC
	
	# Make the controller the parent of self
	Utils.reparent_node(self, controller.hand_rigidbody)
	
	translation = point.hand_transform.inverse().origin * scale
	rotation = point.hand_transform.basis.get_euler()
	
	for collisionshape in collision_shapes:
		var position: Vector3 = to_local(collisionshape.global_transform.origin)
		Utils.reparent_node(collisionshape, controller.hand_rigidbody)
		collisionshape.global_transform.origin = to_global(position)
		collisionshape.rotation += rotation
	
	emit_signal("point_grabbed", controller, point)

# Called when a GrabPoint of this object is released
func point_released(controller, point):
	grab_points[point] = null
	
	# Update grabbed status
	grabbed = false
	for grab_point in grab_points:
		if grab_points[grab_point]:
			grabbed = true
			break
	
	# Re-enable collision and rigidbody physics
	collision_layer = original_data["collision_layer"]
	collision_mask = original_data["collision_mask"]
	mode = MODE_RIGID
	
	# Apply the monitored velocity to the rigidbody physics
#	linear_velocity = monitored_velocity_linear * 30
#	angular_velocity = monitored_velocity_angular * 30
	linear_velocity = controller.hand_rigidbody.linear_velocity
	angular_velocity = controller.hand_rigidbody.angular_velocity
	
	for collisionshape in collision_shapes:
		Utils.reparent_node(collisionshape, self)
		collisionshape.transform = collision_shapes[collisionshape]
	
	# Return to original parent
	var transform: Transform = global_transform
	Utils.reparent_node(self, original_data["parent"])
	global_transform = transform
	
	# Add a brief collision exception for this object to the hand
	controller.hand_rigidbody.add_collision_exception_with(self)
	var time: int = OS.get_ticks_msec()
	collision_exception_times[controller] = time
	yield(get_tree().create_timer(0.5), "timeout")
	if collision_exception_times[controller] == time:
		controller.hand_rigidbody.remove_collision_exception_with(self)
	
	emit_signal("point_released", controller, point)

