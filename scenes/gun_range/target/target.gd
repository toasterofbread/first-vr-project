extends StaticBody

var vp_material

func reset_target():
	$Viewport/Background.visible = true
	$Viewport/BulletHole.visible = false
	$Viewport.render_target_update_mode = Viewport.UPDATE_ONCE

func damage(position: Vector3, direction: Vector3, type: int, amount: float):
	
	# We hit our target at the position specified
	var viewport_position: Vector3 = global_transform.xform_inv(position)
	
	if direction.length() > 0.0:
		var dir = global_transform.basis.xform_inv(direction).normalized()
		viewport_position += dir * viewport_position.x
	
	# Adjust from our 3D coordinates to 2D coordinates in our viewport
	viewport_position.x = (0.5 - (viewport_position.z / 1.0)) * 512.0
	viewport_position.y = (0.5 - (viewport_position.y / 2.0)) * 1024.0
	
	# Position our bullet hole at these coordinates
	$Viewport/BulletHole.rect_position = Vector2(viewport_position.x - 32.0, viewport_position.y - 32.0)
	
	# Now render the bullet hole
	$Viewport/Background.visible = false
	$Viewport/BulletHole.visible = true
	$Viewport.render_target_update_mode = Viewport.UPDATE_ONCE

# Called when the node enters the scene tree for the first time.
func _ready():
	vp_material = SpatialMaterial.new()
	vp_material.albedo_texture = $Viewport.get_texture()
	$MeshInstance.material_override = vp_material

