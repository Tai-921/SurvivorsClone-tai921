extends CharacterBody2D
#玩家角色

@export var movement_speed = 40.0 #角色移動速度 / 預設40
@export var hp = 20 #玩家生命值
@export var maxhp = 80 #玩家最大生命值
var time = 0

@export var last_movement = Vector2.UP

#經驗
var experience = 0
var experience_level = 1
var collected_experience = 0

#Attack
var iceSpear = preload("res://player/Attack/ice_spear.tscn")
var tornado = preload("res://player/Attack/tornado.tscn")
var javelin = preload("res://player/Attack/javelin.tscn")

#UPGRADES 升級
var collected_upgrades = [] #所有已經有的升級
var upgrade_options = [] #當前可用的升級
var armor = 0
var speed = 0
var spell_cooldown = 0
var spell_size = 0
var additional_attacks = 0


#AttackNodes
@onready var iceSpearTimer = get_node("%IceSpearTimer")
@onready var iceSpearAttackTimer = get_node("%IceSpearAttackTimer")
@onready var tornadoTimer = get_node("%TorandoTimer")
@onready var tornadoAttackTimer = get_node("%TorandoAttackTimer")
@onready var javalinBase = get_node("%JavelinBase")

#IceSpear　(冰矛)
var icespear_ammo = 0
var icespear_baseammo = 0
var icespear_attackspeed = 1.5 #攻擊速度 / 發射速度 / 預設 1.5
var icespear_level = 1

#Tornado (龍捲風)
var tornado_ammo = 0
var tornado_baseammo = 0
var tornado_attackspeed = 3 #攻擊速度 / 發射速度 / 預設 3
var tornado_level = 0

#Javelin (標槍)
var javelin_ammo = 0 # 設定標槍數量
var javelin_level = 0

#Enemy Related
var enemy_close = [] #將所有偵測到的敵人寫入此陣列

@onready var sprite = $Sprite2D
@onready var walkTimer = get_node("%walkTimer")

#GUI
@onready var expBar = get_node("%ExperienceBar")
@onready var lblLevel = get_node("%lbl_level")
	#升級選項
@onready var levelPanel = get_node("%LevelUp")
@onready var upgradeOptions = get_node("%UpgradeOptions")
@onready var itemOptions = preload("res://Utility/item_option.tscn")
@onready var sndLevelUp = get_node("%snd_levelup")
	#HP
@onready var healthBar = get_node("%HealthBar")
	#計時器
@onready var lblTimer = get_node("%lblTimer")
	#追蹤升級選項
@onready var collectedWeapons = get_node("%CollectedWeapons")
@onready var collectedUpgrades = get_node("%CollectedUpgrades")
@onready var itemContainer = preload("res://GUI/item_container.tscn")
	#遊戲結果
@onready var deathPanel = get_node("%DeathPanel")
@onready var lblResult = get_node("%lbl_Result")
@onready var sndVictory = get_node("%snd_victory")
@onready var sndLose = get_node("%snd_lose")

#Signal 遊戲背景音樂
signal playerdeath

@onready var label_hp = $label_hp # 暫時使用顯示玩家的血量 (自己額外寫的)


func _ready(): #進入遊戲首次會執行的程式
	label_hp.text = str(hp) #顯示血量文字 (之後改成血條) / UI 的更新
	label_hp.visible = false # 關閉自定義的血量顯示
	upgrade_character("icespear1") # 初始給予的技能
	attack() #開始自動攻擊
	set_expbar(experience, calculate_experiencecap())
	_on_hurtbox_hurt(0,0,0) #更新血條的GUI
	
func _physics_process(_delta):
	movement() #使用物理幀進行角色移動
	
func movement (): #角色移動
	var x_mov = Input.get_action_strength("right") - Input.get_action_strength("left")
	var y_mov = Input.get_action_strength("down") - Input.get_action_strength("up")
	var mov = Vector2(x_mov, y_mov)
	
	#控制角色畫面的水平翻轉
	if  mov.x > 0:
		sprite.flip_h = true
	elif mov.x < 0:
		sprite.flip_h = false
	
	#控制角色的移動動畫
	if mov != Vector2.ZERO:
		
		last_movement = mov # 龍捲風技能需使用到 取得最後一個移動方向
		
		if walkTimer.is_stopped(): #0.2秒然後停止			
			if sprite.frame >= sprite.hframes - 1 :
				sprite.frame = 0
			else :
				sprite.frame += 1
			walkTimer.start()
	
	#角色移動	
	velocity = mov.normalized() * movement_speed
	move_and_slide()
	

