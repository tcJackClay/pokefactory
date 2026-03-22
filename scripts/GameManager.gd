extends Node

## 游戏管理器 - 单例
## 管理所有游戏数据和全局状态

const BattleFactoryService = preload("res://scripts/battle_factory/BattleFactoryService.gd")

# 单例
static var instance: Node

# 数据库
var pokemon_db: PokemonDB
var move_db: MoveDB
var item_db: ItemDB
var ability_db: AbilityDB
var area_db: AreaDB
var type_chart := TypeEffectiveness.new()
var battle_factory: BattleFactoryService

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
	pokemon_db = PokemonDB.new()
	move_db = MoveDB.new()
	item_db = ItemDB.new()
	ability_db = AbilityDB.new()
	area_db = AreaDB.new()
	player_team = Team.new()
	inventory_items = {"potion": 10, "pokeball": 20}
	battle_factory = BattleFactoryService.new()
	battle_factory.setup(self, type_chart)
	print("Game initialized!")

func get_battle_factory_service() -> BattleFactoryService:
	return battle_factory

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

func hydrate_pokemon(data: Dictionary):
	var pkmn = create_pokemon(data.get("id", ""), data.get("level", 1))
	if pkmn == null:
		return null
	pkmn.shiny = data.get("shiny", false)
	pkmn.caught = data.get("caught", 1)
	var ivs = data.get("ivs", {})
	pkmn.iv_hp = ivs.get("hp", pkmn.iv_hp)
	pkmn.iv_atk = ivs.get("atk", pkmn.iv_atk)
	pkmn.iv_def = ivs.get("def", pkmn.iv_def)
	pkmn.iv_satk = ivs.get("satk", pkmn.iv_satk)
	pkmn.iv_sdef = ivs.get("sdef", pkmn.iv_sdef)
	pkmn.iv_spe = ivs.get("spe", pkmn.iv_spe)
	var evs = data.get("evs", {})
	pkmn.ev_hp = evs.get("hp", 0)
	pkmn.ev_atk = evs.get("atk", 0)
	pkmn.ev_def = evs.get("def", 0)
	pkmn.ev_satk = evs.get("satk", 0)
	pkmn.ev_sdef = evs.get("sdef", 0)
	pkmn.ev_spe = evs.get("spe", 0)
	pkmn.ability = data.get("ability", pkmn.ability)
	pkmn.item = data.get("item", "")
	pkmn.status = data.get("status", "")
	pkmn.calculate_stats()
	pkmn.current_hp = clamp(data.get("current_hp", pkmn.max_hp), 0, pkmn.max_hp)
	return pkmn

func get_pokemon_data(pokemon_id: String) -> Dictionary:
	return pokemon_db.get_pokemon(pokemon_id)

func get_move_data(move_id: String) -> Dictionary:
	return move_db.get_move(move_id)

func get_item_data(item_id: String) -> Dictionary:
	return item_db.get_item(item_id)

func get_ability_data(ability_id: String) -> Dictionary:
	return ability_db.get_ability(ability_id)

func get_area_data(area_id: String) -> Dictionary:
	return area_db.get_area(area_id)

func add_pokemon_to_team(pokemon_id: String, level: int = 1) -> bool:
	var pkmn = create_pokemon(pokemon_id, level)
	if pkmn:
		return player_team.add_pokemon(pkmn)
	return false

func clear_player_team() -> void:
	player_team = Team.new()

func get_team_members() -> Array:
	var result: Array = []
	for slot in player_team.slots:
		if slot and slot.pokemon:
			result.append(slot.pokemon)
	return result

func use_item(item_id: String, target) -> Dictionary:
	if not has_item(item_id):
		return {"success": false, "message": "Not enough items"}
	var item_data = get_item_data(item_id)
	if item_data.is_empty():
		return {"success": false, "message": "Unknown item"}
	var result = {"success": true, "message": ""}
	if item_data.get("hp_restore", 0) > 0 and target and target.has_method("heal"):
		target.heal(item_data.hp_restore)
		result.message = "Recovered %d HP!" % item_data.hp_restore
	remove_item(item_id)
	return result

func save_game() -> Dictionary:
	var save_data = {
		"version": game_version,
		"player_name": player_name,
		"play_time": play_time,
		"current_area": current_area,
		"team": player_team.to_dict(),
		"inventory": inventory_items,
		"settings": settings,
		"battle_factory": battle_factory.get_state()
	}
	var file = FileAccess.open("user://pokechill_save.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()
		print("Game saved!")
		return {"success": true}
	return {"success": false, "message": "Failed to save"}

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
	battle_factory.set_state(save_data.get("battle_factory", battle_factory.create_default_state()))
	clear_player_team()
	if save_data.has("team"):
		var team_data = save_data["team"]
		player_team.name = team_data.get("name", "Team 1")
		var slots_data = team_data.get("slots", [])
		for i in range(min(slots_data.size(), player_team.slots.size())):
			var slot_data = slots_data[i]
			if slot_data and slot_data.get("pokemon"):
				player_team.slots[i].pokemon = hydrate_pokemon(slot_data.get("pokemon", {}))
	print("Game loaded!")
	return true

func reset_save() -> void:
	if FileAccess.file_exists("user://pokechill_save.json"):
		var dir = DirAccess.open("user://")
		if dir:
			dir.remove("pokechill_save.json")
	initialize_game()

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
