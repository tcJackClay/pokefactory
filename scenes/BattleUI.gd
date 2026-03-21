class_name BattleUI
extends Control

## 战斗界面UI组件

# 引用
var enemy_sprite: TextureRect
var enemy_name_label: Label
var enemy_level_label: Label
var enemy_hp_bar: ProgressBar
var enemy_hp_label: Label

var player_sprite: TextureRect
var player_name_label: Label
var player_level_label: Label
var player_hp_bar: ProgressBar
var player_hp_label: Label

var move_buttons: Array[Button] = []
var message_label: Label
var log_text: RichTextLabel

# 战斗状态
var is_battling: bool = false

func _ready():
	setup_battle_ui()

func setup_battle_ui():
	set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# === 敌方区域 (上方) ===
	var enemy_area = PanelContainer.new()
	enemy_area.name = "EnemyArea"
	enemy_area.set_anchors_preset(Control.PRESET_TOP_WIDE)
	enemy_area.custom_minimum_size = Vector2(0, 180)
	enemy_area.position = Vector2(0, 10)
	add_child(enemy_area)
	
	var enemy_vbox = VBoxContainer.new()
	enemy_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	enemy_vbox.add_theme_constant_override("separation", 5)
	enemy_area.add_child(enemy_vbox)
	
	# 敌方名称和等级
	var enemy_header = HBoxContainer.new()
	enemy_vbox.add_child(enemy_header)
	
	enemy_name_label = Label.new()
	enemy_name_label.name = "EnemyName"
	enemy_name_label.text = "---"
	enemy_header.add_child(enemy_name_label)
	
	enemy_level_label = Label.new()
	enemy_level_label.name = "EnemyLevel"
	enemy_level_label.text = "Lv. ---"
	enemy_header.add_child(enemy_level_label)
	
	# 敌方HP条
	enemy_hp_bar = ProgressBar.new()
	enemy_hp_bar.name = "EnemyHPBar"
	enemy_hp_bar.max_value = 100
	enemy_hp_bar.value = 100
	enemy_hp_bar.custom_minimum_size = Vector2(300, 25)
	enemy_vbox.add_child(enemy_hp_bar)
	
	enemy_hp_label = Label.new()
	enemy_hp_label.name = "EnemyHPLabel"
	enemy_hp_label.text = "100 / 100"
	enemy_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_vbox.add_child(enemy_hp_label)
	
	# 敌方精灵
	enemy_sprite = TextureRect.new()
	enemy_sprite.name = "EnemySprite"
	enemy_sprite.custom_minimum_size = Vector2(120, 120)
	enemy_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	enemy_sprite.anchor_left = 1.0
	enemy_sprite.anchor_right = 1.0
	enemy_sprite.position = Vector2(-150, 30)
	enemy_area.add_child(enemy_sprite)
	
	# === 玩家区域 (下方) ===
	var player_area = PanelContainer.new()
	player_area.name = "PlayerArea"
	player_area.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	player_area.custom_minimum_size = Vector2(0, 200)
	player_area.position = Vector2(0, 400)
	add_child(player_area)
	
	var player_vbox = VBoxContainer.new()
	player_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	player_vbox.add_theme_constant_override("separation", 5)
	player_area.add_child(player_vbox)
	
	# 玩家精灵
	player_sprite = TextureRect.new()
	player_sprite.name = "PlayerSprite"
	player_sprite.custom_minimum_size = Vector2(120, 120)
	player_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	player_sprite.position = Vector2(20, -80)
	player_area.add_child(player_sprite)
	
	# 玩家名称和等级
	var player_header = HBoxContainer.new()
	player_header.alignment = BoxContainer.ALIGNMENT_END
	player_vbox.add_child(player_header)
	
	player_name_label = Label.new()
	player_name_label.name = "PlayerName"
	player_name_label.text = "---"
	player_header.add_child(player_name_label)
	
	player_level_label = Label.new()
	player_level_label.name = "PlayerLevel"
	player_level_label.text = "Lv. ---"
	player_header.add_child(player_level_label)
	
	# 玩家HP条
	player_hp_bar = ProgressBar.new()
	player_hp_bar.name = "PlayerHPBar"
	player_hp_bar.max_value = 100
	player_hp_bar.value = 100
	player_hp_bar.custom_minimum_size = Vector2(300, 25)
	player_vbox.add_child(player_hp_bar)
	
	player_hp_label = Label.new()
	player_hp_label.name = "PlayerHPLabel"
	player_hp_label.text = "100 / 100"
	player_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_vbox.add_child(player_hp_label)
	
	# === 技能按钮区域 ===
	var moves_panel = GridContainer.new()
	moves_panel.name = "MovesPanel"
	moves_panel.columns = 2
	moves_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	moves_panel.custom_minimum_size = Vector2(0, 160)
	moves_panel.position = Vector2(0, 600)
	moves_panel.add_theme_constant_override("h_separation", 10)
	moves_panel.add_theme_constant_override("v_separation", 10)
	add_child(moves_panel)
	
	# 创建4个技能按钮
	for i in range(4):
		var btn = Button.new()
		btn.name = "MoveButton_%d" % i
		btn.text = "---"
		btn.custom_minimum_size = Vector2(250, 70)
		btn.pressed.connect(_on_move_button_pressed.bind(i))
		moves_panel.add_child(btn)
		move_buttons.append(btn)
	
	# === 消息区域 ===
	message_label = Label.new()
	message_label.name = "MessageLabel"
	message_label.text = "A wild Pokemon appeared!"
	message_label.set_anchors_preset(Control.PRESET_CENTER)
	message_label.position = Vector2(-200, 280)
	message_label.custom_minimum_size = Vector2(400, 40)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(message_label)
	
	# === 战斗日志 ===
	log_text = RichTextLabel.new()
	log_text.name = "BattleLog"
	log_text.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	log_text.custom_minimum_size = Vector2(250, 100)
	log_text.position = Vector2(10, 530)
	log_text.bbcode_enabled = true
	log_text.scroll_following = true
	add_child(log_text)

