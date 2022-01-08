extends Spatial

# Nodes
onready var raycast: RayCast = $MainBody/Model/frame/RayCast
onready var dot_sight: MeshInstance = $MainBody/Model/frame/DotSight
onready var trigger: Spatial = $MainBody/Model/trigger
onready var main_body: GameObjectGrabbable = $MainBody
onready var slide_body: StaticBody = $MainBody/SlideBody
var slide_controller: Controller = null

const fire_cooldown: float = 0.1
var last_fire_time: float = -1
var trigger_position: float = 0.0 setget set_trigger_position

func _ready():
	raycast.add_exception(self)
	slide_body.add_collision_exception_with(main_body)
	main_body.add_collision_exception_with(slide_body)

func _process(delta: float):
#	._process(delta)
	if raycast.is_colliding():
		dot_sight.visible = true
		dot_sight.global_transform.origin = raycast.get_collision_point()
	else:
		dot_sight.visible = false

#func _physics_process(delta: float):
#	if not slide_body.grabbed:
#		pass # Move toward front of gun (direct coordinate manipulation?)

func _on_GrabPointMain_finger_position_changed(finger: int, position: float):
	if finger == Enums.FINGER.INDEX:
		set_trigger_position(max(0.0, (position - 0.3) / 0.7))

func set_trigger_position(value: float):
	trigger_position = value
	trigger.rotation_degrees.x = 34.695 * trigger_position
	
	if trigger_position >= 0.9:
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

func _on_main_body_grabbed(controller: Controller):
	controller.hand_rigidbody.add_collision_exception_with(slide_body)

func _physics_process(_delta: float):
	
	if not slide_controller:
		return
	
	slide_body.translation.z = min(0.0, max(-6.26, to_local(slide_controller.hand_rigidbody.global_transform.origin).z))
	print(to_local(slide_controller.hand_rigidbody.global_transform.origin))

func _on_SlideBody_grabbed(controller: Controller):
	controller.hand_rigidbody.add_collision_exception_with(main_body)
	slide_controller = controller
func _on_SlideBody_released(controller: Controller):
	controller.hand_rigidbody.remove_collision_exception_with(main_body)
	slide_controller = null
