extends AnimationPlayer

func _ready():
	
	var anim: Animation = get_animation("kick")
	
	for track in anim.get_track_count():
		
		for key in anim.track_get_key_count(track):
			
#			print(anim.track_get_key_value(track, key))
			var value = anim.track_get_key_value(track, key)
			for k in value:
				print(k, ": ", typeof(value[k]))
			return
#			print(str(anim.track_get_path(track)))
