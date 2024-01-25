extends Area2D
#hitbox 	- 我要命中 框
#hurtbox	- 我受傷害 框

@export var damage = 1

@onready var collision = $CollisionShape2D
@onready var disableTimer = $DisableHitboxTimer

func tempdisable():
	collision.call_deferred("set", "disibled", true)
	disableTimer.start()


func _on_disable_hitbox_timer_timeout():
	collision.call_deferred("set", "disibled", false)