## 更新敌方信息
func update_enemy(pkmn: Pokemon.PokemonInstance):
	if not pkmn: return
	
	enemy_name_label.text = pkmn.base.get("name", "???") if pkmn.base else "???"
	enemy_level_label.text = "Lv. %d" % pkmn.level
	enemy_hp_bar.max_value = pkmn.max_hp
	enemy_hp_bar.value = pkmn.current_hp
	enemy_hp_label.text = "%d / %d" % [pkmn.current_hp, pkmn.max_hp]
	
	# 更新颜色 (低HP变红)
	if pkmn.current_hp * 100 / pkmn.max_hp < 20:
		enemy_hp_bar.modulate = Color.RED
	elif pkmn.current_hp * 100 / pkmn.max_hp < 50:
		enemy_hp_bar.modulate = Color.YELLOW
	else:
		enemy_hp_bar.modulate = Color.GREEN

## 更新玩家信息
func update_player(pkmn: Pokemon.PokemonInstance):
	if not pkmn: return
	
	player_name_label.text = pkmn.base.get("name", "???") if pkmn.base else "???"
	player_level_label.text = "Lv. %d" % pkmn.level
	player_hp_bar.max_value = pkmn.max_hp
	player_hp_bar.value = pkmn.current_hp
	player_hp_label.text = "%d / %d" % [pkmn.current_hp, pkmn.max_hp]
	
	# 更新技能按钮
	for i in range(4):
		if i < pkmn.moves.size() and pkmn.moves[i]:
			var move = pkmn.moves[i]
			move_buttons[i].text = move.name if move.name else move.id
			move_buttons[i].disabled = false
		else:
			move_buttons[i].text = "-"
			move_buttons[i].disabled = true

## 显示消息
func show_message(text: String, duration: float = 2.0):
	message_label.text = text
	
	# 创建消失动画
	var tween = create_tween()
	tween.tween_interval(duration)
	tween.tween_property(message_label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func():
		message_label.text = ""
		message_label.modulate.a = 1.0
	)

## 添加战斗日志
func add_log(text: String):
	log_text.append_text(text + "\n")

## 技能按钮回调
func _on_move_button_pressed(move_index: int):
	# 发送技能给战斗系统
	BattleManager.execute_player_move(move_index)

## 禁用所有技能按钮
func disable_moves():
	for btn in move_buttons:
		btn.disabled = true

## 启用技能按钮
func enable_moves():
	var team = GameManager.get_instance().player_team.get_team()
	var active = team.get_active_pokemon()
	if active.size() > 0:
		update_player(active[0])
