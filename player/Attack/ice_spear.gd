extends Area2D

var level = 1
var hp = 1
var speed = 100
var damage = 1
var knockback_amount = 100 # 擊退
var attack_size = 1.0

var target = Vector2.ZERO
var angle = Vector2.ZERO

@onready var player = get_tree().get_first_node_in_group("player")
signal remove_form_array(object)

func  _ready():
	angle = global_position.direction_to(target) # 世界座標轉向目標
	rotation = angle.angle() + deg_to_rad(135) # 旋轉角度 + 135度, 使其成為 x方向朝右 
	
	match level:
		1:
			hp = 1					# 子彈血量 (如果要達成穿透後要針對 Enemy 的 Collision 大小與間隔恢復秒數做設定)
			speed = 100 			# 子彈速度
			damage = 5	 			# 子彈傷害
			knockback_amount = 100
			attack_size = 1.0 * (1 + player.spell_size)		# 子彈大小
		2:
			hp = 1					# 子彈血量 (如果要達成穿透後要針對 Enemy 的 Collision 大小與間隔恢復秒數做設定)
			speed = 100 			# 子彈速度
			damage = 5	 			# 子彈傷害
			knockback_amount = 100
			attack_size = 1.0 * (1 + player.spell_size)		# 子彈大小
		3:
			hp = 2					# 子彈血量 (如果要達成穿透後要針對 Enemy 的 Collision 大小與間隔恢復秒數做設定)
			speed = 100 			# 子彈速度
			damage = 8	 			# 子彈傷害 / 等級3 提高 3點傷害
			knockback_amount = 100
			attack_size = 1.0 * (1 + player.spell_size)		# 子彈大小
		4:
			hp = 2					# 子彈血量 (如果要達成穿透後要針對 Enemy 的 Collision 大小與間隔恢復秒數做設定)
			speed = 100 			# 子彈速度
			damage = 8	 			# 子彈傷害 / 等級3 提高 3點傷害
			knockback_amount = 100
			attack_size = 1.0 * (1 + player.spell_size)		# 子彈大小		
	
	#建立冰矛動畫
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1,1) * attack_size, 1).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.play()
	
func _physics_process(delta):
	position += angle * speed * delta
	
	
func enemy_hit(charge = 1): #冰矛擊中敵人
	hp -= charge
#	print("hp=", hp)
	if(hp <= 0):
		emit_signal("remove_form_array", self)
		queue_free()

func _on_timer_timeout():
	emit_signal("remove_form_array", self)
	queue_free()
