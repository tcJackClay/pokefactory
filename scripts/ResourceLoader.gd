extends Node

const SPRITE_PATH = "res://assets/sprites/pokemon/"
const SHINY_PATH = "res://assets/sprites/shiny/"
const MINI_PATH = "res://assets/sprites/mini/"
const ITEM_PATH = "res://assets/items/"
const ICON_PATH = "res://assets/icons/"
const BG_PATH = "res://assets/bg/"
const DECOR_PATH = "res://assets/decor/"
const TRAINER_PATH = "res://assets/trainers/"

var sprite_cache: Dictionary = {}
var item_cache: Dictionary = {}
var icon_cache: Dictionary = {}
var bg_cache: Dictionary = {}
var decor_cache: Dictionary = {}
var trainer_cache: Dictionary = {}

func _ready():
	print("ResourceLoader initialized")

func get_pokemon_sprite(pokemon_id: String, shiny: bool = false) -> Texture2D:
	var cache_key = pokemon_id + ("_shiny" if shiny else "")
	if cache_key in sprite_cache:
		return sprite_cache[cache_key]
	
	var path = (SHINY_PATH if shiny else SPRITE_PATH) + pokemon_id + ".png"
	var texture = load_texture(path)
	
	if texture:
		sprite_cache[cache_key] = texture
	return texture

func get_pokemon_mini(pokemon_id: String) -> Texture2D:
	if pokemon_id in sprite_cache:
		return sprite_cache[pokemon_id]
	
	var path = MINI_PATH + pokemon_id + ".png"
	var texture = load_texture(path)
	
	if texture:
		sprite_cache[pokemon_id] = texture
	return texture

func get_item_icon(item_id: String) -> Texture2D:
	if item_id in item_cache:
		return item_cache[item_id]
	
	var path = ITEM_PATH + item_id + ".png"
	var texture = load_texture(path)
	
	if texture:
		item_cache[item_id] = texture
	return texture

func get_type_icon(type_name: String) -> Texture2D:
	if type_name in icon_cache:
		return icon_cache[type_name]
	
	var path = ICON_PATH + type_name + ".svg"
	var texture = load_texture(path)
	
	if not texture:
		path = ICON_PATH + type_name + ".png"
		texture = load_texture(path)
	
	if texture:
		icon_cache[type_name] = texture
	return texture

func get_background(bg_name: String) -> Texture2D:
	if bg_name in bg_cache:
		return bg_cache[bg_name]
	
	var path = BG_PATH + bg_name + ".png"
	var texture = load_texture(path)
	
	if texture:
		bg_cache[bg_name] = texture
	return texture

func get_decor(decor_id: String) -> Texture2D:
	if decor_id in decor_cache:
		return decor_cache[decor_id]
	
	var path = DECOR_PATH + decor_id + ".png"
	var texture = load_texture(path)
	
	if texture:
		decor_cache[decor_id] = texture
	return texture

func get_trainer(trainer_id: String) -> Texture2D:
	if trainer_id in trainer_cache:
		return trainer_cache[trainer_id]
	
	var path = TRAINER_PATH + trainer_id + ".png"
	var texture = load_texture(path)
	
	if texture:
		trainer_cache[trainer_id] = texture
	return texture

func load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	return null

func clear_cache():
	sprite_cache.clear()
	item_cache.clear()
	icon_cache.clear()
	bg_cache.clear()
	decor_cache.clear()
	trainer_cache.clear()