func attack():
	if icespear_level > 0:
		iceSpearTimer.wait_time = icespear_attackspeed * (1 - spell_cooldown) # * (1 - spell_cooldown) 是玩家升級選項
		if iceSpearTimer.is_stopped():
			iceSpearTimer.start()
	if tornado_level > 0:
		tornadoTimer.wait_time = tornado_attackspeed * (1 - spell_cooldown) # * (1 - spell_cooldown) 是玩家升級選項
		if tornadoTimer.is_stopped():
			tornadoTimer.start()
	if javelin_level > 0 :
		spawn_javelin()
		
	

#layer 與 Mask 的 Enemy  碰撞
func _on_hurtbox_hurt(damage, _angle, _knockback): #接受自 HurtBox 的訊號
	#print("收到被攻擊訊號")
	#假設我受到敵人的 2 點傷害, 但我有 1 點護甲, 就只受到 1 點傷害
	#如果我受到敵人的 1 點傷害, 但我有 3 點護甲, 我仍然會受到 1 點傷害
	hp -= clamp(damage - armor, 1.0, 999.0)
	healthBar.max_value = maxhp
	healthBar.value = hp
	#
	if hp <= 0:
		death()
		
	if hp <= 0:
		hp = 0
			
	label_hp.text = str(hp) #暫時顯示血量文字 (之後改成血條) / 目前隱藏中
	
	print("被攻擊了,扣掉 ",damage," 點血, 剩下", hp, "點血")
	if hp <= 0:
		#queue_free() #結束遊戲，回到選單
		pass


func _on_ice_spear_timer_timeout():
	icespear_ammo += icespear_baseammo + additional_attacks # 0 + 1 = 1 / additional_attacks 是玩家升級選項
	iceSpearAttackTimer.start() 		# 開始攻擊 0.075秒

func _on_ice_spear_attack_timer_timeout():
	#經過 0.075秒後
	if icespear_ammo > 0: 
		var icespear_attack = iceSpear.instantiate() #建立一個冰矛的實體
		# 產生實體該場景的節點架構, 之後才能調用該節點內定義的變數		
		#icespear_attack.positio = position
		icespear_attack.position = position # 位置是使用玩家位置
		icespear_attack.target = get_random_target()	# 設定目標 使用 get_random_target() 函式
		icespear_attack.level = icespear_level 
		add_child(icespear_attack) #加入節點
		icespear_ammo -= 1 # 減掉子彈數
		if icespear_ammo > 0 : 
			iceSpearAttackTimer.start() #繼續發射
		else:
			iceSpearAttackTimer.stop() #停止發射


func _on_torando_timer_timeout():
	tornado_ammo += tornado_baseammo + additional_attacks # 0 + 1 = 1 / additional_attacks 是玩家升級選項
	tornadoAttackTimer.start() 		# 開始攻擊 0.075秒

func _on_torando_attack_timer_timeout():
	#經過 0.075秒後
	if tornado_ammo > 0: 
		var tornado_attack = tornado.instantiate() #建立一個冰矛的實體
		# 產生實體該場景的節點架構, 之後才能調用該節點內定義的變數		
		#tornado_attack.positio = position
		tornado_attack.position = position # 位置是使用玩家位置
		tornado_attack.last_movement = last_movement
		tornado_attack.level = tornado_level 
		add_child(tornado_attack) #加入節點
		tornado_ammo -= 1 # 減掉子彈數
		if tornado_ammo > 0 : 
			tornadoAttackTimer.start() #繼續發射
		else:
			tornadoAttackTimer.stop() #停止發射

