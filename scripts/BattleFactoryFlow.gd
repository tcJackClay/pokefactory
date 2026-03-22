extends PanelContainer

signal team_built(team_ids: Array)

const POKEMON_DATA_PATH := "res://data/pokemon.json"
const MOVES_DATA_PATH := "res://data/moves.json"
const POKEMON_SPRITE_DIR := "res://assets/sprites/pokemon/"
const POKEBALL_ICON_PATH := "res://assets/icons/pokeball.svg"
const HISTORY_FILE := "user://battle_factory_history.save"
const FACTORY_PICKS := 3
const TARGET_TEAM_SIZE := 3

@onready var flow_title: Label = $FlowPadding/FlowContent/FlowHeader/FlowTitle
@onready var flow_step: Label = $FlowPadding/FlowContent/FlowHeader/FlowStep
@onready var flow_body: Label = $FlowPadding/FlowContent/FlowBody
@onready var selection_grid: GridContainer = $FlowPadding/FlowContent/SelectionGrid
@onready var selected_sprite: TextureRect = $FlowPadding/FlowContent/DetailPanel/DetailPadding/DetailBody/SelectedSprite
@onready var selected_name: Label = $FlowPadding/FlowContent/DetailPanel/DetailPadding/DetailBody/DetailInfo/SelectedName
@onready var moves_grid: GridContainer = $FlowPadding/FlowContent/DetailPanel/DetailPadding/DetailBody/DetailInfo/MovesGrid
@onready var continue_button: Button = $FlowPadding/FlowContent/BottomRow/ContinueButton
@onready var team_status: Label = $FlowPadding/FlowContent/BottomRow/TeamMiniPanel/TeamMiniPadding/TeamMiniBody/TeamMiniHeader/TeamMiniStatus
@onready var team_icons: HBoxContainer = $FlowPadding/FlowContent/BottomRow/TeamMiniPanel/TeamMiniPadding/TeamMiniBody/TeamIcons

var pokemon_catalog: Array = []
var pokemon_data: Dictionary = {}
var moves_data: Dictionary = {}
var selected_team: Array = ["pikachu"]
var current_choices: Array = []
var pending_pick := ""
var pick_round := 0
var battle_history: Dictionary = {}
var icon_cache: Dictionary = {}
var awaiting_drop_choice := false
var last_added_id := ""
var expanded_pokemon_id := ""
var flow_completed := false

func _ready() -> void:
	apply_styles()
	pokemon_data = load_json(POKEMON_DATA_PATH)
	moves_data = load_json(MOVES_DATA_PATH)
	load_pokemon_catalog()
	load_history()
	refresh_team_icons()
	update_team_status()
	continue_button.pressed.connect(_on_continue_pressed)
	continue_button.visible = false
	_reset_detail_display()

func apply_styles() -> void:
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.07, 0.1, 0.18, 0.82)
	panel_style.corner_radius_top_left = 24
	panel_style.corner_radius_top_right = 24
	panel_style.corner_radius_bottom_left = 24
	panel_style.corner_radius_bottom_right = 24
	panel_style.border_width_left = 1
	panel_style.border_width_top = 1
	panel_style.border_width_right = 1
	panel_style.border_width_bottom = 1
	panel_style.border_color = Color(1, 1, 1, 0.12)
	add_theme_stylebox_override("panel", panel_style)
	$FlowPadding/FlowContent/BottomRow/TeamMiniPanel.add_theme_stylebox_override("panel", panel_style)
	$FlowPadding/FlowContent/DetailPanel.add_theme_stylebox_override("panel", panel_style)

	var action_primary := StyleBoxFlat.new()
	action_primary.bg_color = Color("#ff9f1c")
	action_primary.corner_radius_top_left = 16
	action_primary.corner_radius_top_right = 16
	action_primary.corner_radius_bottom_left = 16
	action_primary.corner_radius_bottom_right = 16
	continue_button.add_theme_stylebox_override("normal", action_primary)
	continue_button.add_theme_stylebox_override("hover", action_primary)
	continue_button.add_theme_stylebox_override("pressed", action_primary)

func enter_flow() -> void:
	start_battle_factory_flow()

