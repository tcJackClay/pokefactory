extends Control

const TRAINER_PREVIEW := "res://assets/trainers/cynthia.png"
const FEATURE_CARD_SCRIPT := preload("res://app/scripts/FeatureCard.gd")
const TYPE_EFFECTIVENESS_SCRIPT := preload("res://resources/TypeEffectiveness.gd")

const TAB_DEFINITIONS := [
	{
		"id": "factory",
		"label": "工厂",
		"title": "对战工厂核心循环",
		"body": "玩家只带 1 只初始宝可梦开局；每次战斗结束后，系统随机展示 3 只候选宝可梦，玩家挑选并维持 3 人小队，目标是冲击 50 连胜。",
		"features": ["初始宝可梦 → 战斗 → 三选一补强 → 下一战", "围绕 3 人小队做换位、属性覆盖与节奏管理", "局内成长优先服务连胜，而不是长期养成拖慢流程"]
	},
	{
		"id": "squad",
		"label": "编队",
		"title": "3 人小队与轮换策略",
		"body": "每局都强调即时编队：首发节奏、抗性轮转、收割位和属性补盲都需要在手机纵屏上一眼看清。",
		"features": ["固定展示 3 个主力槽位，便于拇指操作", "战后招募直接比较属性、种族值与定位", "用紧凑卡片呈现招式、特性、进化潜力与克制关系"]
	},
	{
		"id": "systems",
		"label": "系统",
		"title": "完整保留宝可梦系统",
		"body": "宝可梦数据、图形资源、升级进化、属性克制、招式与道具等基础规则都继续保留；这次主要重构的是移动端 UI 与工厂模式流程。",
		"features": ["沿用现有宝可梦 / 招式 / 道具 / 属性数据库", "保留升级与进化条件，支持战局内成长演出", "属性相性继续作为战斗决策核心信息"]
	},
	{
		"id": "mobile",
		"label": "界面",
		"title": "手机优先的界面方向",
		"body": "整体形态参考 PokeChill 的移动端信息层级：顶部概览、中部主卡片、底部拇指导航，让战斗工厂的关键信息集中在单手可达区域。",
		"features": ["纵屏安全区布局 + 底部导航", "首页浓缩当前连胜、队伍、招募与下个对手", "后续可继续接入触屏战斗按钮、队伍详情弹层与图鉴检索"]
	}
]

var selected_tab := "factory"
var featured_team: Array[Dictionary] = []
var recruit_choices: Array[Dictionary] = []
var opponent_preview: Dictionary = {}
var starter_preview: Dictionary = {}
var type_effectiveness: TypeEffectiveness

@onready var trainer_texture: TextureRect = $SafeArea/Root/HeaderCard/HeaderPadding/HeaderContent/HeroRow/TrainerTexture
@onready var hero_title: Label = $SafeArea/Root/HeaderCard/HeaderPadding/HeaderContent/Title
@onready var hero_body: Label = $SafeArea/Root/HeaderCard/HeaderPadding/HeaderContent/HeroRow/HeroSummary/HeroBody
@onready var pokemon_stat_value: Label = $SafeArea/Root/StatsGrid/PokemonStat/PokemonStatPadding/PokemonStatBody/PokemonStatValue
@onready var move_stat_value: Label = $SafeArea/Root/StatsGrid/MoveStat/MoveStatPadding/MoveStatBody/MoveStatValue
@onready var item_stat_value: Label = $SafeArea/Root/StatsGrid/ItemStat/ItemStatPadding/ItemStatBody/ItemStatValue
@onready var type_stat_value: Label = $SafeArea/Root/StatsGrid/TypeStat/TypeStatPadding/TypeStatBody/TypeStatValue
@onready var run_value: Label = $SafeArea/Root/RunOverview/RunPadding/RunContent/RunRow/RunCard/RunCardPadding/RunCardBody/RunValue
@onready var stage_value: Label = $SafeArea/Root/RunOverview/RunPadding/RunContent/RunRow/StageCard/StageCardPadding/StageCardBody/StageValue
@onready var starter_value: Label = $SafeArea/Root/RunOverview/RunPadding/RunContent/RunStarter
@onready var opponent_value: Label = $SafeArea/Root/RunOverview/RunPadding/RunContent/RunOpponent
@onready var team_list: VBoxContainer = $SafeArea/Root/TeamPanel/TeamPadding/TeamContent/TeamList
@onready var recruit_list: VBoxContainer = $SafeArea/Root/RecruitPanel/RecruitPadding/RecruitContent/RecruitList
@onready var screen_title: Label = $SafeArea/Root/MainPanel/MainPadding/MainContent/ScreenTitle
@onready var screen_body: Label = $SafeArea/Root/MainPanel/MainPadding/MainContent/ScreenBody
@onready var feature_list: VBoxContainer = $SafeArea/Root/MainPanel/MainPadding/MainContent/FeatureList
@onready var nav_buttons: HBoxContainer = $SafeArea/Root/BottomNav/BottomNavPadding/NavButtons

