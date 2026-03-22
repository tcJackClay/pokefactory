extends Control

@onready var pokedex_grid = $ContentScroll/PokemonGrid
@onready var filter_panel = $FilterPanel
@onready var search_input = $SearchInput
@onready var content_scroll = $ContentScroll
@onready var filter_scroll = $FilterPanel/FilterScroll

var all_pokemon = []
var is_visible = false

signal closed

func _ready():
	# 连接筛选器信号
	filter_panel.filter_changed.connect(_on_filter_changed)
	
	# 隐藏滚动条
	_hide_scrollbar(content_scroll)
	_hide_scrollbar(filter_scroll)
	
	# 加载数据
	_load_pokedex_data()
	
	

func _hide_scrollbar(scroll: ScrollContainer):
	if scroll:
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		var vbar = scroll.get_v_scroll_bar()
		if vbar:
			vbar.visible = false
			vbar.modulate.a = 0

func _load_pokedex_data():
	var db = GameManager.get_pokemon_db()
	if db:
		all_pokemon = db.get_all_pokemon_ids()
		filter_panel.set_pokemon_data(all_pokemon)

func _on_filter_changed(filtered_data: Array):
	# 显示内容区域
	content_scroll.visible = true
	_update_grid(filtered_data)

func show_screen():
	visible = true
	is_visible = true
	content_scroll.visible = false
	# 重置筛选
	filter_panel.apply_filters()

func _update_grid(data: Array):
	# 清除现有
	for child in pokedex_grid.get_children():
		child.queue_free()
	
	var sprites_path = "res://assets/sprites/pokemon/"
	var db = GameManager.get_pokemon_db()
	
	for pkmn_id in data:
		var entry = Button.new()
		entry.custom_minimum_size = Vector2(100, 100)
		entry.focus_mode = Control.FOCUS_NONE
		
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 0)
		entry.add_child(vbox)
		
		# 精灵图片
		var sprite_path = sprites_path + pkmn_id + ".png"
		var sprite = TextureRect.new()
		sprite.custom_minimum_size = Vector2(64, 64)
		sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		if ResourceLoader.exists(sprite_path):
			sprite.texture = load(sprite_path)
		else:
			sprite.modulate = Color(0.3, 0.3, 0.3)
		
		vbox.add_child(sprite)
		
		# 名称
		var name_lbl = Label.new()
		name_lbl.text = pkmn_id
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 10)
		name_lbl.custom_minimum_size = Vector2(100, 16)
		vbox.add_child(name_lbl)
		
		# 类型
		var types_lbl = Label.new()
		var pkmn_data = db.get_pokemon(pkmn_id) if db else {}
		var types = pkmn_data.get("types", [])
		types_lbl.text = " / ".join(types) if types.size() > 0 else ""
		types_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		types_lbl.add_theme_font_size_override("font_size", 8)
		types_lbl.custom_minimum_size = Vector2(100, 14)
		vbox.add_child(types_lbl)
		
		pokedex_grid.add_child(entry)
