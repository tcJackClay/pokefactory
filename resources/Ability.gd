class_name Ability
extends Resource

## 特性数据类

@export_group("基础信息")
@export var id: String = ""
@export var name: String = ""
@export var description: String = ""

@export_group("属性")
@export var types: Array[String] = []  # 适用的属性类型
@export var rarity: int = 1  # 1=普通, 2=稀有, 3=传说

@export_group("效果")
@export var type_guard: String = ""  # 属性伤害减半
@export var status_immunity: String = ""  # 状态免疫
@export var status_heal: String = ""  # 状态治愈（战斗结束时）
@export var stat_boost: Dictionary = {}  # 属性提升
@export var damage_boost: float = 1.0  # 伤害倍率
@export var weather_effect: String = ""  # 天气效果

# 特性效果应用（战斗中使用）
func apply_on_attacker(attacker: Pokemon.PokemonInstance, move: Move.MoveInstance, damage: int) -> Dictionary:
	var result = {"damage": damage, "message": ""}
	
	# 特定属性技能威力提升
	if move.type in types:
		result.damage = int(damage * damage_boost)
		if damage_boost > 1.0:
			result.message = "%s's %s boosted the attack!" % [attacker.base.name, name]
	
	return result

func apply_on_defender(defender: Pokemon.PokemonInstance, attacker: Pokemon.PokemonInstance, move: Move.MoveInstance) -> Dictionary:
	var result = {"damage_mult": 1.0, "message": "", "hit": true}
	
	# 属性伤害减半
	if type_guard != "" and move.type == type_guard:
		result.damage_mult *= 0.5
		result.message = "%s's %s reduced the damage!" % [defender.base.name, name]
	
	# 状态免疫
	if status_immunity != "":
		# 在主逻辑中检查
	
	# 属性提升效果
	if not stat_boost.is_empty():
		for stat in stat_boost.keys():
			defender.buffs[stat] += stat_boost[stat]
	
	return result

func on_turn_end(pokemon: Pokemon.PokemonInstance) -> Dictionary:
	var result = {"message": ""}
	
	# 状态治愈
	if status_heal != "" and pokemon.status == status_heal:
		pokemon.status = ""
		pokemon.status_turns = 0
		result.message = "%s's %s healed its status!" % [pokemon.base.name, name]
	
	return result


# 特性实例
class AbilityInstance:
	var id: String = ""
	var name: String = ""
	var base: Ability
	
	func _init(ability_id: String = ""):
		id = ability_id
		if ability_id != "":
			load_from_db(ability_id)
	
	func load_from_db(ability_id: String):
		var db = load("res://resources/ability_db.tres")
		var ability_data = db.get_ability(ability_id)
		if ability_data:
			base = ability_data
			name = ability_data.name
	
	func to_dict() -> Dictionary:
		return {"id": id}
