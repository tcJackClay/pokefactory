class_name BattleFactoryService
extends RefCounted

const DEFAULT_TARGET_STREAK := 50
const DEFAULT_TEAM_LIMIT := 3
const MAX_LOG_SIZE := 16

var game_manager
var type_chart: TypeEffectiveness
var state: Dictionary = {}

func setup(manager, chart: TypeEffectiveness) -> void:
	game_manager = manager
	type_chart = chart
	ensure_state()

func create_default_state() -> Dictionary:
	return {
		"mode_name": "Battle Factory",
		"target_streak": DEFAULT_TARGET_STREAK,
		"best_streak": 0,
		"win_streak": 0,
		"run_active": false,
		"starter_id": "",
		"starter_choices": [],
		"recruit_choices": [],
		"opponent_preview": [],
		"last_battle": {},
		"team_limit": DEFAULT_TEAM_LIMIT,
		"log": ["欢迎来到宝可梦对战工厂，目标是 50 连胜。"]
	}

func ensure_state() -> void:
	if state.is_empty():
		state = create_default_state()
	var defaults = create_default_state()
	for key in defaults.keys():
		if not state.has(key):
			state[key] = defaults[key]

func reset_all() -> void:
	state = create_default_state()

func set_state(new_state: Dictionary) -> void:
	state = new_state.duplicate(true)
	ensure_state()

func get_state() -> Dictionary:
	ensure_state()
	return state

func roll_starters(count: int = 3) -> Array:
	ensure_state()
	state["starter_choices"] = _get_random_pokemon_ids(count, [], 340, 520)
	return state["starter_choices"]

func start_run(starter_id: String) -> void:
	ensure_state()
	game_manager.clear_player_team()
	var starter = game_manager.create_pokemon(starter_id, 50)
	if starter == null:
		return
	game_manager.player_team.add_pokemon(starter, 0)
	state["run_active"] = true
	state["starter_id"] = starter_id
	state["win_streak"] = 0
	state["recruit_choices"] = []
	state["last_battle"] = {}
	state["log"] = ["新的对战工厂挑战开始：%s。" % starter.base.get("name", starter_id)]
	prepare_next_battle()

func prepare_next_battle() -> Array:
	ensure_state()
	var current_streak: int = state.get("win_streak", 0)
	var min_bst = 360 + min(current_streak * 3, 180)
	var max_bst = min_bst + 120
	state["opponent_preview"] = _build_preview_team(3, min_bst, max_bst)
	return state["opponent_preview"]

func generate_recruit_choices(count: int = 3) -> Array:
	ensure_state()
	var exclude: Array = []
	for member in game_manager.get_team_members():
		exclude.append(member.base_id)
	state["recruit_choices"] = _get_random_pokemon_ids(count, exclude, 380, 620)
	return state["recruit_choices"]

func accept_choice(pokemon_id: String) -> Dictionary:
	ensure_state()
	var pkmn = game_manager.create_pokemon(pokemon_id, 50)
	if pkmn == null:
		return {"success": false, "message": "宝可梦生成失败"}
	var message := ""
	var team_members = game_manager.get_team_members()
	if team_members.size() < state.get("team_limit", DEFAULT_TEAM_LIMIT):
		game_manager.player_team.add_pokemon(pkmn)
		message = "已招募 %s，队伍人数 %d/3。" % [pkmn.base.get("name", pokemon_id), game_manager.get_team_members().size()]
	else:
		var weakest_slot := _find_weakest_slot()
		var replaced_name = game_manager.player_team.slots[weakest_slot].pokemon.base.get("name", "")
		game_manager.player_team.slots[weakest_slot].pokemon = pkmn
		message = "队伍已满，%s 替换了 %s。" % [pkmn.base.get("name", pokemon_id), replaced_name]
	state["recruit_choices"] = []
	_append_log(message)
	prepare_next_battle()
	return {"success": true, "message": message}

func simulate_battle() -> Dictionary:
	ensure_state()
	if not state.get("run_active", false):
		return {"success": false, "message": "请先选择初始宝可梦。"}
	if not state.get("recruit_choices", []).is_empty():
		return {"success": false, "message": "请先从 3 只随机宝可梦中选择 1 只。"}
	if state.get("opponent_preview", []).is_empty():
		prepare_next_battle()
	var opponents = state["opponent_preview"]
	var team_members = game_manager.get_team_members()
	var player_power = _estimate_team_power(team_members, opponents)
	var enemy_power = _estimate_preview_power(opponents, team_members)
	var chance = clamp(0.35 + (player_power / max(enemy_power, 1.0)) * 0.25, 0.15, 0.9)
	var win = randf() <= chance
	var result = {
		"success": true,
		"win": win,
		"chance": chance,
		"player_power": player_power,
		"enemy_power": enemy_power,
		"opponent": opponents.duplicate(true)
	}
	if win:
		state["win_streak"] += 1
		state["best_streak"] = max(state["best_streak"], state["win_streak"])
		_append_log("第 %d 战胜利！当前连胜 %d。" % [state["win_streak"], state["win_streak"]])
		for member in team_members:
			_apply_battle_rewards(member)
		state["last_battle"] = result
		generate_recruit_choices()
	else:
		_append_log("挑战失败，止步于 %d 连胜。" % state["win_streak"])
		state["last_battle"] = result
		state["run_active"] = false
		state["recruit_choices"] = []
		state["opponent_preview"] = []
	return result

