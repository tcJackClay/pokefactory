class_name MoveDB
extends Resource

## 技能数据库

@export var moves: Dictionary = {}

func _init():
	load_data()

func load_data():
	var file = FileAccess.open("res://data/moves.json", FileAccess.READ)
	if file:
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		if error == OK:
			moves = json.get_data()
		file.close()
		print("Loaded %d moves" % moves.size())
	else:
		printerr("Failed to load moves.json")

func get_move(id: String) -> Dictionary:
	return moves.get(id, {})

func get_move_count() -> int:
	return moves.size()

func get_all_move_ids() -> Array:
	return moves.keys()

func get_moves_by_type(type_name: String) -> Array:
	var result: Array = []
	for id in moves:
		if moves[id].get("type") == type_name:
			result.append(id)
	return result

func get_moves_by_category(category: int) -> Array:
	var result: Array = []
	for id in moves:
		if moves[id].get("category") == category:
			result.append(id)
	return result

func get_damaging_moves() -> Array:
	var result: Array = []
	for id in moves:
		var move = moves[id]
		if move.get("power", 0) > 0 and move.get("category", 2) != 2:
			result.append(id)
	return result

func get_status_moves() -> Array:
	var result: Array = []
	for id in moves:
		if moves[id].get("category", 2) == 2:
			result.append(id)
	return result

func get_moves_by_power(min_power: int) -> Array:
	var result: Array = []
	for id in moves:
		if moves[id].get("power", 0) >= min_power:
			result.append(id)
	return result

func search_moves(query: String) -> Array:
	query = query.to_lower()
	var result: Array = []
	for id in moves:
		var name = id.to_lower()
		if query in name:
			result.append(id)
	return result
