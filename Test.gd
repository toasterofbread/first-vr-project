extends Control

onready var label: Label = $PanelContainer/VBoxContainer/Label

func _on_Button_pressed():
	label.text = "Button 1 pressed"

func _on_Button2_pressed():
	label.text = "Button 2 pressed"

func _on_Button3_pressed():
	label.text = "Button 3 pressed"