func reset_run() -> void:
	ensure_state()
	game_manager.clear_player_team()
	var best_streak = state.get("best_streak", 0)
	state = create_default_state()
	state["best_streak"] = best_streak
	roll_starters()

func get_bst_total(data: Dictionary) -> int:
	var bst = data.get("bst", {})
	var total := 0
	for value in bst.values():
		total += int(value)
	return total

func _find_weakest_slot() -> int:
	var weakest_slot := 0
	var weakest_score := 99999
	for i in range(game_manager.player_team.slots.size()):
		var slot = game_manager.player_team.slots[i]
		if slot and slot.pokemon:
			var score = get_bst_total(slot.pokemon.base)
			if score < weakest_score:
				weakest_score = score
				weakest_slot = i
	return weakest_slot

func _apply_battle_rewards(member) -> void:
	member.level = min(member.level + 1, 100)
	member.calculate_stats()
	if member.base.get("evolve_to", "") != "" and member.level >= member.base.get("evolve_level", 999):
		var from_name = member.base.get("name", member.base_id)
		var evolved_id = member.base.get("evolve_to", "")
		var evolved_base = game_manager.pokemon_db.get_pokemon(evolved_id)
		if not evolved_base.is_empty():
			member.base_id = evolved_id
			member.base = evolved_base
			member.calculate_stats()
			_append_log("%s 进化成了 %s！" % [from_name, evolved_base.get("name", evolved_id)])

func _estimate_team_power(team_members: Array, opponents: Array) -> float:
	var total := 0.0
	for member in team_members:
		total += _estimate_single_power(member, opponents)
	return total + team_members.size() * 25.0

func _estimate_preview_power(preview: Array, player_members: Array) -> float:
	var total := 0.0
	for data in preview:
		total += _estimate_preview_single_power(data, player_members)
	return total + preview.size() * 25.0

func _estimate_single_power(member, opponents: Array) -> float:
	var bst_score = get_bst_total(member.base)
	var level_score = member.level * 4.0
	var hp_ratio = 1.0
	if member.max_hp > 0:
		hp_ratio = float(member.current_hp) / float(member.max_hp)
	var type_bonus = _get_type_advantage(member.base.get("types", []), opponents)
	var evolution_bonus = 25.0 if member.base.get("evolve_to", "") == "" else 0.0
	return (bst_score + level_score + type_bonus + evolution_bonus) * hp_ratio

func _estimate_preview_single_power(data: Dictionary, player_members: Array) -> float:
	var bst_score = get_bst_total(data)
	var level_score = data.get("level", 50) * 4.0
	var comparison_team: Array = player_members.map(func(member): return {"types": member.base.get("types", [])})
	var type_bonus = _get_type_advantage(data.get("types", []), comparison_team)
	return bst_score + level_score + type_bonus

func _get_type_advantage(types: Array, other_team: Array) -> float:
	var total := 0.0
	for attack_type in types:
		var best := 1.0
		for enemy in other_team:
			var defend_types = enemy.get("types", [])
			best = max(best, type_chart.get_effectiveness(attack_type, defend_types))
		total += (best - 1.0) * 40.0
	return total

func _build_preview_team(count: int, min_bst: int, max_bst: int) -> Array:
	var ids = _get_random_pokemon_ids(count, [], min_bst, max_bst)
	var result: Array = []
	for id in ids:
		var base = game_manager.pokemon_db.get_pokemon(id)
		if base.is_empty():
			continue
		result.append({
			"id": id,
			"name": base.get("name", id),
			"types": base.get("types", []),
			"bst": base.get("bst", {}),
			"evolve_to": base.get("evolve_to", ""),
			"level": 50 + min(state.get("win_streak", 0), 20)
		})
	return result

func _get_random_pokemon_ids(count: int, exclude: Array = [], min_bst: int = 0, max_bst: int = 9999) -> Array:
	var pool: Array = []
	for id in game_manager.pokemon_db.get_all_pokemon_ids():
		if id in exclude:
			continue
		var data = game_manager.pokemon_db.get_pokemon(id)
		var bst = get_bst_total(data)
		if bst >= min_bst and bst <= max_bst:
			pool.append(id)
	pool.shuffle()
	if pool.size() < count:
		for id in game_manager.pokemon_db.get_all_pokemon_ids():
			if not id in exclude and not id in pool:
				pool.append(id)
		pool.shuffle()
	return pool.slice(0, min(count, pool.size()))

func _append_log(text: String) -> void:
	ensure_state()
	state["log"].append(text)
	if state["log"].size() > MAX_LOG_SIZE:
		state["log"] = state["log"].slice(state["log"].size() - MAX_LOG_SIZE, state["log"].size())
