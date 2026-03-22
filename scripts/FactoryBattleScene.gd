extends PanelContainer

signal battle_finished(result: Dictionary)
signal back_requested

const POKEMON_DATA_PATH := "res://data/pokemon.json"
const MOVES_DATA_PATH := "res://data/moves.json"
const POKEMON_SPRITE_DIR := "res://assets/sprites/pokemon/"
const POKEBALL_ICON_PATH := "res://assets/icons/pokeball.svg"

@onready var top_label: Label = $BattlePadding/BattleBody/Header/TopLabel
@onready var status_label: Label = $BattlePadding/BattleBody/Header/StatusLabel

@onready var enemy_sprite: TextureRect = $BattlePadding/BattleBody/EnemyPanel/EnemyPadding/EnemyBody/EnemyRow/EnemySprite
@onready var enemy_name: Label = $BattlePadding/BattleBody/EnemyPanel/EnemyPadding/EnemyBody/EnemyRow/EnemyInfo/EnemyName
@onready var enemy_hp_bar: ProgressBar = $BattlePadding/BattleBody/EnemyPanel/EnemyPadding/EnemyBody/EnemyRow/EnemyInfo/EnemyHp

@onready var player_sprite: TextureRect = $BattlePadding/BattleBody/PlayerPanel/PlayerPadding/PlayerBody/PlayerRow/PlayerSprite
@onready var player_name: Label = $BattlePadding/BattleBody/PlayerPanel/PlayerPadding/PlayerBody/PlayerRow/PlayerInfo/PlayerName
@onready var player_hp_bar: ProgressBar = $BattlePadding/BattleBody/PlayerPanel/PlayerPadding/PlayerBody/PlayerRow/PlayerInfo/PlayerHp

@onready var log_label: RichTextLabel = $BattlePadding/BattleBody/LogPanel/LogPadding/Log
@onready var move_grid: GridContainer = $BattlePadding/BattleBody/MovePanel/MovePadding/Moves
@onready var back_button: Button = $BattlePadding/BattleBody/Footer/BackButton

var pokemon_data: Dictionary = {}
var moves_data: Dictionary = {}
var icon_cache: Dictionary = {}

var player_team: Array = []
var enemy_team: Array = []
var player_active := 0
var enemy_active := 0
var battle_over := false

func _ready() -> void:
	pokemon_data = _load_json(POKEMON_DATA_PATH)
	moves_data = _load_json(MOVES_DATA_PATH)
	_apply_styles()
	_bind_move_buttons()
	back_button.pressed.connect(func() -> void:
		emit_signal("back_requested")
	)
	_write_log("战斗场景已就绪。")

func setup(player_team_ids: Array, enemy_team_ids: Array) -> void:
	player_team = _build_team(player_team_ids, 50)
	enemy_team = _build_team(enemy_team_ids, 50)
	player_active = _next_alive_index(player_team, 0)
	enemy_active = _next_alive_index(enemy_team, 0)
	battle_over = false
	top_label.text = "对战工厂 3v3"
	_write_log("对手出现，战斗开始。")
	_refresh_ui()

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
	$BattlePadding/BattleBody/EnemyPanel.add_theme_stylebox_override("panel", panel_style)
	$BattlePadding/BattleBody/PlayerPanel.add_theme_stylebox_override("panel", panel_style)
	$BattlePadding/BattleBody/LogPanel.add_theme_stylebox_override("panel", panel_style)
	$BattlePadding/BattleBody/MovePanel.add_theme_stylebox_override("panel", panel_style)

func _bind_move_buttons() -> void:
	var idx := 0
	for child in move_grid.get_children():
		if child is Button:
			var button := child as Button
			button.pressed.connect(_on_move_pressed.bind(idx))
			idx += 1