func spawn_javelin():
	var get_javelin_total = javalinBase.get_child_count()
	var calc_spawns = (javelin_ammo + additional_attacks) - get_javelin_total #additional_attacks 是玩家升級選項
	while calc_spawns > 0:
		var javelin_spawn = javelin.instantiate()
		javelin_spawn.global_position = global_position		
		javalinBase.add_child(javelin_spawn)
		calc_spawns -= 1
	#update javelin / 升級標槍
	var get_javelin = javalinBase.get_children()
	for i in get_javelin:
		if i.has_method("update_javelin"):
			i.update_javelin()
	

func get_random_target():
	if enemy_close.size() > 0:
		return enemy_close.pick_random().global_position
	else :
		#var random_way = ["UP","LEFT","RIGHT","BOTTOM"].pick_random()
		#print("random_way=", random_way)
		return Vector2.UP


#將碰撞的敵人 加入 / 移出 enemy_close 陣列
func _on_enemy_detection_area_body_entered(body):
	if not enemy_close.has(body):
		enemy_close.append(body)

func _on_enemy_detection_area_body_exited(body):
	if enemy_close.has(body):
		enemy_close.erase(body)

#------------------------------------------------------------
#以下為經驗值升級計算
#碰撞到寶石後,寶石往人物世界座標移動並觸發函式
#要記錄 寶石經驗值 與 當下目前的經驗值數 與 達到可以升級的經驗值數 這三個數值
#當下目前的經驗值數 加上 取得的寶石經驗值 再去與 達到可以升級的經驗數做比較
#------------------------------------------------------------
func _on_grab_area_area_entered(area):
	if area.is_in_group("loot"):
		area.target = self

func _on_collect_area_area_entered(area):
	if area.is_in_group("loot"):
		var gem_exp = area.collect()
		calculate_experience(gem_exp)

func calculate_experience(gem_exp):
	var exp_required = calculate_experiencecap()
	collected_experience += gem_exp
	if experience + collected_experience >= exp_required : #Level Up / 等級提升
		collected_experience -= exp_required - experience
		experience_level += 1
		#print("等級=", experience_level) # 等級等於
		#lblLevel.text = str("Level ",experience_level) # 移到函式 levelup() 內
		experience = 0
		exp_required = calculate_experiencecap()
		levelup()
		#calculate_experience(0) # 移到函式 levelup() 內
	else :
		experience += collected_experience
		collected_experience = 0
		print("經驗值=",experience)
	
	set_expbar(experience, exp_required)

func calculate_experiencecap(): #升級計算
	var exp_cap = experience_level
	# 前 20 級只要 5 經驗值就可以升級
	if experience_level < 20:
		exp_cap = experience_level * 5
	elif experience_level < 40: # 超過 20 級以後會需要 95 * (目前的等級 - 19) * 8
		exp_cap = 95 * (experience_level - 19) * 8
	else :# 超過 40 級以後會需要 255 * (目前的等級 - 39) * 12
		exp_cap = 255 + (experience_level - 39) * 12
	
	return exp_cap

func set_expbar(set_value = 1, set_max_value = 100):
	expBar.value = set_value
	expBar.max_value = set_max_value

func levelup():
	sndLevelUp.play()
	lblLevel.text = str("Level ",experience_level)
	var tween = levelPanel.create_tween()
	tween.tween_property(levelPanel, "position", Vector2(220,50),0.2).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	tween.play()
	levelPanel.visible = true
	var options = 0
	var optionsmax = 3
	while options < optionsmax:		
		var option_choice = itemOptions.instantiate()
		#取得亂數物品
		option_choice.item = get_random_item()
		#print(option_choice.item)
		upgradeOptions.add_child(option_choice)
		options += 1
	
	get_tree().paused = true