func load_pokemon_catalog() -> void:
	pokemon_catalog.clear()
	for pokemon_id in pokemon_data.keys():
		var entry: Dictionary = pokemon_data[pokemon_id]
		var types: Array = entry.get("types", [])
		var p_type := "normal"
		if not types.is_empty():
			p_type = str(types[0])
		pokemon_catalog.append({
			"id": pokemon_id,
			"name": entry.get("name", pokemon_id.capitalize()),
			"type": p_type,
			"bst": sum_bst(entry.get("bst", {}))
		})
	pokemon_catalog.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("bst", 0)) > int(b.get("bst", 0))
	)

func sum_bst(bst: Dictionary) -> int:
	var total := 0
	for value in bst.values():
		total += int(value)
	return total

func start_battle_factory_flow() -> void:
	load_history()
	_reset_detail_display()
	if bool(battle_history.get("has_active_run", false)):
		selected_team = battle_history.get("team", ["pikachu"]).duplicate()
		pick_round = int(battle_history.get("pick_round", 0))
		if selected_team.is_empty():
			selected_team = ["pikachu"]
		refresh_team_icons()
		update_team_status()
		if pick_round < FACTORY_PICKS:
			prepare_next_selection_round()
			return
	reset_factory_flow(true)

func _on_continue_pressed() -> void:
	if flow_completed:
		emit_signal("team_built", selected_team.duplicate())
		return
	if awaiting_drop_choice:
		return
	if pending_pick.is_empty():
		return
	apply_pending_pick()

func reset_factory_flow(start_selection: bool) -> void:
	selected_team = ["pikachu"]
	pick_round = 0
	pending_pick = ""
	awaiting_drop_choice = false
	last_added_id = ""
	expanded_pokemon_id = ""
	flow_completed = false
	battle_history["has_active_run"] = false
	battle_history["team"] = selected_team.duplicate()
	battle_history["pick_round"] = pick_round
	save_history()
	refresh_team_icons()
	update_team_status()
	continue_button.visible = false
	continue_button.text = "确认选择"
	_reset_detail_display()
	if start_selection:
		prepare_next_selection_round()

func prepare_next_selection_round() -> void:
	if pick_round >= FACTORY_PICKS:
		finalize_team()
		return
	pending_pick = ""
	flow_completed = false
	current_choices = generate_choices()
	render_selection_balls()
	expanded_pokemon_id = ""
	continue_button.visible = false
	flow_title.text = "宝可梦三选一"
	flow_step.text = "第%d / %d次选择" % [pick_round + 1, FACTORY_PICKS]
	flow_body.text = ""
	_reset_detail_display()

func generate_choices() -> Array:
	var choices: Array = []
	var offset := pick_round * 7
	for entry in pokemon_catalog:
		var pid := String(entry.get("id", ""))
		if pid in selected_team:
			continue
		if offset > 0:
			offset -= 1
			continue
		choices.append(pid)
		if choices.size() == 3:
			break
	if choices.size() < 3:
		for entry in pokemon_catalog:
			var fallback_id := String(entry.get("id", ""))
			if fallback_id in selected_team or choices.has(fallback_id):
				continue
			choices.append(fallback_id)
			if choices.size() == 3:
				break
	return choices

func render_selection_balls() -> void:
	_clear_selection_grid()
	for pid in current_choices:
		selection_grid.add_child(create_choice_ball(pid))

func create_choice_ball(pokemon_id: String) -> VBoxContainer:
	var wrapper := VBoxContainer.new()
	wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrapper.alignment = BoxContainer.ALIGNMENT_CENTER
	wrapper.add_theme_constant_override("separation", 4)

	var ball_button := Button.new()
	ball_button.custom_minimum_size = Vector2(72, 72)
	ball_button.text = ""
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(1, 1, 1, 0.12)
	normal.corner_radius_top_left = 36
	normal.corner_radius_top_right = 36
	normal.corner_radius_bottom_left = 36
	normal.corner_radius_bottom_right = 36
	normal.border_width_left = 2
	normal.border_width_top = 2
	normal.border_width_right = 2
	normal.border_width_bottom = 2
	normal.border_color = Color(1, 1, 1, 0.45)
	ball_button.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate()
	hover.bg_color = Color(1, 1, 1, 0.2)
	ball_button.add_theme_stylebox_override("hover", hover)
	ball_button.add_theme_stylebox_override("pressed", hover)
	ball_button.icon = _get_ball_texture_for_pokemon(pokemon_id)
	ball_button.expand_icon = true
	ball_button.pressed.connect(_on_pick_pressed.bind(pokemon_id))
	wrapper.add_child(ball_button)
	return wrapper