func _ready() -> void:
	_apply_mobile_theme()
	type_effectiveness = TYPE_EFFECTIVENESS_SCRIPT.new()
	_load_preview_image()
	_load_summary_data()
	_build_factory_preview()
	_render_team_preview()
	_render_recruit_choices()
	_build_navigation()
	_show_screen(selected_tab)

func _apply_mobile_theme() -> void:
	var root := get_window()
	if root:
		root.min_size = Vector2i(360, 740)

func _load_preview_image() -> void:
	if ResourceLoader.exists(TRAINER_PREVIEW):
		trainer_texture.texture = load(TRAINER_PREVIEW)

func _load_summary_data() -> void:
	var pokemon_data := _load_json("res://data/pokemon.json")
	var move_data := _load_json("res://data/moves.json")
	var item_data := _load_json("res://data/items.json")
	pokemon_stat_value.text = str(pokemon_data.size())
	move_stat_value.text = str(move_data.size())
	item_stat_value.text = str(item_data.size())
	type_stat_value.text = str(type_effectiveness.all_types.size())
	hero_title.text = "PokeFactory：50 连胜对战工厂"
	hero_body.text = "保留现有宝可梦图形、数据、升级进化与属性机制，并把体验收束到手机纵屏的对战工厂循环。"

func _build_factory_preview() -> void:
	var pokemon_data := _load_json("res://data/pokemon.json")
	var ids: Array = pokemon_data.keys()
	if ids.is_empty():
		return

	starter_preview = pokemon_data.get("eevee", pokemon_data[ids[0]])
	featured_team = [
		starter_preview,
		pokemon_data.get("azumarill", pokemon_data[ids[min(25, ids.size() - 1)]]),
		pokemon_data.get("talonflame", pokemon_data[ids[min(50, ids.size() - 1)]])
	]
	recruit_choices = [
		pokemon_data.get("metagross", pokemon_data[ids[min(80, ids.size() - 1)]]),
		pokemon_data.get("rotomWash", pokemon_data[ids[min(120, ids.size() - 1)]]),
		pokemon_data.get("garchomp", pokemon_data[ids[min(160, ids.size() - 1)]])
	]
	opponent_preview = pokemon_data.get("gengar", pokemon_data[ids[min(200, ids.size() - 1)]])

	run_value.text = "12 / 50"
	stage_value.text = "第 13 战"
	starter_value.text = "初始宝可梦：%s" % _format_pokemon_summary(starter_preview)
	opponent_value.text = "下个对手：%s" % _format_pokemon_summary(opponent_preview)

func _render_team_preview() -> void:
	_clear_container(team_list)
	for index in range(featured_team.size()):
		var pokemon: Dictionary = featured_team[index]
		var slot_title := "槽位 %d · %s" % [index + 1, pokemon.get("name", pokemon.get("id", "未知宝可梦"))]
		var description := "%s｜BST %d｜%s" % [
			_format_types(pokemon.get("types", [])),
			_calculate_bst(pokemon),
			_describe_evolution(pokemon)
		]
		team_list.add_child(_create_info_card(slot_title, description))

