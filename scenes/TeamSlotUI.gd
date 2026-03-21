class_name TeamSlotUI
extends PanelContainer

## 队伍槽位UI组件

signal slot_clicked(slot_index: int)
signal slot_right_clicked(slot_index: int)

@export var slot_index: int = 0

# UI组件
var sprite: TextureRect
var name_label: Label
var level_label: Label
var hp_bar: ProgressBar
var hp_label: Label
var moves_container: HBoxContainer
var item_icon: TextureRect

# 数据
var pokemon: Pokemon.PokemonInstance = null

func _ready():
	setup_slot_ui()

func setup_slot_ui():
	custom_minimum_size = Vector2(350, 100)
	
	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 10)
	add_child(hbox)
	
	# 宝可梦精灵
	sprite = TextureRect.new()
	sprite.name = "Sprite"
	sprite.custom_minimum_size = Vector2(80, 80)
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.mouse_filter = Control.MOUSE_FILTER_STOP
	hbox.add_child(sprite)
	
	# 信息区域
	var info_vbox = VBoxContainer.new()
	info_vbox.custom_minimum_size = Vector2(150, 0)
	info_vbox.add_theme_constant_override("separation", 2)
	hbox.add_child(info_vbox)
	
	# 名称行
	var name_hbox = HBoxContainer.new()
	info_vbox.add_child(name_hbox)
	
	name_label = Label.new()
	name_label.name = "Name"
	name_label.text = "---"
	name_hbox.add_child(name_label)
	
	# 闪光标记
	var shiny_mark = Label.new()
	shiny_mark.name = "ShinyMark"
	shiny_mark.text = ""
	shiny_mark.modulate = Color(1, 0.3, 0.5)
	name_hbox.add_child(shiny_mark)
	
	# 等级
	level_label = Label.new()
	level_label.name = "Level"
	level_label.text = "Lv. ---"
	info_vbox.add_child(level_label)
	
	# HP条
	hp_bar = ProgressBar.new()
	hp_bar.name = "HPBar"
	hp_bar.max_value = 100
	hp_bar.value = 100
	hp_bar.custom_minimum_size = Vector2(140, 16)
	info_vbox.add_child(hp_bar)
	
	# HP数值
	hp_label = Label.new()
	hp_label.name = "HPLabel"
	hp_label.text = "--- / ---"
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_vbox.add_child(hp_label)
	
	# 技能区域
	moves_container = HBoxContainer.new()
	moves_container.name = "Moves"
	moves_container.add_theme_constant_override("separation", 5)
	info_vbox.add_child(moves_container)
	
	# 4个技能图标占位
	for i in range(4):
		var move_icon = TextureRect.new()
		move_icon.custom_minimum_size = Vector2(30, 20)
		move_icon.modulate = Color.GRAY
		moves_container.add_child(move_icon)
	
	# 道具图标
	item_icon = TextureRect.new()
	item_icon.name = "ItemIcon"
	item_icon.custom_minimum_size = Vector2(40, 40)
	item_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	item_icon.visible = false
	hbox.add_child(item_icon)
	
	# 点击事件
	gui_input.connect(_on_gui_input)

func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			slot_clicked.emit(slot_index)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			slot_right_clicked.emit(slot_index)

## 更新显示
func update_display(pkmn: Pokemon.PokemonInstance):
	pokemon = pkmn
	
	if pkmn:
		# 名称
		name_label.text = pkmn.base.get("name", "???") if pkmn.base else "???"
		
		# 闪光标记
		var shiny_mark = get_node_or_null("HBoxContainer/Info/ShinyMark")
		if shiny_mark:
			shiny_mark.text = " ✦" if pkmn.shiny else ""
		
		# 等级
		level_label.text = "Lv. %d" % pkmn.level
		
		# HP
		hp_bar.max_value = pkmn.max_hp
		hp_bar.value = pkmn.current_hp
		hp_label.text = "%d / %d" % [pkmn.current_hp, pkmn.max_hp]
		
		# HP颜色
		var hp_percent = float(pkmn.current_hp) / pkmn.max_hp
		if hp_percent < 0.2:
			hp_bar.modulate = Color.RED
		elif hp_percent < 0.5:
			hp_bar.modulate = Color.YELLOW
		else:
			hp_bar.modulate = Color.GREEN
		
		# 技能
		for i in range(min(4, pkmn.moves.size())):
			var move = pkmn.moves[i]
			var move_icon = moves_container.get_child(i)
			if move and move_icon:
				move_icon.tooltip_text = move.name
				move_icon.modulate = TypeEffectiveness.new().get_type_color(move.type)
			elif move_icon:
				move_icon.tooltip_text = ""
				modulate = Color.GRAY
		
		# 道具
		if pkmn.item and pkmn.item != "":
			item_icon.visible = true
			item_icon.tooltip_text = pkmn.item
		else:
			item_icon.visible = false
		
		# 精灵 (需要从资源加载)
		# TODO: 加载实际精灵图片
	else:
		# 空槽位
		name_label.text = "Empty Slot"
		level_label.text = ""
		hp_bar.max_value = 100
		hp_bar.value = 0
		hp_label.text = "-"
		modulate = Color(0.5, 0.5, 0.5, 0.5)

## 设置为选中状态
func set_selected(selected: bool):
	if selected:
		modulate = Color(1.2, 1.2, 1.2)
	else:
		modulate = Color.WHITE
