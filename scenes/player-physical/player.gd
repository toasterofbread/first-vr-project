class_name Player
extends KinematicBody

const movement_speed: float = 1.0

onready var camera: ARVRCamera = $ARVROrigin/ARVRCamera
#onready var hud: PlayerHUD = camera.get_node("VRGUIPanel").scene
onready var controller_right: ARVRController = $ARVROrigin/ControllerRight
onready var controller_left: ARVRController = $ARVROrigin/ControllerLeft

var camera_moved: bool = false

func _physics_process(delta: float):
	
	var stick_r: Vector2 = controller_right.get_joystick_vector()
	if camera_moved:
		if abs(stick_r.x) < 0.7:
			camera_moved = false
	elif abs(stick_r.x) > 0.7:
		camera_moved = true
		rotation_degrees.y -= 45 * sign(stick_r.x)
	
	var stick_l: Vector2 = controller_left.get_joystick_vector()
	translate(Vector3(stick_l.x, stick_r.y*delta*20, stick_l.y * -1).rotated(Vector3(0, 1, 0), $ARVROrigin/ARVRCamera.rotation.y) * delta * 2.0 * movement_speed)
	
	Framework.plog(OS.get_ticks_msec())

func _ready():
	print("Ready")
	
	controller_right.pair = controller_left
	controller_left.pair = controller_right
	
	Framework.player = self
