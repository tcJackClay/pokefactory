extends PanelContainer

signal battle_start_requested(player_team_ids: Array, opponent_team_ids: Array)
signal back_requested

const POKEMON_DATA_PATH := "res://data/pokemon.json"
const POKEMON_SPRITE_DIR := "res://assets/sprites/pokemon/"
const POKEBALL_ICON_PATH := "res://assets/icons/pokeball.svg"

@onready var title_label: Label = $BodyPadding/Body/Title
@onready var info_label: Label = $BodyPadding/Body/Info
@onready var player_row: HBoxContainer = $BodyPadding/Body/PlayerPanel/PlayerPadding/PlayerBody/PlayerIcons
@onready var enemy_row: HBoxContainer = $BodyPadding/Body/EnemyPanel/EnemyPadding/EnemyBody/EnemyIcons
@onready var reroll_button: Button = $BodyPadding/Body/Actions/RefreshButton
@onready var battle_button: Button = $BodyPadding/Body/Actions/BattleButton
@onready var back_button: Button = $BodyPadding/Body/Actions/BackButton

var pokemon_data: Dictionary = {}
var pokemon_catalog: Array = []
var player_team_ids: Array = []
var opponent_team_ids: Array = []
var icon_cache: Dictionary = {}

func _ready() -> void:
	pokemon_data = _load_json(POKEMON_DATA_PATH)
	_build_catalog()
	_apply_styles()
	reroll_button.pressed.connect(_on_reroll_pressed)
	battle_button.pressed.connect(_on_battle_pressed)
	back_button.pressed.connect(func() -> void:
		emit_signal("back_requested")
	)
	title_label.text = "对手生成"
	info_label.text = "生成中..."

func setup(team_ids: Array) -> void:
	player_team_ids = team_ids.duplicate()
	_render_player_team()
	_generate_opponents()

func _apply_styles() -> void:
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
	$BodyPadding/Body/PlayerPanel.add_theme_stylebox_override("panel", panel_style)
	$BodyPadding/Body/EnemyPanel.add_theme_stylebox_override("panel", panel_style)

func _on_reroll_pressed() -> void:
	_generate_opponents()

func _on_battle_pressed() -> void:
	if opponent_team_ids.size() != 3:
		return
	emit_signal("battle_start_requested", player_team_ids.duplicate(), opponent_team_ids.duplicate())

func _generate_opponents() -> void:
	var player_bst_total := 0.0
	for pid in player_team_ids:
		player_bst_total += _sum_bst(pokemon_data.get(String(pid), {}).get("bst", {}))
	var avg_bst := 420.0
	if not player_team_ids.is_empty():
		avg_bst = player_bst_total / float(player_team_ids.size())

	var min_bst := int(max(250.0, avg_bst - 70.0))
	var max_bst := int(min(760.0, avg_bst + 90.0))
	opponent_team_ids = _pick_random_ids(3, player_team_ids, min_bst, max_bst)

	# 兜底，确保始终为 3 只
	if opponent_team_ids.size() < 3:
		var fallback := _pick_random_ids(3, player_team_ids, 0, 9999)
		opponent_team_ids = fallback.slice(0, 3)

	info_label.text = "对手已生成：%s, %s, %s" % [
		_get_name(opponent_team_ids[0]),
		_get_name(opponent_team_ids[1]),
		_get_name(opponent_team_ids[2])
	]
	_render_enemy_team()

func _render_player_team() -> void:
	for child in player_row.get_children():
		child.queue_free()
	for pid in player_team_ids:
		player_row.add_child(_create_icon_card(String(pid)))

func _render_enemy_team() -> void:
	for child in enemy_row.get_children():
		child.queue_free()
	for pid in opponent_team_ids:
		enemy_row.add_child(_create_icon_card(String(pid)))

func _create_icon_card(pokemon_id: String) -> Control:
	var card := VBoxContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_theme_constant_override("separation", 4)

	var sprite := TextureRect.new()
	sprite.custom_minimum_size = Vector2(44, 44)
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.texture = _load_pokemon_texture(pokemon_id)
	card.add_child(sprite)

	var name_label := Label.new()
	name_label.text = _get_name(pokemon_id)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.clip_text = true
	name_label.max_lines_visible = 1
	card.add_child(name_label)
	return card

func _build_catalog() -> void:
	pokemon_catalog.clear()
	for pokemon_id in pokemon_data.keys():
		var entry: Dictionary = pokemon_data[pokemon_id]
		pokemon_catalog.append({
			"id": pokemon_id,
			"bst": _sum_bst(entry.get("bst", {}))
		})

func _pick_random_ids(count: int, exclude: Array, min_bst: int, max_bst: int) -> Array:
	var pool: Array = []
	for item in pokemon_catalog:
		var pid := String(item.get("id", ""))
		var bst := int(item.get("bst", 0))
		if pid in exclude:
			continue
		if bst < min_bst or bst > max_bst:
			continue
		pool.append(pid)
	pool.shuffle()
	return pool.slice(0, min(count, pool.size()))

func _sum_bst(bst: Dictionary) -> int:
	var total := 0
	for value in bst.values():
		total += int(value)
	return total

func _get_name(pokemon_id: String) -> String:
	var entry: Dictionary = pokemon_data.get(pokemon_id, {})
	return String(entry.get("name", pokemon_id.capitalize()))

func _load_pokemon_texture(pokemon_id: String) -> Texture2D:
	if icon_cache.has(pokemon_id):
		return icon_cache[pokemon_id]
	var path := "%s%s.png" % [POKEMON_SPRITE_DIR, pokemon_id]
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path)
	elif ResourceLoader.exists(POKEBALL_ICON_PATH):
		tex = load(POKEBALL_ICON_PATH)
	icon_cache[pokemon_id] = tex
	return tex

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		return parsed
	return {}
