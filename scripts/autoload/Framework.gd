extends Node

var player: Player = null
var hud: PlayerHUD
var theme: Theme = Theme.new()

func plog(msg):
	if not hud:
		return
	
	hud.log_label.text += "\n" + str(msg)
	var max_lines: int = hud.log_label.rect_size.y / (theme.get_font("normal_font", "richtextlabel").get_height() + theme.get_constant("line_separation", "richtextlabel"))
	
	if hud.log_label.get_line_count() > max_lines:
		hud.log_label.remove_line(0)