func _get_ball_texture_for_pokemon(_pokemon_id: String) -> Texture2D:
	if ResourceLoader.exists(POKEBALL_ICON_PATH):
		return load(POKEBALL_ICON_PATH)
	return null

func _on_pick_pressed(pokemon_id: String) -> void:
	if expanded_pokemon_id == pokemon_id:
		expanded_pokemon_id = ""
		pending_pick = ""
		continue_button.visible = false
		_reset_detail_display()
		return

	expanded_pokemon_id = pokemon_id
	pending_pick = pokemon_id
	continue_button.text = "确认选择"
	continue_button.visible = true
	_update_selected_detail(pokemon_id)

func apply_pending_pick() -> void:
	selected_team.append(pending_pick)
	last_added_id = pending_pick
	expanded_pokemon_id = ""
	pick_round += 1

	if pick_round == FACTORY_PICKS and selected_team.size() > TARGET_TEAM_SIZE:
		awaiting_drop_choice = true
		continue_button.visible = false
		flow_title.text = "选择要放弃的旧队员"
		flow_step.text = ""
		flow_body.text = "请选择 1 只宝可梦放弃。"
		render_drop_candidates()
		refresh_team_icons()
		update_team_status()
		selected_name.text = "放弃队员步骤"
		_render_move_chips(["待选择", "待选择", "待选择", "待选择"])
		return

	pending_pick = ""
	battle_history["has_active_run"] = pick_round < FACTORY_PICKS
	battle_history["team"] = selected_team.duplicate()
	battle_history["pick_round"] = pick_round
	save_history()
	refresh_team_icons()
	update_team_status()

	if pick_round >= FACTORY_PICKS:
		finalize_team()
	else:
		prepare_next_selection_round()

func render_drop_candidates() -> void:
	_clear_selection_grid()
	for pokemon_id in selected_team:
		if pokemon_id == last_added_id:
			continue
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(0, 88)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var style := StyleBoxFlat.new()
		style.bg_color = Color(1, 1, 1, 0.07)
		style.corner_radius_top_left = 12
		style.corner_radius_top_right = 12
		style.corner_radius_bottom_left = 12
		style.corner_radius_bottom_right = 12
		card.add_theme_stylebox_override("panel", style)

		var pad := MarginContainer.new()
		pad.add_theme_constant_override("margin_left", 6)
		pad.add_theme_constant_override("margin_top", 6)
		pad.add_theme_constant_override("margin_right", 6)
		pad.add_theme_constant_override("margin_bottom", 6)
		card.add_child(pad)

		var body := VBoxContainer.new()
		body.alignment = BoxContainer.ALIGNMENT_CENTER
		body.add_theme_constant_override("separation", 4)
		pad.add_child(body)

		var sprite := TextureRect.new()
		sprite.custom_minimum_size = Vector2(32, 32)
		sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sprite.texture = load_pokemon_texture(pokemon_id)
		body.add_child(sprite)

		var drop_btn := Button.new()
		drop_btn.text = "放弃"
		drop_btn.pressed.connect(_on_drop_choice.bind(String(pokemon_id)))
		body.add_child(drop_btn)
		selection_grid.add_child(card)

func _on_drop_choice(drop_id: String) -> void:
	var index := selected_team.find(drop_id)
	if index == -1:
		return
	selected_team.remove_at(index)
	awaiting_drop_choice = false
	pending_pick = ""
	battle_history["has_active_run"] = false
	battle_history["team"] = selected_team.duplicate()
	battle_history["pick_round"] = pick_round
	save_history()
	refresh_team_icons()
	update_team_status()
	finalize_team()

func finalize_team() -> void:
	_clear_selection_grid()
	flow_completed = true
	continue_button.visible = true
	continue_button.text = "开始对战"
	battle_history["has_active_run"] = false
	battle_history["team"] = selected_team.duplicate()
	battle_history["pick_round"] = pick_round
	save_history()
	flow_title.text = "队伍构建完成"
	flow_step.text = ""
	flow_body.text = "已完成三次选择，点击开始对战进入对手生成。"
	selected_name.text = "队伍构建完成"
	_render_move_chips(["已就绪", "已就绪", "已就绪", "已就绪"])
	update_team_status()

func refresh_team_icons() -> void:
	for child in team_icons.get_children():
		child.queue_free()
	for pokemon_id in selected_team:
		team_icons.add_child(create_team_icon(pokemon_id))

func create_team_icon(pokemon_id: String) -> Control:
	var box := CenterContainer.new()
	box.custom_minimum_size = Vector2(36, 36)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(28, 28)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = load_pokemon_texture(pokemon_id)
	box.add_child(icon)
	return box

