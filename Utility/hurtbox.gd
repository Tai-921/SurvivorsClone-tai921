extends Area2D
#hitbox 	- 我要命中 框
#hurtbox	- 我受傷害 框

#自定義受傷害框類型
@export_enum("CoolDown","HitOce","DisableBox") var HurtBoxType = 0

#開始時只執行ㄧ次
@onready var collision = $CollisionShape2D
@onready var disableTime = $DisableTimer

#訊號
signal hurt(damage, angle, knockback)

var hit_once_array = []

#當有其他物件進入的時候, 就會觸發
func _on_area_entered(area):
	if area.is_in_group("attack"): #hitbox 要設節點的群組 "attack"		
		#print("area get damage = ",area.get("damage"))
		if not area.get("damage") == null: #判斷有沒有此變數
			match HurtBoxType:
				0: #CoolDown
					collision.call_deferred("set", "disabled", true) #將物件設為停用狀態
					#collision.disabled = true #這個好像不能這樣使用
					disableTime.start() # 計時器啟用
					#print("(計時器設為停用)cooldown= ", collision.disabled)
				1: #HitOnce
					if hit_once_array.has(area) == false:
						hit_once_array.append(area)
						if area.has_signal("remove_form_array"):
							if not area.is_connected("remove_form_array", Callable(self,"remove_form_list")):
								area.connect("remove_form_array", Callable(self,"remove_form_list"))
					else:
						return
				2: #DisableBox
					if area.has_method("tempdisable"):
						area.tempdisable()
						
			var damage = area.damage
			#
			var angle = Vector2.ZERO
			var knockback = 1
			#檢查冰矛是否有角度
			if not area.get("angle") == null:
				angle = area.angle
			if not area.get("knockback_amount") == null:
				knockback = area.knockback_amount
			#print("area.damage = ", area.damage)
			emit_signal("hurt", damage, angle, knockback) #發送訊號
			#print("發送訊號")
			# 冰矛受傷害 (移除冰矛)
			if area.has_method("enemy_hit") :
				area.enemy_hit(1)
			
func remove_form_list(object):
	if hit_once_array.has(object):
		hit_once_array.erase(object)


#計時器時間到後
func _on_disable_timer_timeout():
	#將物件設為啟用
	collision.call_deferred("set","disabled", false)
	#collision.disabled = false #這個好像不能這樣使用
	print("(計時器設為啟用)cooldown= ", collision.disabled)
	pass # Replace with function body.
