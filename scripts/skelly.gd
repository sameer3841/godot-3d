extends Sprite3D

func _on_area_3d_area_entered(area):
	if area.is_in_group("Sword"):
		queue_free()