func _render_recruit_choices() -> void:
	_clear_container(recruit_list)
	for pokemon in recruit_choices:
		var best_attack := _build_best_attack_line(pokemon)
		var description := "%s｜BST %d｜%s" % [
			_format_types(pokemon.get("types", [])),
			_calculate_bst(pokemon),
			best_attack
		]
		recruit_list.add_child(_create_info_card(pokemon.get("name", "未知候选"), description))

func _build_navigation() -> void:
	for child in nav_buttons.get_children():
		child.queue_free()

	for item in TAB_DEFINITIONS:
		var button := Button.new()
		button.text = item.label
		button.custom_minimum_size = Vector2(0, 56)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_on_nav_pressed.bind(item.id))
		nav_buttons.add_child(button)

func _show_screen(tab_id: String) -> void:
	selected_tab = tab_id
	var tab := _get_tab(tab_id)
	screen_title.text = tab.title
	screen_body.text = tab.body
	_clear_container(feature_list)
	for feature in tab.features:
		var card := PanelContainer.new()
		card.set_script(FEATURE_CARD_SCRIPT)
		feature_list.add_child(card)
		card.call("setup", feature)
	_update_nav_state()

func _update_nav_state() -> void:
	for index in range(nav_buttons.get_child_count()):
		var button := nav_buttons.get_child(index) as Button
		var item: Dictionary = TAB_DEFINITIONS[index]
		button.disabled = item.id == selected_tab

func _on_nav_pressed(tab_id: String) -> void:
	_show_screen(tab_id)

func _get_tab(tab_id: String) -> Dictionary:
	for item in TAB_DEFINITIONS:
		if item.id == tab_id:
			return item
	return TAB_DEFINITIONS[0]

func _format_pokemon_summary(pokemon: Dictionary) -> String:
	return "%s（%s）" % [pokemon.get("name", pokemon.get("id", "未知")), _format_types(pokemon.get("types", []))]

func _format_types(types: Array) -> String:
	if types.is_empty():
		return "未知属性"
	var parts: Array[String] = []
	for type_name in types:
		parts.append(type_effectiveness.get_type_name_cn(str(type_name)))
	return "/".join(parts)

func _describe_evolution(pokemon: Dictionary) -> String:
	var evolve_to := str(pokemon.get("evolve_to", ""))
	if evolve_to.is_empty():
		return "最终形态或特殊进化"
	var evolve_level = pokemon.get("evolve_level", null)
	if evolve_level == null:
		return "可进化为 %s" % evolve_to
	return "Lv.%s 进化为 %s" % [str(evolve_level), evolve_to]

func _build_best_attack_line(pokemon: Dictionary) -> String:
	var attack_types: Array = pokemon.get("types", [])
	if attack_types.is_empty():
		return "属性覆盖待定"
	var coverage: Array[String] = []
	for attack_type in attack_types:
		var targets := type_effectiveness.get_attacks_super_effective(str(attack_type))
		if targets.is_empty():
			continue
		var preview := targets.slice(0, min(3, targets.size()))
		var preview_names: Array[String] = []
		for defend_type in preview:
			preview_names.append(type_effectiveness.get_type_name_cn(str(defend_type)))
		coverage.append("%s克%s" % [type_effectiveness.get_type_name_cn(str(attack_type)), "/".join(preview_names)])
	if coverage.is_empty():
		return "属性覆盖待定"
	return coverage[0]

func _calculate_bst(pokemon: Dictionary) -> int:
	var total := 0
	var bst: Dictionary = pokemon.get("bst", {})
	for value in bst.values():
		total += int(value)
	return total

func _create_info_card(title: String, body: String) -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	card.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	margin.add_child(column)
	var title_label := Label.new()
	title_label.text = title
	column.add_child(title_label)
	var body_label := Label.new()
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.text = body
	column.add_child(body_label)
	return card

func _clear_container(container: Container) -> void:
	for child in container.get_children():
		child.queue_free()

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		return parsed
	return {}