func upgrade_character(upgrade):
	#升級套用
	match upgrade:
		"icespear1":
			icespear_level = 1
			icespear_baseammo += 1
		"icespear2":
			icespear_level = 2
			icespear_baseammo += 1
		"icespear3":
			icespear_level = 3
		"icespear4":
			icespear_level = 4
			icespear_baseammo += 2
		"tornado1":
			tornado_level = 1
			tornado_baseammo += 1
		"tornado2":
			tornado_level = 2
			tornado_baseammo += 1
		"tornado3":
			tornado_level = 3
			tornado_attackspeed -= 0.5
		"tornado4":
			tornado_level = 4
			tornado_baseammo += 1
		"javelin1":
			javelin_level = 1
			javelin_ammo = 1
		"javelin2":
			javelin_level = 2
		"javelin3":
			javelin_level = 3
		"javelin4":
			javelin_level = 4
		"armor1","armor2","armor3","armor4":
			armor += 1
		"speed1","speed2","speed3","speed4":
			movement_speed += 20.0
		"tome1","tome2","tome3","tome4":
			spell_size += 0.10
		"scroll1","scroll2","scroll3","scroll4":
			spell_cooldown += 0.05
		"ring1","ring2":
			additional_attacks += 1 # 額外攻擊
		"food":
			hp += 20
			hp = clamp(hp,0,maxhp)	
	
	adjust_gui_collect(upgrade) # 追蹤升級的 GUI 圖示
	attack()
	var option_children = upgradeOptions.get_children()
	for i in option_children:
		i.queue_free()
	#Clear 升級選項陣列
	upgrade_options.clear()
	collected_upgrades.append(upgrade)
	levelPanel.visible = false
	levelPanel.position = Vector2(850, 50)
	# 可以自訂加入Tween
	get_tree().paused = false
	calculate_experience(0)
	
	
func get_random_item(): #取得亂數物品 / 這一段有問題
	var dblist = []
	# 遍歷資料庫內的每一個升級
	for i in UpgradeDb.UPGRADES:
		#檢查我們是否已經有了該升級
		if i in collected_upgrades : # Find already collected upgrade (找到已經收集的升級)
			pass
		elif i in upgrade_options : # If the upgrade is already an option (如果升級已經生成選項了)
			pass
		elif UpgradeDb.UPGRADES[i]["type"] == "item" : #don't pick food (不要選擇食物)
			#print("type == item")
			pass
		elif UpgradeDb.UPGRADES[i]["prerequisite"].size() > 0 : #Check for prerequiste (檢查是否有先決條件)
			var to_add = true
			for n in UpgradeDb.UPGRADES[i]["prerequisite"] : #檢查是否已經收集了該升級
				if not n in collected_upgrades:
					to_add = false
			if to_add:
				dblist.append(i)
		else :
			dblist.append(i)	
	if dblist.size() > 0:
		var randomitem = dblist.pick_random()
		upgrade_options.append(randomitem)
		return randomitem
	else : # 如果沒有任何可回傳的
		return null

func change_time(argtime = 0):
	time = argtime
	var get_m = int(time / 60.0)
	var get_s = time % 60
	
	if get_m < 10:
		get_m = str(0, get_m)
		if get_s < 10:
			get_s = str(0, get_s)
			
	lblTimer.text = str(get_m,":" , get_s)
	
	
func adjust_gui_collect(upgrade):
	var get_upgrade_displayname = UpgradeDb.UPGRADES[upgrade]["displayname"]
	var get_type = UpgradeDb.UPGRADES[upgrade]["type"]
	if get_type != "item":
		var get_collected_displaynames = []
		for i in collected_upgrades:
			get_collected_displaynames.append(UpgradeDb.UPGRADES[i]["displayname"])
		if not get_upgrade_displayname in get_collected_displaynames:
			var new_item =  itemContainer.instantiate()
			new_item.upgrade = upgrade
			match get_type:
				"weapon":
					collectedWeapons.add_child(new_item)
				"upgrade":
					collectedUpgrades.add_child(new_item)
			
	

func death():
	deathPanel.visible = true
	emit_signal("playerdeath")
	get_tree().paused = true
	var tween = deathPanel.create_tween()
	tween.tween_property(deathPanel,"position", Vector2(220,50), 3.0).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.play()
	
	if time >= 300 :
		lblResult.text = "You Win"
		sndVictory.play()
	else :
		lblResult.text = "You Lose"
		sndLose.play()
		




func _on_btn_menu_click_end():
	get_tree().paused = false
	var _level = get_tree().change_scene_to_file("res://titleScreen.tscn")	
	
