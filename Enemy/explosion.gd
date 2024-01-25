extends Sprite2D


func _ready():
	$AnimationPlayer.play("exploed")
	
func _on_animation_player_animation_finished(anim_name):
	queue_free()	
