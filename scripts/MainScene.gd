extends Node2D

var menu_button: Button
var menu_items_panel: PanelContainer
var menu_grid: GridContainer
var menu_open = false
var pokedex_screen: Control
var search_input: LineEdit
var pokedex_grid: GridContainer
var filters = {}
var total_label: Label

const SCREEN_WIDTH = 480
const SCREEN_HEIGHT = 800

var menu_buttons = [
	{"id": "travel", "text": "Travel", "icon": "oldMap.png"},
	{"id": "vs", "text": "VS", "icon": "vs.png"},
	{"id": "items", "text": "Items", "icon": "items.png"},
	{"id": "team", "text": "Team", "icon": "pokeball.png"},
	{"id": "dex", "text": "Dex", "icon": "dex.png"},
	{"id": "shop", "text": "Poke-Mart", "icon": "maxPotion.png"},
	{"id": "training", "text": "Training", "icon": "blackBelt.png"},
	{"id": "genetics", "text": "Genetics", "icon": "dnaSplicer.png"},
	{"id": "mystery_gift", "text": "Mystery Gift", "icon": "gift.png"},
	{"id": "wonder_trade", "text": "Wonder Trade", "icon": "beastball.png"},
	{"id": "dimension", "text": "Mega Dimension", "icon": "megaChunk.png"},
	{"id": "dictionary", "text": "Dictionary", "icon": "journal.png"},
	{"id": "guide", "text": "Guide", "icon": "tv.png"},
	{"id": "settings", "text": "Settings", "icon": "key.png"},
]

var all_pokemon = []
var filtered_pokemon = []
var current_screen: Control

func _ready():
	$CanvasLayer/UI/TopNav.visible = false
	
	menu_button = $CanvasLayer/UI/MenuButtonParent/MenuButton
	menu_items_panel = $CanvasLayer/UI/MenuItemsPanel
	menu_grid = $CanvasLayer/UI/MenuItemsPanel/MenuGrid
	
	_setup_menu_layer()
	_create_menu()
	_create_pokedex_screen()
	_load_pokedex_data()
	_load_background()

func _setup_menu_layer():
	var menu_parent = $CanvasLayer/UI/MenuButtonParent
	menu_parent.position = Vector2((SCREEN_WIDTH - 96) / 2, SCREEN_HEIGHT - 110)
	
	menu_items_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	menu_items_panel.clip_contents = true
	
	menu_items_panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	menu_items_panel.anchor_left = 0
	menu_items_panel.anchor_top = 1.0
	menu_items_panel.anchor_right = 1
	menu_items_panel.anchor_bottom = 1.0
	menu_items_panel.offset_top = -440
	menu_items_panel.offset_bottom = 0
	menu_items_panel.offset_left = 10
	menu_items_panel.offset_right = -10

func _create_menu():
	menu_button.custom_minimum_size = Vector2(96, 96)
	menu_button.size = Vector2(96, 96)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.58, 0.53, 0.42)
	style.corner_radius_bottom_right = 20
	menu_button.add_theme_stylebox_override("normal", style)
	
	var icon_path = "res://assets/icons/pokeball.svg"
	if ResourceLoader.exists(icon_path):
		var icon = TextureRect.new()
		icon.texture = load(icon_path)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(64, 64)
		icon.position = Vector2(16, 16)
		menu_button.add_child(icon)
	
	menu_button.focus_mode = Control.FOCUS_NONE
	
	var items_path = "res://assets/items/"
	for config in menu_buttons:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(100, 100)
		btn.focus_mode = Control.FOCUS_NONE
		
		var btn_style = StyleBoxFlat.new()
		btn_style.bg_color = Color(0.58, 0.53, 0.42)
		btn_style.border_width_left = 2
		btn_style.border_width_right = 2
		btn_style.border_width_top = 2
		btn_style.border_width_bottom = 2
		btn_style.border_color = Color(0.58, 0.53, 0.42)
		btn_style.corner_radius_top_left = 8
		btn_style.corner_radius_top_right = 8
		btn_style.corner_radius_bottom_left = 8
		btn_style.corner_radius_bottom_right = 8
		btn.add_theme_stylebox_override("normal", btn_style)
		
		var icon_path2 = items_path + config.icon
		if ResourceLoader.exists(icon_path2):
			var tex = load(icon_path2)
			var icon = TextureRect.new()
			icon.texture = tex
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.custom_minimum_size = Vector2(56, 56)
			icon.position = Vector2(22, 10)
			btn.add_child(icon)
			
			var lbl = Label.new()
			lbl.text = config.text
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.add_theme_font_size_override("font_size", 10)
			lbl.position = Vector2(0, 70)
			lbl.size = Vector2(100, 24)
			lbl.modulate = Color.WHITE
			
			var lbl_bg = StyleBoxFlat.new()
			lbl_bg.bg_color = Color(0.27, 0.25, 0.18, 0.8)
			lbl_bg.corner_radius_top_left = 4
			lbl_bg.corner_radius_top_right = 4
			lbl_bg.corner_radius_bottom_left = 4
			lbl_bg.corner_radius_bottom_right = 4
			lbl.add_theme_stylebox_override("normal", lbl_bg)
			
			btn.add_child(lbl)
		else:
			btn.text = config.text
		
		btn.pressed.connect(_on_menu_item_pressed.bind(config))
		menu_grid.add_child(btn)
	
	menu_grid.columns = 4

