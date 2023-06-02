extends RigidBody

var vel: Vector3 = Vector3.ZERO
var ang: Vector3 = Vector3.ZERO



func _integrate_forces(state: PhysicsDirectBodyState):
#	state.linear_velocity = state.linear_velocity.move_toward(vel, 1.0)
	state.linear_velocity = vel
	state.angular_velocity = ang
	
#	state.add_central_force(vel)
#	state.add_torque(ang)
	
