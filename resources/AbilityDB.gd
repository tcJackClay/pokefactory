class_name AbilityDB
extends Resource

## 特性数据库

@export var abilities: Dictionary = {}

func _init():
	load_data()

func load_data():
	# 特性数据需要从 moveDictionary.js 中提取
	# 这里先创建空数据库，后续可以扩展
	abilities = {}
	
	# 常用特性示例
	var common_abilities = {
		"overgrow": {"name": "Overgrow", "type": ["grass"], "rarity": 1, "effect": "grass_damage_boost"},
		"blaze": {"name": "Blaze", "type": ["fire"], "rarity": 1, "effect": "fire_damage_boost"},
		"swarm": {"name": "Swarm", "type": ["bug"], "rarity": 1, "effect": "bug_damage_boost"},
		"torrent": {"name": "Torrent", "type": ["water"], "rarity": 1, "effect": "water_damage_boost"},
		" intimidate": {"name": "Intimidate", "type": ["all"], "rarity": 2, "effect": "lower_atk"},
		"trace": {"name": "Trace", "type": ["all"], "rarity": 2, "effect": "copy_ability"},
		"pressure": {"name": "Pressure", "type": ["all"], "rarity": 2, "effect": "double_pp"},
		"intuition": {"name": "Intuition", "type": ["all"], "rarity": 2, "effect": "critical_boost"},
		"regenerator": {"name": "Regenerator", "type": ["all"], "rarity": 3, "effect": "heal_on_switch"},
		"moxie": {"name": "Moxie", "type": ["all"], "rarity": 3, "effect": "atk_boost_on_ko"},
		"simple": {"name": "Simple", "type": ["all"], "rarity": 2, "effect": "double_buff"},
		"moody": {"name": "Moody", "type": ["all"], "rarity": 3, "effect": "random_buff_debuff"},
		" Download": {"name": "Download", "type": ["all"], "rarity": 2, "effect": "sp_atk_boost"},
		"adaptability": {"name": "Adaptability", "type": ["all"], "rarity": 3, "effect": "stab_boost"},
		"magicGuard": {"name": "Magic Guard", "type": ["all"], "rarity": 3, "effect": "no_passive_damage"},
		"thickFat": {"name": "Thick Fat", "type": ["all"], "rarity": 2, "effect": "fire_water_reduce"},
		"levitate": {"name": "Levitate", "type": ["all"], "rarity": 2, "effect": "ground_immune"},
		"flashFire": {"name": "Flash Fire", "type": ["fire"], "rarity": 2, "effect": "fire_immune"},
		"waterAbsorb": {"name": "Water Absorb", "type": ["water"], "rarity": 2, "effect": "water_heal"},
		"voltAbsorb": {"name": "Volt Absorb", "type": ["electric"], "rarity": 2, "effect": "electric_heal"},
		"immunity": {"name": "Immunity", "type": ["all"], "rarity": 1, "effect": "poison_immune"},
		"limber": {"name": "Limber", "type": ["all"], "rarity": 1, "effect": "paralysis_immune"},
		"insomnia": {"name": "Insomnia", "type": ["all"], "rarity": 1, "effect": "sleep_immune"},
		"ownTempo": {"name": "Own Tempo", "type": ["all"], "rarity": 1, "effect": "confusion_immune"},
	}
	
	for key in common_abilities:
		abilities[key] = common_abilities[key]
	
	print("Loaded %d abilities" % abilities.size())

func get_ability(id: String) -> Dictionary:
	return abilities.get(id, {})

func get_ability_count() -> int:
	return abilities.size()

func get_all_ability_ids() -> Array:
	return abilities.keys()

func get_abilities_by_type(type_name: String) -> Array:
	var result: Array = []
	for id in abilities:
		var types = abilities[id].get("type", [])
		if type_name in types:
			result.append(id)
	return result

func get_abilities_by_rarity(rarity: int) -> Array:
	var result: Array = []
	for id in abilities:
		if abilities[id].get("rarity") == rarity:
			result.append(id)
	return result

# 稀有度常量
const RARITY_COMMON = 1
const RARITY_UNCOMMON = 2
const RARITY_RARE = 3
