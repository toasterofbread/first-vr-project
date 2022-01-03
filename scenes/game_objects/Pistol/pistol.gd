extends GameObjectGrabbable

# Nodes
onready var raycast: RayCast = $Model/frame/RayCast
onready var dot_sight: MeshInstance = $Model/frame/DotSight
onready var slide_body: GameObjectGrabbable = $SlideBody

const fire_cooldown: float = 0.1
var last_fire_time: float = -1
var trigger_position: float = 0.0 setget set_trigger_position

func _ready():
	._ready()
	raycast.add_exception(self)
	raycast.add_exception(slide_body)
#	var transform: Transform = slide_body.global_transform
#	Utils.reparent_node(slide_body, Utils.anchor)
#	slide.global_transform = transform
	
	update_sliderjoint()

func _process(delta: float):
	._process(delta)
	if raycast.is_colliding():
		dot_sight.visible = true
		dot_sight.global_transform.origin = raycast.get_collision_point()
	else:
		dot_sight.visible = false

func _on_GrabPointMain_finger_position_changed(finger: int, position: float):
	if finger == Enums.FINGER.INDEX:
		set_trigger_position(max(0.0, (position - 0.3) / 0.7))

func set_trigger_position(value: float):
	trigger_position = value
	$Model/trigger.rotation_degrees.x = 34.695 * trigger_position
	
	if trigger_position == 1.0:
		fire()

func fire():
	
	if (OS.get_ticks_msec() - last_fire_time) / 1000.0 < fire_cooldown:
		return
	
	last_fire_time = OS.get_ticks_msec()
	Utils.tprint("fire")
	
	if raycast.is_colliding():
		var collision_object: Object = raycast.get_collider()
		if collision_object.has_method("damage"):
			collision_object.damage(raycast.get_collision_point(), raycast.get_collision_normal(), Enums.DAMAGE_TYPE.BULLET, 10)

func update_sliderjoint():
	pass
#	$SlideJoint.set_node_a(get_path())
#	$SlideJoint.set_node_b(slide_body.get_path())