func update_team_status() -> void:
	team_status.text = "%d / %d" % [selected_team.size(), TARGET_TEAM_SIZE]

func load_pokemon_texture(pokemon_id: String) -> Texture2D:
	if icon_cache.has(pokemon_id):
		return icon_cache[pokemon_id]
	var path := "%s%s.png" % [POKEMON_SPRITE_DIR, pokemon_id]
	var texture: Texture2D = null
	if ResourceLoader.exists(path):
		texture = load(path)
	elif ResourceLoader.exists(POKEBALL_ICON_PATH):
		texture = load(POKEBALL_ICON_PATH)
	icon_cache[pokemon_id] = texture
	return texture

func get_pokemon_info(pokemon_id: String) -> Dictionary:
	for entry in pokemon_catalog:
		if String(entry.get("id", "")) == pokemon_id:
			return entry
	return {"id": pokemon_id, "name": pokemon_id.capitalize(), "type": "normal", "bst": 0}

func get_pokemon_name(pokemon_id: String) -> String:
	return String(get_pokemon_info(pokemon_id).get("name", pokemon_id.capitalize()))

func _clear_selection_grid() -> void:
	for child in selection_grid.get_children():
		child.queue_free()

func _reset_detail_display() -> void:
	selected_sprite.texture = load(POKEBALL_ICON_PATH) if ResourceLoader.exists(POKEBALL_ICON_PATH) else null
	selected_name.text = "宝可梦详情"
	_render_move_chips(["技能?", "技能?", "技能?", "技能?"])

func _update_selected_detail(pokemon_id: String) -> void:
	var info := get_pokemon_info(pokemon_id)
	selected_sprite.texture = load_pokemon_texture(pokemon_id)
	selected_name.text = "%s  |  %s" % [get_pokemon_name(pokemon_id), String(info.get("type", "normal")).capitalize()]
	_render_move_chips(_build_move_list(pokemon_id))

func _build_move_list(pokemon_id: String) -> Array:
	var info := get_pokemon_info(pokemon_id)
	var primary_type := String(info.get("type", "normal"))
	var raw_entry: Dictionary = pokemon_data.get(pokemon_id, {})
	var signature_move := String(raw_entry.get("signature_move", ""))

	var picked_moves: Array = []
	if not signature_move.is_empty():
		picked_moves.append(signature_move)

	var candidates: Array = []
	for move_id in moves_data.keys():
		var move_info: Dictionary = moves_data[move_id]
		if String(move_info.get("type", "")) != primary_type:
			continue
		if bool(move_info.get("restricted", false)):
			continue
		candidates.append({
			"id": String(move_info.get("id", move_id)),
			"power": int(move_info.get("power", 0))
		})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("power", 0)) > int(b.get("power", 0))
	)

	for item in candidates:
		var move_name := String(item.get("id", ""))
		if picked_moves.has(move_name):
			continue
		picked_moves.append(move_name)
		if picked_moves.size() >= 4:
			break

	while picked_moves.size() < 4:
		picked_moves.append("暂无")
	return picked_moves.slice(0, 4)

func _render_move_chips(move_names: Array) -> void:
	for child in moves_grid.get_children():
		child.queue_free()
	for move_name in move_names:
		var chip := PanelContainer.new()
		chip.custom_minimum_size = Vector2(0, 38)
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var style := StyleBoxFlat.new()
		style.bg_color = Color(1, 1, 1, 0.08)
		style.corner_radius_top_left = 10
		style.corner_radius_top_right = 10
		style.corner_radius_bottom_left = 10
		style.corner_radius_bottom_right = 10
		chip.add_theme_stylebox_override("panel", style)

		var pad := MarginContainer.new()
		pad.add_theme_constant_override("margin_left", 8)
		pad.add_theme_constant_override("margin_right", 8)
		chip.add_child(pad)

		var label := Label.new()
		label.text = String(move_name)
		label.clip_text = true
		label.max_lines_visible = 1
		pad.add_child(label)
		moves_grid.add_child(chip)

func load_history() -> void:
	battle_history = {}
	if not FileAccess.file_exists(HISTORY_FILE):
		return
	var file := FileAccess.open(HISTORY_FILE, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		battle_history = parsed

func save_history() -> void:
	var file := FileAccess.open(HISTORY_FILE, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(battle_history))

func load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		return parsed
	return {}