func _on_move_pressed(move_index: int) -> void:
	if battle_over:
		return
	if player_active == -1 or enemy_active == -1:
		return

	var player_unit: Dictionary = player_team[player_active]
	var enemy_unit: Dictionary = enemy_team[enemy_active]
	var player_move: Dictionary = _get_move_from_unit(player_unit, move_index)
	var enemy_move: Dictionary = _pick_enemy_move(enemy_unit)
	var player_first := int(player_unit.get("spe", 1)) >= int(enemy_unit.get("spe", 1))
	if int(player_unit.get("spe", 1)) == int(enemy_unit.get("spe", 1)):
		player_first = randf() >= 0.5

	if player_first:
		_apply_action(player_team, player_active, enemy_team, enemy_active, player_move, true)
		if not _is_fainted(enemy_team[enemy_active]):
			_apply_action(enemy_team, enemy_active, player_team, player_active, enemy_move, false)
	else:
		_apply_action(enemy_team, enemy_active, player_team, player_active, enemy_move, false)
		if not _is_fainted(player_team[player_active]):
			_apply_action(player_team, player_active, enemy_team, enemy_active, player_move, true)

	_handle_faint_switch()
	_check_battle_result()
	_refresh_ui()

func _apply_action(attacker_team: Array, attacker_index: int, defender_team: Array, defender_index: int, move: Dictionary, from_player: bool) -> void:
	var attacker: Dictionary = attacker_team[attacker_index]
	var defender: Dictionary = defender_team[defender_index]
	var attacker_name := String(attacker.get("name", "???"))
	var defender_name := String(defender.get("name", "???"))
	var move_name := String(move.get("id", "tackle"))
	var damage := _calculate_damage(attacker, defender, move)
	defender["current_hp"] = max(0, int(defender.get("current_hp", 0)) - damage)
	defender_team[defender_index] = defender

	var owner := "我方" if from_player else "对手"
	_write_log("%s %s 使用 %s，对 %s 造成 %d 伤害。" % [owner, attacker_name, move_name, defender_name, damage])

func _calculate_damage(attacker: Dictionary, defender: Dictionary, move: Dictionary) -> int:
	var level := int(attacker.get("level", 50))
	var power: int = int(max(1, int(move.get("power", 40))))
	var move_type := String(move.get("type", "normal"))
	var category := int(move.get("category", 0)) # 0物理,1特殊
	var atk_stat := int(attacker.get("atk", 30))
	var satk_stat := int(attacker.get("satk", 30))
	var def_stat: int = int(max(1, int(defender.get("def", 30))))
	var sdef_stat: int = int(max(1, int(defender.get("sdef", 30))))
	var attack := atk_stat if category == 0 else satk_stat
	var defense: int = def_stat if category == 0 else sdef_stat

	# 参考 PokéRogue/正统宝可梦思路：基础伤害 + STAB + 属性克制 + 随机浮动
	var base_damage := (((2.0 * float(level) / 5.0 + 2.0) * float(power) * float(attack) / float(defense)) / 50.0) + 2.0
	var stab := 1.5 if _has_type(attacker, move_type) else 1.0
	var effectiveness := _type_effectiveness(move_type, defender)
	var random_factor := randf_range(0.85, 1.0)
	var final_damage := int(max(1.0, floor(base_damage * stab * effectiveness * random_factor)))
	return final_damage

func _handle_faint_switch() -> void:
	if player_active != -1 and _is_fainted(player_team[player_active]):
		var old_name := String(player_team[player_active].get("name", "???"))
		player_active = _next_alive_index(player_team, player_active + 1)
		if player_active != -1:
			_write_log("我方 %s 倒下，%s 上场。" % [old_name, String(player_team[player_active].get("name", "???"))])
	if enemy_active != -1 and _is_fainted(enemy_team[enemy_active]):
		var old_enemy := String(enemy_team[enemy_active].get("name", "???"))
		enemy_active = _next_alive_index(enemy_team, enemy_active + 1)
		if enemy_active != -1:
			_write_log("对手 %s 倒下，%s 上场。" % [old_enemy, String(enemy_team[enemy_active].get("name", "???"))])

