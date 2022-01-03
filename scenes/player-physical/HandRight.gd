extends ARVRController



# Physics values
const slow_down_velocity_linear: float = 0.75
const slow_down_velocity_angular: float = 0.75
const max_position_change: float = 75.0
const max_rotation_change: float = 75.0

# Status
var grabbed_point: GameObjectGrabPoint = null
var physics_activation_area_entered_bodies: Array = []

var just_changed: bool = false

func _physics_process(delta: float):
	
	print(MODE.keys()[mode])
	
	if mode == MODE.DIRECT:
		if not is_holding_object() and not physics_activation_area.get_overlapping_bodies().empty():
			set_mode(MODE.PHYSICAL)
	else: # mode == MODE.PHYSICAL
		var linear_velocity: Vector3 = get_new_linear_velocity() / delta
#		rigidbody.linear_velocity = rigidbody.linear_velocity.move_toward(linear_velocity, max_position_change * delta)
		if is_velocity_valid(linear_velocity.x):
			hand_rigidbody.linear_velocity = linear_velocity
		
		# IDK?
		var angular_velocity: Vector3 = get_new_angular_velocity() / delta
		if is_velocity_valid(angular_velocity.x):
#			rigidbody.angular_velocity = rigidbody.angular_velocity.move_toward(angular_velocity, max_rotation_change * delta)
			hand_rigidbody.angular_velocity = angular_velocity

func is_velocity_valid(value: float) -> bool:
	return not is_nan(value) and not is_inf(value)

func get_new_linear_velocity() -> Vector3:
	return global_transform.origin - hand_rigidbody.global_transform.origin

func get_new_angular_velocity() -> Vector3:
	
	var diff: Quat = global_transform.basis.get_rotation_quat() * hand_rigidbody.global_transform.basis.get_rotation_quat().inverse()
	
	var euler: Vector3 = diff.get_euler()
	
	return euler

func is_holding_object() -> bool:
	return grabbed_point != null

func set_mode(value: int):
	
	mode = value
	
	match mode:
		MODE.DIRECT:
			if hand.get_parent() != self:
				hand_rigidbody.mode = RigidBody.MODE_STATIC
				Utils.reparent_node(hand, self, true)
				just_changed = true
		MODE.PHYSICAL:
			if hand.get_parent() != anchor:
				hand_rigidbody.mode = RigidBody.MODE_RIGID
				Utils.reparent_node(hand, anchor, true)
				just_changed = true

func _on_PhysicsActivationArea_body_shape_entered(body_id: int, _body: Node, _body_shape: int, _local_shape: int):
	physics_activation_area_entered_bodies.append(body_id)

func _on_PhysicsActivationArea_body_shape_exited(body_id: int, _body, Node, _body_shape: int, _local_shape: int):
	physics_activation_area_entered_bodies.erase(body_id)

func get_joystick_vector() -> Vector2:
	return Vector2(get_joystick_axis(Enums.CONTROLLER_AXIS.JOYSTICK_X), get_joystick_axis(Enums.CONTROLLER_AXIS.JOYSTICK_Y))
