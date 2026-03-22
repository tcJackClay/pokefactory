class_name PokedexScreen
extends Control

signal back_requested

const CARD_BG = Color("2B2D42")
const ACCENT = Color("E9C46A")

var game_manager
var search_input: LineEdit
var pokedex_grid: GridContainer
var total_label: Label
var filters := {}
var all_pokemon: Array = []
var filtered_pokemon: Array = []

func setup(manager) -> void:
	game_manager = manager
	_build_ui()
	reload_data()

func reload_data() -> void:
	if game_manager == null:
		return
	all_pokemon = game_manager.pokemon_db.get_all_pokemon_ids()
	filtered_pokemon = all_pokemon.duplicate()
	_update_pokedex_grid()
	_update_total()

func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 8
	offset_top = 8
	offset_right = -8
	offset_bottom = -8

	var shell = _panel()
	shell.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shell)

	var box = VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.add_theme_constant_override("separation", 6)
	shell.add_child(box)

	var top = HBoxContainer.new()
	var back_btn = _action_button("← 返回")
	back_btn.pressed.connect(func(): back_requested.emit())
	top.add_child(back_btn)
	search_input = LineEdit.new()
	search_input.placeholder_text = "搜索宝可梦..."
	search_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search_input.text_changed.connect(_on_search_changed)
	top.add_child(search_input)
	total_label = Label.new()
	total_label.text = "0/0"
	top.add_child(total_label)
	box.add_child(top)

	var filter_row = HBoxContainer.new()
	filters["type"] = _create_filter_dropdown(filter_row, ["All Types", "Normal", "Fire", "Water", "Electric", "Grass", "Ice", "Fighting", "Poison", "Ground", "Flying", "Psychic", "Bug", "Rock", "Ghost", "Dragon", "Dark", "Steel", "Fairy"])
	filters["division"] = _create_filter_dropdown(filter_row, ["All Div", "S", "A", "B", "C", "D"])
	var clear_btn = _action_button("清除")
	clear_btn.pressed.connect(_on_clear_filters)
	filter_row.add_child(clear_btn)
	box.add_child(filter_row)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)
	pokedex_grid = GridContainer.new()
	pokedex_grid.columns = 3
	pokedex_grid.add_theme_constant_override("h_separation", 6)
	pokedex_grid.add_theme_constant_override("v_separation", 6)
	scroll.add_child(pokedex_grid)

func _create_filter_dropdown(parent: Control, options: Array) -> OptionButton:
	var dropdown = OptionButton.new()
	for option in options:
		dropdown.add_item(option)
	dropdown.item_selected.connect(_on_filter_changed)
	parent.add_child(dropdown)
	return dropdown

func _update_pokedex_grid() -> void:
	for child in pokedex_grid.get_children():
		child.queue_free()
	for pkmn_id in filtered_pokemon:
		var data = game_manager.get_pokemon_data(pkmn_id)
		var entry = _panel()
		entry.custom_minimum_size = Vector2(0, 132)
		var box = VBoxContainer.new()
		box.add_theme_constant_override("separation", 2)
		entry.add_child(box)
		box.add_child(_sprite_for_pokemon(pkmn_id, 64))
		var name_lbl = Label.new()
		name_lbl.text = data.get("name", pkmn_id)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(name_lbl)
		var types_lbl = Label.new()
		types_lbl.text = "/".join(data.get("types", []))
		types_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(types_lbl)
		var evo_lbl = Label.new()
		evo_lbl.text = "进化: %s" % data.get("evolve_to", "—")
		evo_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		evo_lbl.add_theme_font_size_override("font_size", 10)
		box.add_child(evo_lbl)
		pokedex_grid.add_child(entry)

func _update_total() -> void:
	total_label.text = "%d/%d" % [filtered_pokemon.size(), all_pokemon.size()]

func _apply_filters() -> void:
	var search_text = search_input.text.to_lower()
	var type_filter = filters["type"].get_item_text(filters["type"].selected).to_lower()
	var div_filter = filters["division"].get_item_text(filters["division"].selected).to_lower()
	filtered_pokemon = []
	for pkmn_id in all_pokemon:
		var data = game_manager.get_pokemon_data(pkmn_id)
		var name = data.get("name", pkmn_id).to_lower()
		if search_text != "" and not (search_text in pkmn_id.to_lower() or search_text in name):
			continue
		if type_filter != "all types" and not type_filter in data.get("types", []):
			continue
		if div_filter != "all div":
			var total = game_manager.get_battle_factory_service().get_bst_total(data)
			var bucket = "d"
			if total >= 600:
				bucket = "s"
			elif total >= 500:
				bucket = "a"
			elif total >= 400:
				bucket = "b"
			elif total >= 300:
				bucket = "c"
			if bucket != div_filter:
				continue
		filtered_pokemon.append(pkmn_id)
	_update_pokedex_grid()
	_update_total()

func _on_search_changed(_text: String) -> void:
	_apply_filters()

func _on_filter_changed(_index: int) -> void:
	_apply_filters()

func _on_clear_filters() -> void:
	search_input.text = ""
	for filter_dropdown in filters.values():
		filter_dropdown.select(0)
	_apply_filters()

func _panel() -> PanelContainer:
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = CARD_BG
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = ACCENT.darkened(0.35)
	style.content_margin_left = 10
	style.content_margin_top = 10
	style.content_margin_right = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _action_button(text: String) -> Button:
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 44)
	button.focus_mode = Control.FOCUS_NONE
	return button

func _sprite_for_pokemon(pokemon_id: String, size: int) -> TextureRect:
	var sprite = TextureRect.new()
	sprite.custom_minimum_size = Vector2(size, size)
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var path = "res://assets/sprites/pokemon/%s.png" % pokemon_id
	if ResourceLoader.exists(path):
		sprite.texture = load(path)
	return sprite