func _check_battle_result() -> void:
	var player_has_alive := _has_alive(player_team)
	var enemy_has_alive := _has_alive(enemy_team)
	if player_has_alive and enemy_has_alive:
		return
	battle_over = true
	_set_move_buttons_enabled(false)
	var player_win := player_has_alive and not enemy_has_alive
	if player_win:
		status_label.text = "战斗结果：胜利"
		_write_log("战斗结束：你赢了。")
	else:
		status_label.text = "战斗结果：失败"
		_write_log("战斗结束：你输了。")
	emit_signal("battle_finished", {
		"player_win": player_win,
		"player_team": player_team,
		"enemy_team": enemy_team
	})

func _refresh_ui() -> void:
	if player_active != -1:
		var p: Dictionary = player_team[player_active]
		player_sprite.texture = _load_pokemon_texture(String(p.get("id", "")))
		player_name.text = "%s Lv.%d" % [String(p.get("name", "???")), int(p.get("level", 50))]
		player_hp_bar.max_value = float(max(1, int(p.get("max_hp", 1))))
		player_hp_bar.value = float(int(p.get("current_hp", 0)))
	else:
		player_name.text = "无可战斗宝可梦"
		player_hp_bar.value = 0

	if enemy_active != -1:
		var e: Dictionary = enemy_team[enemy_active]
		enemy_sprite.texture = _load_pokemon_texture(String(e.get("id", "")))
		enemy_name.text = "%s Lv.%d" % [String(e.get("name", "???")), int(e.get("level", 50))]
		enemy_hp_bar.max_value = float(max(1, int(e.get("max_hp", 1))))
		enemy_hp_bar.value = float(int(e.get("current_hp", 0)))
	else:
		enemy_name.text = "对手已全灭"
		enemy_hp_bar.value = 0

	status_label.text = "我方剩余 %d | 对手剩余 %d" % [_alive_count(player_team), _alive_count(enemy_team)] if not battle_over else status_label.text
	_refresh_move_labels()

func _refresh_move_labels() -> void:
	if player_active == -1:
		_set_move_buttons_enabled(false)
		return
	_set_move_buttons_enabled(not battle_over)
	var unit: Dictionary = player_team[player_active]
	var moves: Array = unit.get("moves", [])
	var i := 0
	for child in move_grid.get_children():
		if child is Button:
			var btn := child as Button
			if i < moves.size():
				btn.text = String((moves[i] as Dictionary).get("id", "招式"))
			else:
				btn.text = "招式"
				btn.disabled = true
			i += 1

func _set_move_buttons_enabled(enabled: bool) -> void:
	for child in move_grid.get_children():
		if child is Button:
			(child as Button).disabled = not enabled

func _get_move_from_unit(unit: Dictionary, move_index: int) -> Dictionary:
	var moves: Array = unit.get("moves", [])
	if move_index >= 0 and move_index < moves.size():
		return moves[move_index]
	return {"id": "tackle", "type": "normal", "power": 40, "category": 0}

func _pick_enemy_move(unit: Dictionary) -> Dictionary:
	var moves: Array = unit.get("moves", [])
	if moves.is_empty():
		return {"id": "tackle", "type": "normal", "power": 40, "category": 0}
	return moves[randi() % moves.size()]

func _build_team(team_ids: Array, level: int) -> Array:
	var result: Array = []
	for pid_any in team_ids:
		var pid := String(pid_any)
		var p_data: Dictionary = pokemon_data.get(pid, {})
		var bst: Dictionary = p_data.get("bst", {})
		var hp := _calc_stat(int(bst.get("hp", 60)), level, true)
		var unit := {
			"id": pid,
			"name": String(p_data.get("name", pid.capitalize())),
			"types": p_data.get("types", ["normal"]),
			"level": level,
			"max_hp": hp,
			"current_hp": hp,
			"atk": _calc_stat(int(bst.get("atk", 60)), level, false),
			"def": _calc_stat(int(bst.get("def", 60)), level, false),
			"satk": _calc_stat(int(bst.get("satk", 60)), level, false),
			"sdef": _calc_stat(int(bst.get("sdef", 60)), level, false),
			"spe": _calc_stat(int(bst.get("spe", 60)), level, false),
			"moves": _build_moves_for_pokemon(pid, p_data)
		}
		result.append(unit)
	return result

