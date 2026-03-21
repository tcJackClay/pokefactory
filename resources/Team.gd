class_name Team
extends Resource

## 队伍数据类

@export_group("队伍信息")
@export var name: String = "Team 1"
@export var slots: Array = []

func _init():
	slots = []
	for i in range(6):
		slots.append(TeamSlot.new())

func get_active_pokemon() -> Array:
	var result = []
	for s in slots:
		if s and s.pokemon != null and s.pokemon.is_alive():
			result.append(s.pokemon)
	return result

func get_pokemon_count() -> int:
	var count = 0
	for s in slots:
		if s and s.pokemon != null:
			count += 1
	return count

func add_pokemon(pokemon, slot: int = -1) -> bool:
	if slot < 0:
		for i in range(6):
			if slots[i] and slots[i].pokemon == null:
				slot = i
				break
		if slot < 0:
			return false
	
	if slot >= 0 and slot < 6:
		if slots[slot]:
			slots[slot].pokemon = pokemon
			if pokemon:
				pokemon.slot = slot
			return true
	return false

func remove_pokemon(slot: int):
	if slot >= 0 and slot < 6 and slots[slot]:
		var removed = slots[slot].pokemon
		slots[slot].pokemon = null
		return removed
	return null

func swap_pokemon(slot1: int, slot2: int) -> bool:
	if slot1 >= 0 and slot1 < 6 and slot2 >= 0 and slot2 < 6:
		if slots[slot1] and slots[slot2]:
			var temp = slots[slot1].pokemon
			slots[slot1].pokemon = slots[slot2].pokemon
			slots[slot2].pokemon = temp
			return true
	return false

func get_leader():
	for s in slots:
		if s and s.pokemon:
			return s.pokemon
	return null

func heal_all():
	for s in slots:
		if s and s.pokemon:
			s.pokemon.full_heal()

func to_dict() -> Dictionary:
	var slots_data = []
	for s in slots:
		if s:
			slots_data.append(s.to_dict())
	return {
		"name": name,
		"slots": slots_data
	}


class TeamSlot:
	var pokemon = null
	var turn_order: int = 1
	var buffs: Dictionary = {}
	var item: String = ""
	
	func to_dict() -> Dictionary:
		return {
			"pokemon": pokemon.to_dict() if pokemon else null,
			"turn_order": turn_order,
			"buffs": buffs,
			"item": item
		}


class TeamManager:
	static var current_team: Team = Team.new()
	static var preview_teams: Dictionary = {}
	
	static func create_new_team() -> Team:
		current_team = Team.new()
		return current_team
	
	static func get_team() -> Team:
		return current_team
	
	static func add_pokemon(pokemon, slot: int = -1) -> bool:
		return current_team.add_pokemon(pokemon, slot)
	
	static func get_active_count() -> int:
		return current_team.get_active_pokemon().size()
	
	static func is_team_alive() -> bool:
		return current_team.get_active_pokemon().size() > 0
	
	static func save_team_data() -> Dictionary:
		return current_team.to_dict()
	
	static func load_team_data(data: Dictionary):
		current_team.name = data.get("name", "Team 1")
		var slots_data = data.get("slots", [])
		for i in range(min(slots_data.size(), 6)):
			var slot_data = slots_data[i]
			if slot_data and slot_data.get("pokemon"):
				var pkmn_data = slot_data["pokemon"]
				var pkmn_script = load("res://scripts/Pokemon.gd")
				if pkmn_script:
					var instance = pkmn_script.PokemonInstance.new()
					instance.base_id = pkmn_data.get("id", "")
					instance.level = pkmn_data.get("level", 1)
					instance.shiny = pkmn_data.get("shiny", false)
					instance.ability = pkmn_data.get("ability", "")
					instance.item = pkmn_data.get("item", "")
					instance.status = pkmn_data.get("status", "")
					current_team.slots[i].pokemon = instance
