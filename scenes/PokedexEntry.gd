class_name PokedexEntry
extends Button

## 宝可梦图鉴条目组件

signal entry_clicked(pkmn_id: String)
signal entry_right_clicked(pkmn_id: String)

@export var pokemon_id: String = ""
@export var pokemon_data: Dictionary = {}

# UI组件
var sprite: TextureRect
var name_label: Label
var type_labels: Array[Label] = []
var caught_indicator: TextureRect

func _ready():
	setup_entry_ui()

func setup_entry_ui():
	custom_minimum_size = Vector2(90, 110)
	pressed.connect(_on_pressed)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 2)
	add_child(vbox)
	
	# 精灵
	sprite = TextureRect.new()
	sprite.name = "Sprite"
	sprite.custom_minimum_size = Vector2(64, 64)
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vbox.add_child(sprite)
	
	# 类型图标行
	var types_hbox = HBoxContainer.new()
	types_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	types_hbox.add_theme_constant_override("separation", 2)
	vbox.add_child(types_hbox)
	
	# 2个类型标签
	for i in range(2):
		var type_lbl = Label.new()
		type_lbl.name = "Type_%d" % i
		type_lbl.custom_minimum_size = Vector2(40, 14)
		type_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		type_lbl.add_theme_font_size_override("font_size", 10)
		types_hbox.add_child(type_lbl)
		type_labels.append(type_lbl)
	
	# 名称
	name_label = Label.new()
	name_label.name = "Name"
	name_label.custom_minimum_size = Vector2(85, 20)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(name_label)
	
	# 已捕捉标记
	caught_indicator = TextureRect.new()
	caught_indicator.name = "Caught"
	caught_indicator.custom_minimum_size = Vector2(12, 12)
	caught_indicator.visible = false
	caught_indicator.position = Vector2(2, 2)
	add_child(caught_indicator)

func _on_pressed():
	entry_clicked.emit(pokemon_id)

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			entry_right_clicked.emit(pokemon_id)

## 更新显示
func update_display(pkmn_id: String, data: Dictionary, caught: bool = false):
	pokemon_id = pkmn_id
	pokemon_data = data
	
	# 名称
	name_label.text = data.get("name", pkmn_id)
	
	# 类型
	var types = data.get("types", [])
	var type_eff = TypeEffectiveness.new()
	
	for i in range(2):
		if i < types.size():
			type_labels[i].text = types[i].substr(0, 3).to_upper()
			type_labels[i].modulate = type_eff.get_type_color(types[i])
			type_labels[i].visible = true
		else:
			type_labels[i].visible = false
	
	# 精灵图片 (需要从资源加载)
	# TODO: 加载实际精灵图片
	# sprite.texture = load("res://assets/sprites/pokemon/%s.png" % pkmn_id)
	
	# 已捕捉状态
	caught_indicator.visible = caught
	
	# 未捕捉时灰显
	if not caught:
		modulate = Color(0.3, 0.3, 0.3)
	else:
		modulate = Color.WHITE

## 设置为选中
func set_selected(selected: bool):
	if selected:
		add_theme_stylebox_override("normal", create_selected_style())
	else:
		remove_theme_stylebox_override("normal")

func create_selected_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.3, 0.5, 0.8, 0.3)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.3, 0.5, 0.8)
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	return style