func _create_pokedex_screen():
	pokedex_screen = Control.new()
	pokedex_screen.name = "PokedexScreen"
	pokedex_screen.visible = false
	pokedex_screen.set_anchors_preset(Control.PRESET_TOP_WIDE)
	pokedex_screen.offset_bottom = -120
	$CanvasLayer/UI.add_child(pokedex_screen)
	
	var header = Control.new()
	header.set_anchors_preset(Control.PRESET_TOP_WIDE)
	header.custom_minimum_size = Vector2(0, 50)
	pokedex_screen.add_child(header)
	
	var back_btn = Button.new()
	back_btn.text = "← Back"
	back_btn.position = Vector2(10, 10)
	back_btn.custom_minimum_size = Vector2(80, 30)
	back_btn.pressed.connect(_on_back_pressed)
	header.add_child(back_btn)
	
	search_input = LineEdit.new()
	search_input.placeholder_text = "Search..."
	search_input.position = Vector2(100, 10)
	search_input.size = Vector2(180, 30)
	search_input.text_changed.connect(_on_search_changed)
	pokedex_screen.add_child(search_input)
	
	var filter_scroll = ScrollContainer.new()
	filter_scroll.set_anchors_preset(Control.PRESET_TOP_WIDE)
	filter_scroll.custom_minimum_size = Vector2(0, 80)
	filter_scroll.offset_top = 50
	filter_scroll.offset_bottom = -120
	# 禁用水平滚动
	filter_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	# 隐藏垂直滚动条并设置宽度为0
	var filter_v_scroll = filter_scroll.get_v_scroll_bar()
	if filter_v_scroll:
		filter_v_scroll.custom_minimum_size = Vector2(0, 0)
		filter_v_scroll.visible = false
		filter_v_scroll.modulate.a = 0
	pokedex_screen.add_child(filter_scroll)
	
	var filter_vbox = VBoxContainer.new()
	filter_vbox.custom_minimum_size = Vector2(600, 70)
	filter_scroll.add_child(filter_vbox)
	
	var filter_row1 = HBoxContainer.new()
	filter_row1.add_theme_constant_override("separation", 4)
	filter_vbox.add_child(filter_row1)
	
	filters["type"] = _create_filter_dropdown(filter_row1, "Type", ["All Types", "Normal", "Fire", "Water", "Electric", "Grass", "Ice", "Fighting", "Poison", "Ground", "Flying", "Psychic", "Bug", "Rock", "Ghost", "Dragon", "Dark", "Steel", "Fairy"])
	filters["type2"] = _create_filter_dropdown(filter_row1, "Type2", ["All", "Normal", "Fire", "Water", "Electric", "Grass", "Ice", "Fighting", "Poison", "Ground", "Flying", "Psychic", "Bug", "Rock", "Ghost", "Dragon", "Dark", "Steel", "Fairy"])
	filters["division"] = _create_filter_dropdown(filter_row1, "Div", ["All Div", "S", "A", "B", "C", "D"])
	
	total_label = Label.new()
	total_label.text = "0/0"
	total_label.custom_minimum_size = Vector2(60, 30)
	filter_row1.add_child(total_label)
	
	var filter_row2 = HBoxContainer.new()
	filter_row2.add_theme_constant_override("separation", 4)
	filter_vbox.add_child(filter_row2)
	
	filters["ability"] = _create_filter_dropdown(filter_row2, "Ability", ["All", "Overgrow", "Blaze", "Torrent", "Swarm", "Intimidate"])
	filters["shiny"] = _create_filter_dropdown(filter_row2, "Shiny", ["All", "Shiny", "Normal"])
	
	var clear_btn = Button.new()
	clear_btn.text = "Clear"
	clear_btn.custom_minimum_size = Vector2(60, 30)
	clear_btn.pressed.connect(_on_clear_filters)
	filter_row2.add_child(clear_btn)
	
	var scroll = ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_TOP_WIDE)
	scroll.custom_minimum_size = Vector2(0, 550)
	scroll.offset_top = 130
	scroll.offset_bottom = -120
	# 禁用水平滚动
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	# 隐藏垂直滚动条并设置宽度为0
	var main_v_scroll = scroll.get_v_scroll_bar()
	if main_v_scroll:
		main_v_scroll.custom_minimum_size = Vector2(0, 0)
		main_v_scroll.visible = false
		main_v_scroll.modulate.a = 0
	pokedex_screen.add_child(scroll)
	
	# 使用HBoxContainer实现内容居中
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(hbox)
	
	# 添加空白实现左侧边距
	var left_spacer = Control.new()
	left_spacer.custom_minimum_size = Vector2(10, 0)
	hbox.add_child(left_spacer)
	
	pokedex_grid = GridContainer.new()
	pokedex_grid.columns = 4
	pokedex_grid.add_theme_constant_override("h_separation", 4)
	pokedex_grid.add_theme_constant_override("v_separation", 4)
	pokedex_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	hbox.add_child(pokedex_grid)

