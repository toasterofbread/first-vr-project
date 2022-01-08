extends Spatial

var interface: ARVRInterface

var perform_runtime_config = false

var ovr_init_config
var ovr_performance

func _ready():
	
	Framework.hud = $VRGUIPanel.scene
	
	OS.vsync_enabled = false
	Engine.target_fps = 75
	
	interface = ARVRServer.find_interface("OVRMobile")
	if interface:
		
		ovr_init_config = preload("res://addons/godot_ovrmobile/OvrInitConfig.gdns").new()
		ovr_performance = preload("res://addons/godot_ovrmobile/OvrPerformance.gdns").new()
		
		ovr_init_config.set_render_target_size_multiplier(1)
		
		if interface.initialize():
			get_viewport().arvr = true

func _process(_delta):
	if not perform_runtime_config and interface:
		ovr_performance.set_clock_levels(1, 1)
		ovr_performance.set_extra_latency_mode(1)
		perform_runtime_config = true
