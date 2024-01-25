extends CharacterBody2D
#敵方角色

@export var movement_speed = 20.0 #移動速度
@export var hp = 20 # 生命
@export var knockback_revovery = 3.5
@export var experience = 1
@export var enemy_damage = 1
var knockback = Vector2.ZERO

@onready var player = get_tree().get_first_node_in_group("player")
@onready var loot_base = get_tree().get_first_node_in_group("loot")
@onready var sprite = $Sprite2D
@onready var anim = $walkTime
@onready var snd_hit = $snd_hit
@onready var hitBox = $Hitbox

var death_anim = preload("res://Enemy/explosion.tscn")
var exp_gem = preload("res://Objects/experience_gem.tscn")


signal remove_form_array(object)


func  _ready():
	#AnimationPlayer 動畫撥放 / 重複播放
	anim.play("walk")
	hitBox.damage = enemy_damage

func _physics_process(_delta): #物理幀
	knockback = knockback.move_toward(Vector2.ZERO, knockback_revovery)
	var direction = global_position.direction_to(player.global_position)  #取得 Player 的 世界座標位置
	#print("player_position=",player.global_position.y)	
	velocity = direction * movement_speed
	velocity += knockback 
	move_and_slide()
	
	#判斷玩家方向, 做圖片的水平翻轉面對玩家
	if direction.x > 0.1:
		sprite.flip_h = true
	elif direction.x < -0.1:
		sprite.flip_h = false
	
func death():
	emit_signal("remove_form_array", self)
	var enemy_death = death_anim.instantiate()
	enemy_death.scale = sprite.scale
	enemy_death.global_position = global_position
	get_parent().call_deferred("add_child", enemy_death)
	var new_gem = exp_gem.instantiate()
	new_gem.global_position = global_position
	new_gem.experience = experience
	loot_base.call_deferred("add_child", new_gem)
	queue_free()
	
func _on_hurtbox_hurt(damage, angle, knockback_amount): #受傷害,角度,擊退 偵測
	hp -= damage
	knockback = angle * knockback_amount #ㄧ個角度 * 擊退量
	
	if hp <= 0:
		death()
	else:
		snd_hit.play()
		