func _create_filter_dropdown(parent, label_text, options: Array) -> OptionButton:
	var dropdown = OptionButton.new()
	dropdown.custom_minimum_size = Vector2(80, 30)
	for opt in options:
		dropdown.add_item(opt)
	dropdown.item_selected.connect(_on_filter_changed)
	parent.add_child(dropdown)
	return dropdown

func _load_pokedex_data():
	var db = GameManager.get_pokemon_db()
	if db:
		all_pokemon = db.get_all_pokemon_ids()
		filtered_pokemon = all_pokemon.duplicate()
		_update_pokedex_grid()
		_update_total()

func _update_pokedex_grid():
	for child in pokedex_grid.get_children():
		child.queue_free()
	
	var sprites_path = "res://assets/sprites/pokemon/"
	
	for pkmn_id in filtered_pokemon:
		var entry = Button.new()
		entry.custom_minimum_size = Vector2(105, 100)
		entry.focus_mode = Control.FOCUS_NONE
		
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 0)
		entry.add_child(vbox)
		
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
		
		var name_lbl = Label.new()
		name_lbl.text = pkmn_id
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 9)
		name_lbl.custom_minimum_size = Vector2(100, 16)
		vbox.add_child(name_lbl)
		
		var types_lbl = Label.new()
		var pkmn_data = GameManager.get_pokemon_db().get_pokemon(pkmn_id)
		var types = pkmn_data.get("types", [])
		types_lbl.text = " / ".join(types) if types.size() > 0 else ""
		types_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		types_lbl.add_theme_font_size_override("font_size", 8)
		types_lbl.custom_minimum_size = Vector2(100, 14)
		vbox.add_child(types_lbl)
		
		pokedex_grid.add_child(entry)

func _update_total():
	total_label.text = "%d/%d" % [filtered_pokemon.size(), all_pokemon.size()]

