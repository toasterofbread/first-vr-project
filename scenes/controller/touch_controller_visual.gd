tool
extends ControllerVisual

var models: Dictionary = {
	Enums.SIDE.LEFT: preload("res://models/touch_controller/TouchControllerLeft.tscn"),
	Enums.SIDE.RIGHT: preload("res://models/touch_controller/TouchControllerRight.tscn")
}

# Constants
const STICK_PRESSED: float = -0.004
const STICK_UNPRESSED: float = -0.003
const MENU_PRESSED: float = -0.0005
const AX_PRESSED: float = -0.002
const BY_PRESSED: float = -0.002
const GRIP_PRESSED: float = -0.0035
const TRIGGER_PRESSED: float = 25.0 # Degrees
const JOY_PRESSED: float = 20.0 # Degrees

var btn_ax: MeshInstance
var btn_by: MeshInstance
var btn_menu: MeshInstance
var grip: MeshInstance
var trigger: MeshInstance
var stick: MeshInstance

func _ready():
	controller.connect("button_pressed", self, "controller_button_pressed")
	controller.connect("button_release", self, "controller_button_released")

func _process(_delta: float):
	update_buttons();

func model_changed():
	btn_ax = model.get_node("BtnAX")
	btn_by = model.get_node("BtnBY")
	btn_menu = model.get_node("BtnMenu")
	grip = model.get_node("Grip")
	trigger = model.get_node("Trigger")
	stick = model.get_node("Stick")

# Updates analogue button positions (digital buttons are handled through signals)
func update_buttons():
	if controller and model:
		grip.transform.origin.x = GRIP_PRESSED * ((controller.get_joystick_axis(Enums.CONTROLLER_AXIS.GRIP_TRIGGER) + 1) / 2)
		trigger.rotation_degrees.x = TRIGGER_PRESSED * ((controller.get_joystick_axis(Enums.CONTROLLER_AXIS.INDEX_TRIGGER) + 1)/2)
		stick.rotation_degrees.x = JOY_PRESSED * controller.get_joystick_axis(Enums.CONTROLLER_AXIS.JOYSTICK_Y)
		stick.rotation_degrees.z = JOY_PRESSED * controller.get_joystick_axis(Enums.CONTROLLER_AXIS.JOYSTICK_X)
		
		# Flip for right
		if controller.side == Enums.SIDE.RIGHT:
			grip.transform.origin.x *= -1
			trigger.rotation_degrees.x *= -1
			stick.rotation_degrees.x *= -1
			stick.rotation_degrees.z *= -1

func controller_button_pressed(button: int):
	match button:
		Enums.CONTROLLER_BUTTON.AX:
			btn_ax.transform.origin.y = AX_PRESSED
		Enums.CONTROLLER_BUTTON.BY:
			btn_by.transform.origin.y = BY_PRESSED
		Enums.CONTROLLER_BUTTON.MENU:
			btn_menu.transform.origin.y = MENU_PRESSED
		Enums.CONTROLLER_BUTTON.STICK:
			stick.transform.origin.y = STICK_PRESSED
			if controller.side == Enums.SIDE.RIGHT:
				stick.transform.origin.y -= 0.0005
	

func controller_button_released(button: int):
	match button:
		Enums.CONTROLLER_BUTTON.AX:
			btn_ax.transform.origin.y = 0.0
		Enums.CONTROLLER_BUTTON.BY:
			btn_by.transform.origin.y = 0.0
		Enums.CONTROLLER_BUTTON.MENU:
			btn_menu.transform.origin.y = 0.0
		Enums.CONTROLLER_BUTTON.STICK:
			stick.transform.origin.y = STICK_UNPRESSED
			if controller.side == Enums.SIDE.RIGHT:
				stick.transform.origin.y -= 0.0005

func get_model_instance(side: int) -> Spatial:
	return models[side].instance()
