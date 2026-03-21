class_name Pokemon
extends Resource

## 宝可梦数据类

@export_group("基础信息")
@export var id: String = ""
@export var name: String = ""
@export var types: Array[String] = []

@export_group("种族值")
@export var bst_hp: int = 0
@export var bst_atk: int = 0
@export var bst_def: int = 0
@export var bst_satk: int = 0
@export var bst_sdef: int = 0
@export var bst_spe: int = 0

@export_group("进化")
@export var evolve_to: String = ""
@export var evolve_level: int = 30
@export var evolve_item: String = ""
@export var hidden_ability: String = ""
@export var signature_move: String = ""

@export_group("其他")
@export var description: String = ""
@export var generation: int = 1

func get_bst_dict() -> Dictionary:
	return {
		"hp": bst_hp,
		"atk": bst_atk,
		"def": bst_def,
		"satk": bst_satk,
		"sdef": bst_sdef,
		"spe": bst_spe
	}

func get_total_bst() -> int:
	return bst_hp + bst_atk + bst_def + bst_satk + bst_sdef + bst_spe


# 宝可梦实例类
class PokemonInstance:
	var base_id: String = ""
	var base: Dictionary = {}
	var level: int = 1
	var shiny: bool = false
	var caught: int = 1
	
	# 个体值 (0-31)
	var iv_hp: int = 0
	var iv_atk: int = 0
	var iv_def: int = 0
	var iv_satk: int = 0
	var iv_sdef: int = 0
	var iv_spe: int = 0
	
	# 努力值
	var ev_hp: int = 0
	var ev_atk: int = 0
	var ev_def: int = 0
	var ev_satk: int = 0
	var ev_sdef: int = 0
	var ev_spe: int = 0
	
	# 当前属性
	var current_hp: int = 0
	var max_hp: int = 0
	var atk: int = 0
	var def: int = 0
	var satk: int = 0
	var sdef: int = 0
	var spe: int = 0
	
	# 技能
	var moves: Array = [null, null, null, null]
	var movepool: Array = []
	
	# 特性与道具
	var ability: String = ""
	var item: String = ""
	
	# 状态
	var status: String = ""
	var status_turns: int = 0
	
	# 增益/减益
	var buffs: Dictionary = {
		"atk": 0, "def": 0, "satk": 0, "sdef": 0, "spe": 0, "accuracy": 0, "evasion": 0
	}
	
	# 队伍位置
	var slot: int = 0
	var turn_order: int = 1
	
	func _init():
		pass
	
	func randomize_ivs():
		iv_hp = randi() % 32
		iv_atk = randi() % 32
		iv_def = randi() % 32
		iv_satk = randi() % 32
		iv_sdef = randi() % 32
		iv_spe = randi() % 32
		shiny = randi() % 400 == 0
	
	func calculate_stats():
		var bst = base.get("bst", {})
		var bst_hp_val = bst.get("hp", 0)
		var bst_atk_val = bst.get("atk", 0)
		var bst_def_val = bst.get("def", 0)
		var bst_satk_val = bst.get("satk", 0)
		var bst_sdef_val = bst.get("sdef", 0)
		var bst_spe_val = bst.get("spe", 0)
		
		max_hp = _calc_stat(bst_hp_val, iv_hp, ev_hp, true)
		atk = _calc_stat(bst_atk_val, iv_atk, ev_atk, false)
		def = _calc_stat(bst_def_val, iv_def, ev_def, false)
		satk = _calc_stat(bst_satk_val, iv_satk, ev_satk, false)
		sdef = _calc_stat(bst_sdef_val, iv_sdef, ev_sdef, false)
		spe = _calc_stat(bst_spe_val, iv_spe, ev_spe, false)
		current_hp = max_hp
	
	func _calc_stat(base_val: int, iv: int, ev: int, is_hp: bool) -> int:
		var result = ((2 * base_val + iv + ev / 4) * level / 100)
		if is_hp:
			result += level + 10
		else:
			result += 5
		return int(result)
	
	func setup_moves():
		if base.is_empty():
			return
		
		movepool = []
		# 简单的技能分配
		var basic_moves = ["tackle", "quickAttack", "scratch", "vineWhip", "waterGun", "ember", "tailWhip"]
		for i in range(min(4 + level / 10, 8)):
			var move_id = basic_moves[randi() % basic_moves.size()]
			if not move_id in movepool:
				movepool.append(move_id)
		
		for i in range(min(4, movepool.size())):
			moves[i] = {"id": movepool[i], "pp": 35, "max_pp": 57}
		
		ability = get_random_ability()
	
	func get_random_ability() -> String:
		var hidden = base.get("hidden_ability", "")
		if hidden != "":
			return hidden
		return "overgrow"
	
	func get_types() -> Array:
		return base.get("types", [])
	
	func take_damage(amount: int) -> int:
		var actual = min(amount, current_hp)
		current_hp -= actual
		return actual
	
	func heal(amount: int):
		current_hp = min(current_hp + amount, max_hp)
	
	func full_heal():
		current_hp = max_hp
		status = ""
		status_turns = 0
		buffs = {"atk": 0, "def": 0, "satk": 0, "sdef": 0, "spe": 0, "accuracy": 0, "evasion": 0}
	
	func is_alive() -> bool:
		return current_hp > 0
	
	func to_dict() -> Dictionary:
		return {
			"id": base_id,
			"level": level,
			"shiny": shiny,
			"caught": caught,
			"ivs": {"hp": iv_hp, "atk": iv_atk, "def": iv_def, "satk": iv_satk, "sdef": iv_sdef, "spe": iv_spe},
			"evs": {"hp": ev_hp, "atk": ev_atk, "def": ev_def, "satk": ev_satk, "sdef": ev_sdef, "spe": ev_spe},
			"moves": moves.map(func(m): return m.get("id", null) if m else null),
			"ability": ability,
			"item": item,
			"status": status,
			"current_hp": current_hp
		}
