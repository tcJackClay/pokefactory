class_name PokemonDB
extends Resource

## 宝可梦数据库

@export var pokemon: Dictionary = {}

func _init():
	load_data()

func load_data():
	var file = FileAccess.open("res://data/pokemon.json", FileAccess.READ)
	if file:
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		if error == OK:
			pokemon = json.get_data()
		file.close()
		print("Loaded %d Pokemon" % pokemon.size())
	else:
		printerr("Failed to load pokemon.json")

func get_pokemon(id: String) -> Dictionary:
	return pokemon.get(id, {})

func get_pokemon_count() -> int:
	return pokemon.size()

func get_all_pokemon_ids() -> Array:
	return pokemon.keys()

func get_pokemon_by_type(type_name: String) -> Array:
	var result: Array = []
	for id in pokemon:
		var types = pokemon[id].get("types", [])
		if type_name in types:
			result.append(id)
	return result

func get_pokemon_by_division(division: String) -> Array:
	var result: Array = []
	var threshold = {"S": 600, "A": 500, "B": 400, "C": 300, "D": 0}
	var min_bst = threshold.get(division, 0)
	
	for id in pokemon:
		var bst = pokemon[id].get("bst", {})
		var total = 0
		for v in bst.values():
			total += v
		if total >= min_bst and (division == "D" or total < threshold.get(_get_next_division(division), 600)):
			result.append(id)
	return result

func _get_next_division(div: String) -> String:
	var order = ["D", "C", "B", "A", "S"]
	var idx = order.find(div)
	if idx >= 0 and idx < order.size() - 1:
		return order[idx + 1]
	return "S"

func search_pokemon(query: String) -> Array:
	query = query.to_lower()
	var result: Array = []
	for id in pokemon:
		var name = pokemon[id].get("name", "").to_lower()
		if query in id or query in name:
			result.append(id)
	return result
