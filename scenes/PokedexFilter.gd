extends Control

# 图鉴筛选器脚本 - 选项已在场景文件中配置

signal filter_changed

@onready var type_filter = $FilterScroll/FilterVBox/FilterRow1/TypeFilter
@onready var type2_filter = $FilterScroll/FilterVBox/FilterRow1/Type2Filter
@onready var div_filter = $FilterScroll/FilterVBox/FilterRow1/DivFilter
@onready var ability_filter = $FilterScroll/FilterVBox/FilterRow2/AbilityFilter
@onready var shiny_filter = $FilterScroll/FilterVBox/FilterRow2/ShinyFilter
@onready var clear_btn = $FilterScroll/FilterVBox/FilterRow2/ClearButton
@onready var total_label = $FilterScroll/FilterVBox/FilterRow1/TotalLabel
@onready var filter_scroll = $FilterScroll

var search_input: LineEdit
var content_scroll: ScrollContainer

var all_pokemon: Array = []
var filtered_pokemon: Array = []

# 筛选条件
var search_text: String = ""
var type1: String = ""
var type2: String = ""
var division: String = ""
var ability: String = ""
var shiny_only: bool = false
var normal_only: bool = false

const TYPES = ["normal", "fire", "water", "electric", "grass", "ice", "fighting", "poison", "ground", "flying", "psychic", "bug", "rock", "ghost", "dragon", "dark", "steel", "fairy"]

func _ready():
	# 获取兄弟节点
	search_input = get_node("../SearchInput")
	content_scroll = get_node("../ContentScroll")
	
	# 连接信号
	if search_input:
		search_input.text_changed.connect(_on_search_changed)
	
	type_filter.item_selected.connect(_on_filter_selected)
	type2_filter.item_selected.connect(_on_filter_selected)
	div_filter.item_selected.connect(_on_filter_selected)
	ability_filter.item_selected.connect(_on_filter_selected)
	shiny_filter.item_selected.connect(_on_filter_selected)
	clear_btn.pressed.connect(_on_clear_pressed)
	
	# 填充筛选选项
	_fill_filter_options()
	
	# 隐藏滚动条
	_hide_scrollbars(filter_scroll)
	_hide_scrollbars(content_scroll)

func _fill_filter_options():
	# 如果场景中已经有选项，就不重复添加
	if type_filter.item_count > 1:
		return
	
	# Type 1 筛选器
	type_filter.clear()
	type_filter.add_item("All Types", 0)
	for i in range(TYPES.size()):
		type_filter.add_item(TYPES[i].capitalize(), i + 1)
	
	# Type 2 筛选器
	type2_filter.clear()
	type2_filter.add_item("All", 0)
	type2_filter.add_item("None (Single)", 1)
	for i in range(TYPES.size()):
		type2_filter.add_item(TYPES[i].capitalize(), i + 2)
	
	# Division 筛选器
	div_filter.clear()
	div_filter.add_item("All Div", 0)
	div_filter.add_item("S (600+)", 1)
	div_filter.add_item("A (500-599)", 2)
	div_filter.add_item("B (400-499)", 3)
	div_filter.add_item("C (300-399)", 4)
	div_filter.add_item("D (<300)", 5)
	
	# Shiny 筛选器
	shiny_filter.clear()
	shiny_filter.add_item("All", 0)
	shiny_filter.add_item("Shiny Only", 1)
	shiny_filter.add_item("Normal Only", 2)

func _hide_scrollbars(scroll: ScrollContainer):
	if scroll:
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		var v_scroll = scroll.get_v_scroll_bar()
		if v_scroll:
			v_scroll.custom_minimum_size = Vector2(0, 0)
			v_scroll.visible = false

func set_pokemon_data(data: Array):
	all_pokemon = data
	apply_filters()

func apply_filters():
	filtered_pokemon = []
	
	var db = GameManager.get_pokemon_db()
	if not db:
		filtered_pokemon = all_pokemon.duplicate()
		emit_signal("filter_changed", filtered_pokemon)
		return
	
	for pkmn_id in all_pokemon:
		if _is_pokemon_matched(pkmn_id, db):
			filtered_pokemon.append(pkmn_id)
	
	# 更新总数显示
	_update_total_label()
	
	emit_signal("filter_changed", filtered_pokemon)

func _update_total_label():
	if total_label:
		total_label.text = "%d/%d" % [filtered_pokemon.size(), all_pokemon.size()]

func _is_pokemon_matched(pkmn_id: String, db) -> bool:
	var data = db.get_pokemon(pkmn_id)
	if not data:
		return false
	
	var name = pkmn_id.to_lower()
	var types = data.get("types", [])
	var bst = data.get("bst", {})
	
	# 搜索筛选
	if search_text != "" and not search_text in name:
		return false
	
	# Type 1 筛选
	if type1 != "" and not type1 in types:
		return false
	
	# Type 2 筛选 - 修复: 支持单属性宝可梦
	if type2 != "":
		if type2 == "none":
			# 筛选单属性宝可梦
			if types.size() > 1:
				return false
		else:
			# 筛选指定第二属性
			if types.size() < 2 or types[1] != type2:
				return false
	
	# Division 筛选
	if division != "":
		var total = 0
		for v in bst.values():
			total += v
		var pkmn_div = "d"
		if total >= 600: pkmn_div = "s"
		elif total >= 500: pkmn_div = "a"
		elif total >= 400: pkmn_div = "b"
		elif total >= 300: pkmn_div = "c"
		if pkmn_div != division:
			return false
	
	# Shiny/Normal 筛选 (暂未实现，保留接口)
	if shiny_only or normal_only:
		pass  # TODO: 实现闪光筛选
	
	return true

func _on_search_changed(text: String):
	search_text = text.to_lower()
	apply_filters()

func _on_filter_selected(_idx: int):
	if type_filter.selected > 0:
		type1 = TYPES[type_filter.selected - 1]
	else:
		type1 = ""
	
	if type2_filter.selected > 0:
		if type2_filter.selected == 1:
			type2 = "none"  # 单属性
		else:
			type2 = TYPES[type2_filter.selected - 2]
	else:
		type2 = ""
	
	if div_filter.selected > 0:
		var divs = ["s", "a", "b", "c", "d"]
		division = divs[div_filter.selected - 1]
	else:
		division = ""
	
	shiny_only = shiny_filter.selected == 1
	normal_only = shiny_filter.selected == 2
	
	apply_filters()

func _on_clear_pressed():
	if search_input:
		search_input.text = ""
	type_filter.select(0)
	type2_filter.select(0)
	div_filter.select(0)
	ability_filter.select(0)
	shiny_filter.select(0)
	
	search_text = ""
	type1 = ""
	type2 = ""
	division = ""
	ability = ""
	shiny_only = false
	normal_only = false
	
	apply_filters()

func get_filtered_pokemon() -> Array:
	return filtered_pokemon