func _apply_filters():
	var search_text = search_input.text.to_lower() if search_input else ""
	
	var type1 = ""
	if filters.has("type"):
		var idx = filters["type"].selected
		if idx > 0:
			var arr = ["normal", "fire", "water", "electric", "grass", "ice", "fighting", "poison", "ground", "flying", "psychic", "bug", "rock", "ghost", "dragon", "dark", "steel", "fairy"]
			type1 = arr[idx-1] if idx-1 < arr.size() else ""
	
	var type2 = ""
	if filters.has("type2"):
		var idx = filters["type2"].selected
		if idx > 0:
			var arr = ["normal", "fire", "water", "electric", "grass", "ice", "fighting", "poison", "ground", "flying", "psychic", "bug", "rock", "ghost", "dragon", "dark", "steel", "fairy"]
			type2 = arr[idx-1] if idx-1 < arr.size() else ""
	
	var div = ""
	if filters.has("division"):
		var idx = filters["division"].selected
		if idx > 0:
			var arr = ["s", "a", "b", "c", "d"]
			div = arr[idx-1] if idx-1 < arr.size() else ""
	
	filtered_pokemon = []
	var db = GameManager.get_pokemon_db()
	
	for pkmn_id in all_pokemon:
		var data = db.get_pokemon(pkmn_id)
		var name = pkmn_id.to_lower()
		var types = data.get("types", [])
		var bst = data.get("bst", {})
		
		if search_text != "" and not search_text in name:
			continue
		
		if type1 != "" and not type1 in types:
			continue
		
		if type2 != "":
			if types.size() < 2 or types[1] != type2:
				continue
		
		if div != "":
			var total = 0
			for v in bst.values():
				total += v
			var pkmn_div = "d"
			if total >= 600: pkmn_div = "s"
			elif total >= 500: pkmn_div = "a"
			elif total >= 400: pkmn_div = "b"
			elif total >= 300: pkmn_div = "c"
			if pkmn_div != div:
				continue
		
		filtered_pokemon.append(pkmn_id)
	
	_update_pokedex_grid()
	_update_total()

func _on_search_changed(_text: String):
	_apply_filters()

func _on_filter_changed(_idx: int):
	_apply_filters()

func _on_clear_filters():
	search_input.text = ""
	for f in filters.values():
		f.select(0)
	_apply_filters()

func _on_menu_button_pressed():
	menu_open = !menu_open
	menu_items_panel.visible = menu_open

func _on_menu_item_pressed(config: Dictionary):
	menu_open = false
	menu_items_panel.visible = false
	
	match config.id:
		"dex":
			show_pokedex()
		"team":
			show_team()
		"items":
			show_items()
		"shop":
			show_shop()
		"travel":
			show_travel()
		"vs":
			show_battle()
		"training":
			show_training()
		"genetics":
			show_genetics()
		"mystery_gift":
			show_message("Mystery Gift - Coming soon!")
		"wonder_trade":
			show_message("Wonder Trade - Coming soon!")
		"dimension":
			show_message("Mega Dimension - Coming soon!")
		"dictionary":
			show_message("Dictionary - Coming soon!")
		"guide":
			show_message("Guide - Coming soon!")
		"settings":
			show_settings()

func show_pokedex():
	_close_current_screen()
	pokedex_screen.visible = true
	current_screen = pokedex_screen

func show_team():
	_close_current_screen()
	show_message("Team - Coming soon!")

func show_items():
	_close_current_screen()
	show_message("Items - Coming soon!")

func show_shop():
	_close_current_screen()
	show_message("Shop - Coming soon!")

func show_travel():
	_close_current_screen()
	show_message("Travel - Coming soon!")

func show_battle():
	_close_current_screen()
	show_message("VS Battle - Coming soon!")

func show_training():
	_close_current_screen()
	show_message("Training - Coming soon!")

func show_genetics():
	_close_current_screen()
	show_message("Genetics - Coming soon!")

func show_settings():
	_close_current_screen()
	show_message("Settings - Coming soon!")

func _close_current_screen():
	if current_screen != null:
		current_screen.visible = false
		current_screen = null

func _on_back_pressed():
	_close_current_screen()

func _on_save_pressed():
	GameManager.get_instance().save_game()
	show_message("Game Saved!", 1.0)

func show_message(text: String, duration: float = 2.0):
	var label = $CanvasLayer/UI/MessageLabel
	label.text = text
	label.visible = text != ""
	if text != "" and duration > 0:
		await get_tree().create_timer(duration).timeout
		label.visible = false

func _load_background():
	var bg = $ParallaxBackground/BackgroundPattern
	var path = "res://assets/bg/main-bg.png"
	if ResourceLoader.exists(path):
		bg.texture = load(path)
		bg.modulate.a = 0.1

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_S:
				if event.ctrl_pressed:
					GameManager.get_instance().save_game()
					show_message("Saved!", 1.0)
			KEY_ESCAPE:
				_close_current_screen()
