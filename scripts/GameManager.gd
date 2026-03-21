extends Node

## 游戏管理器 - 单例
## 管理所有游戏数据和全局状态

# 单例
static var instance: Node

# 数据库
var pokemon_db: PokemonDB
var move_db: MoveDB
var item_db: ItemDB
var ability_db: AbilityDB
var area_db: AreaDB

# 玩家数据
var player_name: String = "Player"
var player_team
var inventory_items: Dictionary = {}

# 游戏状态
var current_area: String = ""
var game_version: float = 5.0
var play_time: int = 0

# 设置
var settings: Dictionary = {
	"theme": "default",
	"battle_speed": 1.0,
	"show_shiny": true,
	"music_volume": 0.8,
	"sfx_volume": 1.0
}

func _ready():
	instance = self
	initialize_game()

func _init():
	if instance == null:
		instance = self

## 初始化游戏
func initialize_game():
	print("Initializing game...")
	
	# 初始化数据库
	pokemon_db = PokemonDB.new()
	move_db = MoveDB.new()
	item_db = ItemDB.new()
	ability_db = AbilityDB.new()
	area_db = AreaDB.new()
	
	# 初始化玩家数据
	player_team = Team.new()
	
	# 初始化背包
	inventory_items = {}
	inventory_items["potion"] = 10
	inventory_items["pokeball"] = 20
	
	print("Game initialized!")

## 背包管理
func add_item(item_id: String, count: int = 1):
	if item_id in inventory_items:
		inventory_items[item_id] += count
	else:
		inventory_items[item_id] = count

func remove_item(item_id: String, count: int = 1) -> bool:
	if item_id in inventory_items and inventory_items[item_id] >= count:
		inventory_items[item_id] -= count
		if inventory_items[item_id] <= 0:
			inventory_items.erase(item_id)
		return true
	return false

func get_item_count(item_id: String) -> int:
	return inventory_items.get(item_id, 0)

func has_item(item_id: String, count: int = 1) -> bool:
	return get_item_count(item_id) >= count

## 创建新的宝可梦实例
func create_pokemon(pokemon_id: String, level: int = 1):
	var pkmn_data = pokemon_db.get_pokemon(pokemon_id)
	if pkmn_data.is_empty():
		printerr("Pokemon not found: " + pokemon_id)
		return null
	
	var instance_class = Pokemon.PokemonInstance.new()
	instance_class.base_id = pokemon_id
	instance_class.base = pkmn_data
	instance_class.level = level
	instance_class.randomize_ivs()
	instance_class.calculate_stats()
	instance_class.setup_moves()
	
	return instance_class

## 获取宝可梦数据
func get_pokemon_data(pokemon_id: String) -> Dictionary:
	return pokemon_db.get_pokemon(pokemon_id)

## 获取技能数据
func get_move_data(move_id: String) -> Dictionary:
	return move_db.get_move(move_id)

## 获取道具数据
func get_item_data(item_id: String) -> Dictionary:
	return item_db.get_item(item_id)

## 获取特性数据
func get_ability_data(ability_id: String) -> Dictionary:
	return ability_db.get_ability(ability_id)

## 获取区域数据
func get_area_data(area_id: String) -> Dictionary:
	return area_db.get_area(area_id)

## 添加宝可梦到队伍
func add_pokemon_to_team(pokemon_id: String, level: int = 1) -> bool:
	var pkmn = create_pokemon(pokemon_id, level)
	if pkmn:
		return player_team.add_pokemon(pkmn)
	return false

## 使用道具
func use_item(item_id: String, target) -> Dictionary:
	if not has_item(item_id):
		return{"success": false, "message": "Not enough items"}
	
	# 简单道具效果
	var item_data = get_item_data(item_id)
	if item_data.is_empty():
		return{"success": false, "message": "Unknown item"}
	
	var result = {"success": true, "message": ""}
	
	# HP回复
	if item_data.get("hp_restore", 0) > 0 and target and target.has_method("heal"):
		target.heal(item_data.hp_restore)
		result.message = "Recovered %d HP!" % item_data.hp_restore
	
	remove_item(item_id)
	return result

## 保存游戏
func save_game() -> Dictionary:
	var save_data = {
		"version": game_version,
		"player_name": player_name,
		"play_time": play_time,
		"current_area": current_area,
		"team": player_team.to_dict(),
		"inventory": inventory_items,
		"settings": settings
	}
	
	var file = FileAccess.open("user://pokechill_save.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()
		print("Game saved!")
		return {"success": true}
	
	return {"success": false, "message": "Failed to save"}

## 加载游戏
func load_game() -> bool:
	if not FileAccess.file_exists("user://pokechill_save.json"):
		return false
	
	var file = FileAccess.open("user://pokechill_save.json", FileAccess.READ)
	if not file:
		return false
	
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	file.close()
	
	if error != OK:
		return false
	
	var save_data = json.get_data()
	
	player_name = save_data.get("player_name", "Player")
	current_area = save_data.get("current_area", "")
	settings = save_data.get("settings", settings)
	inventory_items = save_data.get("inventory", {})
	
	if save_data.has("team"):
		var team_data = save_data["team"]
		player_team.name = team_data.get("name", "Team 1")
	
	print("Game loaded!")
	return true

## 重置存档
func reset_save():
	if FileAccess.file_exists("user://pokechill_save.json"):
		var dir = DirAccess.open("user://")
		if dir:
			dir.remove("pokechill_save.json")
	initialize_game()


# 静态方法访问
static func get_instance() -> Node:
	return instance

static func get_pokemon_db() -> PokemonDB:
	return instance.pokemon_db if instance else null

static func get_move_db() -> MoveDB:
	return instance.move_db if instance else null

static func get_item_db() -> ItemDB:
	return instance.item_db if instance else null

static func get_ability_db() -> AbilityDB:
	return instance.ability_db if instance else null

static func get_area_db() -> AreaDB:
	return instance.area_db if instance else null
