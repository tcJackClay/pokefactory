class_name GameDataManager
extends Node

## 游戏数据管理器
## 负责加载和访问所有游戏数据

# 单例实例
static var instance: GameDataManager

# 数据缓存
var pokemon_db: Dictionary = {}
var move_db: Dictionary = {}
var item_db: Dictionary = {}
var ability_db: Dictionary = {}
var area_db: Dictionary = {}

# 数据路径
const DATA_PATH = "res://data/"

func _ready():
	instance = self
	load_all_data()

func _init():
	if instance == null:
		instance = self


## 加载所有数据
func load_all_data():
	load_pokemon_data()
	load_move_data()
	load_item_data()
	load_ability_data()
	load_area_data()
	print("All game data loaded!")


## 加载宝可梦数据
func load_pokemon_data():
	# TODO: 从JSON文件加载
	# 示例数据结构:
	# {
	#   "bulbasaur": {
	#     "name": "Bulbasaur",
	#     "types": ["grass", "poison"],
	#     "bst": {"hp": 45, "atk": 49, "def": 49, "satk": 65, "sdef": 65, "spe": 45},
	#     "evolve": "ivysaur",
	#     "evolve_level": 16
	#   }
	# }
	pass


## 加载技能数据
func load_move_data():
	# TODO: 从JSON文件加载
	pass


## 加载道具数据
func load_item_data():
	# TODO: 从JSON文件加载
	pass


## 加载特性数据
func load_ability_data():
	# TODO: 从JSON文件加载
	pass


## 加载区域数据
func load_area_data():
	# TODO: 从JSON文件加载
	pass


## 获取宝可梦数据
func get_pokemon(pokemon_id: String) -> Dictionary:
	return pokemon_db.get(pokemon_id, {})


## 获取技能数据
func get_move(move_id: String) -> Dictionary:
	return move_db.get(move_id, {})


## 获取道具数据
func get_item(item_id: String) -> Dictionary:
	return item_db.get(item_id, {})


## 获取特性数据
func get_ability(ability_id: String) -> Dictionary:
	return ability_db.get(ability_id, {})


## 获取区域数据
func get_area(area_id: String) -> Dictionary:
	return area_db.get(area_id, {})


## 根据属性筛选宝可梦
func get_pokemon_by_type(type_name: String) -> Array:
	var result: Array = []
	for id in pokemon_db:
		var pkmn = pokemon_db[id]
		if type_name in pkmn.get("types", []):
			result.append(id)
	return result


## 根据等级范围筛选宝可梦
func get_pokemon_by_level_range(min_level: int, max_level: int) -> Array:
	# TODO: 实现
	return []


## 根据段位筛选宝可梦 (D, C, B, A, S)
func get_pokemon_by_division(division: String) -> Array:
	var result: Array = []
	var division_value = {"D": 1, "C": 2, "B": 3, "A": 4, "S": 5}
	
	for id in pokemon_db:
		var pkmn = pokemon_db[id]
		var bst = pkmn.get("bst", {})
		var total = 0
		for stat in bst.values():
			total += stat
		
		# 简单分段
		var pkmn_div = "D"
		if total >= 600: pkmn_div = "S"
		elif total >= 500: pkmn_div = "A"
		elif total >= 400: pkmn_div = "B"
		elif total >= 300: pkmn_div = "C"
		
		if pkmn_div == division:
			result.append(id)
	
	return result


## 导出数据到JSON (用于转换原始JS数据)
func export_to_json():
	# TODO: 实现导出功能
	pass


## 从JSON导入数据
func import_from_json(json_path: String):
	var file = FileAccess.open(json_path, FileAccess.READ)
	if file:
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		if error == OK:
			var data = json.get_data()
			# 根据文件名确定数据类型
			if "pokemon" in json_path.to_lower():
				pokemon_db = data
			elif "move" in json_path.to_lower():
				move_db = data
			elif "item" in json_path.to_lower():
				item_db = data
			elif "ability" in json_path.to_lower():
				ability_db = data
			elif "area" in json_path.to_lower():
				area_db = data
		file.close()
