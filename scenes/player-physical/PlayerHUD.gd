class_name PlayerHUD
extends Control

onready var log_label: RichTextLabel = $PanelContainer/HBoxContainer/Log
#func _ready():
#	log_label.theme = Theme.new()

var th: Theme = Theme.new()

func print_msg(msg):
	log_label.text += "\n" + str(msg)
	var max_lines: int = log_label.rect_size.y / (th.get_font("normal_font", "richtextlabel").get_height() + th.get_constant("line_separation", "richtextlabel"))
	
	
	if log_label.get_line_count() > max_lines:
		log_label.remove_line(0)


func _on_fov_value_changed(value: float):
	Framework.player.camera.fov = value


func _on_Breakpoint_pressed():
	breakpoint


func _on_Exit_pressed():
	get_tree().quit()