func _build_moves_for_pokemon(pokemon_id: String, p_data: Dictionary) -> Array:
	var primary_type := "normal"
	var types: Array = p_data.get("types", [])
	if not types.is_empty():
		primary_type = String(types[0])

	var chosen: Array = []
	var signature := String(p_data.get("signature_move", ""))
	if not signature.is_empty() and moves_data.has(signature):
		chosen.append(_move_to_runtime_dict(signature, moves_data[signature]))

	var typed_candidates: Array = []
	var normal_candidates: Array = []
	for move_id in moves_data.keys():
		var m: Dictionary = moves_data[move_id]
		if bool(m.get("restricted", false)):
			continue
		var bucket := typed_candidates if String(m.get("type", "normal")) == primary_type else normal_candidates
		bucket.append({
			"id": String(m.get("id", move_id)),
			"power": int(m.get("power", 0)),
			"data": m
		})
	typed_candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("power", 0)) > int(b.get("power", 0))
	)
	normal_candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("power", 0)) > int(b.get("power", 0))
	)

	for bucket in [typed_candidates, normal_candidates]:
		for item in bucket:
			var id := String(item.get("id", ""))
			var exists := false
			for c in chosen:
				if String((c as Dictionary).get("id", "")) == id:
					exists = true
					break
			if exists:
				continue
			chosen.append(_move_to_runtime_dict(id, item.get("data", {})))
			if chosen.size() >= 4:
				break
		if chosen.size() >= 4:
			break

	while chosen.size() < 4:
		chosen.append({"id": "tackle", "type": "normal", "power": 40, "category": 0})
	return chosen

func _move_to_runtime_dict(move_id: String, move_data: Dictionary) -> Dictionary:
	return {
		"id": move_id,
		"type": String(move_data.get("type", "normal")),
		"power": max(1, int(move_data.get("power", 40))),
		"category": int(move_data.get("category", 0))
	}

func _calc_stat(base_value: int, level: int, is_hp: bool) -> int:
	var core := int(((2 * base_value + 31) * level) / 100.0)
	return core + level + 10 if is_hp else core + 5

func _type_effectiveness(attack_type: String, defender: Dictionary) -> float:
	var gm = GameManager.get_instance()
	if gm == null:
		return 1.0
	var chart: TypeEffectiveness = gm.type_chart
	if chart == null:
		return 1.0
	return float(chart.get_effectiveness(attack_type, defender.get("types", [])))

func _has_type(unit: Dictionary, target_type: String) -> bool:
	for t in unit.get("types", []):
		if String(t) == target_type:
			return true
	return false

func _is_fainted(unit: Dictionary) -> bool:
	return int(unit.get("current_hp", 0)) <= 0

func _has_alive(team: Array) -> bool:
	for unit in team:
		if int((unit as Dictionary).get("current_hp", 0)) > 0:
			return true
	return false

func _alive_count(team: Array) -> int:
	var count := 0
	for unit in team:
		if int((unit as Dictionary).get("current_hp", 0)) > 0:
			count += 1
	return count

func _next_alive_index(team: Array, start_index: int) -> int:
	for i in range(start_index, team.size()):
		if int((team[i] as Dictionary).get("current_hp", 0)) > 0:
			return i
	return -1

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

func _write_log(text: String) -> void:
	if log_label == null:
		return
	# 不持久化日志：仅显示最新一条
	log_label.text = text

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
