extends Control

const NAV_ITEMS := [
	{
		"id": "home",
		"label": "首页",
		"title": "首页",
		"body": "当前显示首页概览。后续可以在这里接入主玩法、任务流或运营活动入口。",
		"features": ["素材总览", "项目状态提示", "快捷入口预留"]
	},
	{
		"id": "collection",
		"label": "图鉴",
		"title": "图鉴 / 素材库",
		"body": "用于承接宝可梦图鉴、角色插图、道具插画等内容浏览能力，适合做列表 + 详情的移动端体验。",
		"features": ["图片资源复用", "搜索筛选位", "详情页容器"]
	},
	{
		"id": "adventure",
		"label": "探索",
		"title": "探索 / 玩法",
		"body": "预留关卡、地图、剧情推进与战斗流入口，后续可以按你的安排继续细化具体玩法。",
		"features": ["玩法入口卡片", "流程状态机预留", "触屏操作区"]
	},
	{
		"id": "settings",
		"label": "设置",
		"title": "设置 / 开发面板",
		"body": "用于放置音量、性能、账号、本地缓存以及开发期调试开关，方便后续持续扩展。",
		"features": ["系统设置", "资源版本信息", "调试入口预留"]
	}
]

const TRAINER_PREVIEW := "res://assets/trainers/cynthia.png"
const FEATURE_CARD_SCRIPT := preload("res://app/scripts/FeatureCard.gd")

@onready var trainer_texture: TextureRect = $SafeArea/Root/HeaderCard/HeaderPadding/HeaderContent/HeroRow/TrainerTexture
@onready var pokemon_stat_value: Label = $SafeArea/Root/StatsGrid/PokemonStat/PokemonStatPadding/PokemonStatBody/PokemonStatValue
@onready var item_stat_value: Label = $SafeArea/Root/StatsGrid/ItemStat/ItemStatPadding/ItemStatBody/ItemStatValue
@onready var hero_body: Label = $SafeArea/Root/HeaderCard/HeaderPadding/HeaderContent/HeroRow/HeroSummary/HeroBody
@onready var screen_title: Label = $SafeArea/Root/MainPanel/MainPadding/MainContent/ScreenTitle
@onready var screen_body: Label = $SafeArea/Root/MainPanel/MainPadding/MainContent/ScreenBody
@onready var feature_list: VBoxContainer = $SafeArea/Root/MainPanel/MainPadding/MainContent/FeatureList
@onready var nav_buttons: HBoxContainer = $SafeArea/Root/BottomNav/BottomNavPadding/NavButtons

var selected_tab := "home"

func _ready() -> void:
	_apply_mobile_theme()
	_load_summary_data()
	_load_preview_image()
	_build_navigation()
	_show_screen(selected_tab)

func _apply_mobile_theme() -> void:
	var root := get_window()
	if root:
		root.min_size = Vector2i(360, 740)

func _load_summary_data() -> void:
	var pokemon_data := _load_json("res://data/pokemon.json")
	var item_data := _load_json("res://data/items.json")
	pokemon_stat_value.text = str(pokemon_data.size())
	item_stat_value.text = str(item_data.size())
	hero_body.text = "已保留 %s 个宝可梦文本条目与 %s 个道具文本条目，原始图片素材目录也继续沿用。" % [pokemon_data.size(), item_data.size()]

func _load_preview_image() -> void:
	if ResourceLoader.exists(TRAINER_PREVIEW):
		trainer_texture.texture = load(TRAINER_PREVIEW)

func _build_navigation() -> void:
	for child in nav_buttons.get_children():
		child.queue_free()

	for item in NAV_ITEMS:
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
	_clear_feature_cards()
	for feature in tab.features:
		var card := PanelContainer.new()
		card.set_script(FEATURE_CARD_SCRIPT)
		feature_list.add_child(card)
		card.call("setup", feature)
	_update_nav_state()

func _clear_feature_cards() -> void:
	for child in feature_list.get_children():
		child.queue_free()

func _update_nav_state() -> void:
	for index in range(nav_buttons.get_child_count()):
		var button := nav_buttons.get_child(index) as Button
		var item: Dictionary = NAV_ITEMS[index]
		button.disabled = item.id == selected_tab

func _on_nav_pressed(tab_id: String) -> void:
	_show_screen(tab_id)

func _get_tab(tab_id: String) -> Dictionary:
	for item in NAV_ITEMS:
		if item.id == tab_id:
			return item
	return NAV_ITEMS[0]

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
