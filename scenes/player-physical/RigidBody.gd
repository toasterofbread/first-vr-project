extends RigidBody

var vel: Vector3 = Vector3.ZERO
var ang: Vector3 = Vector3.ZERO

func _integrate_forces(state: PhysicsDirectBodyState):
	state.linear_velocity = vel
	state.angular_velocity = ang
	return state
