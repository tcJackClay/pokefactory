extends Control

const BACKGROUND_TEXTURE := "res://assets/bg/main-bg.png"
const HERO_TEXTURE := "res://assets/bg/gymCard.png"
const POKEBALL_ICON := "res://assets/icons/pokeball.svg"

const NAV_COPY := {
	"pokemon": {
		"title": "当前宝可梦",
		"description": "查看当前工厂租借阵容、属性覆盖和招式节奏，快速决定下一场轮换对象。"
	},
	"dex": {
		"title": "图鉴",
		"description": "检索可用宝可梦、属性克制与推荐招式，提前规划工厂高连胜路线。"
	},
	"factory": {
		"title": "对战工厂",
		"description": "主玩法入口：开始挑战、挑选租借队伍，并在连战中不断优化你的策略。"
	},
	"train": {
		"title": "训练",
		"description": "进入训练模块，测试配招、模拟属性对局，调整你的工厂战术储备。"
	},
	"settings": {
		"title": "设置",
		"description": "管理音效、震动、显示表现和账号信息，切换更适合移动端的游玩体验。"
	}
}

@onready var background: TextureRect = $Background
@onready var hero_art: TextureRect = $SafeArea/Root/Content/HeroCard/HeroPadding/HeroContent/HeroHeader/HeroArt
@onready var hero_description: Label = $SafeArea/Root/Content/HeroCard/HeroPadding/HeroContent/HeroHeader/HeroText/HeroDescription
@onready var stat_a_value: Label = $SafeArea/Root/Content/HeroCard/HeroPadding/HeroContent/QuickStats/StatA/StatAPadding/StatABody/StatAValue
@onready var stat_b_value: Label = $SafeArea/Root/Content/HeroCard/HeroPadding/HeroContent/QuickStats/StatB/StatBPadding/StatBBody/StatBValue
@onready var hero_title: Label = $SafeArea/Root/Content/HeroCard/HeroPadding/HeroContent/HeroHeader/HeroText/HeroTitle
@onready var tip_text: Label = $SafeArea/Root/Content/TipCard/TipPadding/TipText
@onready var player_name: Label = $SafeArea/Root/TopBar/TopBarPadding/TopBarRow/TrainerInfo/PlayerName
@onready var status_label: Label = $SafeArea/Root/TopBar/TopBarPadding/TopBarRow/TrainerInfo/StatusLabel
@onready var rank_chip: Label = $SafeArea/Root/TopBar/TopBarPadding/TopBarRow/ResourceInfo/RankChip
@onready var ticket_chip: Label = $SafeArea/Root/TopBar/TopBarPadding/TopBarRow/ResourceInfo/TicketChip

@onready var pokemon_button: Button = $SafeArea/Root/BottomDock/BottomDockPadding/NavRow/PokemonButton
@onready var dex_button: Button = $SafeArea/Root/BottomDock/BottomDockPadding/NavRow/DexButton
@onready var factory_button: Button = $SafeArea/Root/BottomDock/BottomDockPadding/NavRow/FactoryButtonWrap/FactoryButton
@onready var train_button: Button = $SafeArea/Root/BottomDock/BottomDockPadding/NavRow/TrainButton
@onready var settings_button: Button = $SafeArea/Root/BottomDock/BottomDockPadding/NavRow/SettingsButton

var selected_tab := "factory"

func _ready() -> void:
	_apply_mobile_theme()
	_apply_art()
	_apply_styles()
	_load_summary_data()
	_connect_buttons()
	_select_tab(selected_tab)

func _apply_mobile_theme() -> void:
	var root := get_window()
	if root:
		root.min_size = Vector2i(360, 760)

func _apply_art() -> void:
	if ResourceLoader.exists(BACKGROUND_TEXTURE):
		background.texture = load(BACKGROUND_TEXTURE)
	if ResourceLoader.exists(HERO_TEXTURE):
		hero_art.texture = load(HERO_TEXTURE)

func _apply_styles() -> void:
	var title_settings := LabelSettings.new()
	title_settings.font_size = 34
	title_settings.outline_size = 8
	title_settings.font_color = Color("#f6fbff")
	title_settings.outline_color = Color(0.02, 0.05, 0.12, 0.6)
	$SafeArea/Root/Content/HeroCard/HeroPadding/HeroContent/HeroHeader/HeroText/HeroTitle.label_settings = title_settings

	var eyebrow_settings := LabelSettings.new()
	eyebrow_settings.font_size = 14
	eyebrow_settings.font_color = Color("#ffd166")
	$SafeArea/Root/Content/HeroCard/HeroPadding/HeroContent/HeroHeader/HeroText/HeroEyebrow.label_settings = eyebrow_settings

	var stat_value_settings := LabelSettings.new()
	stat_value_settings.font_size = 24
	stat_value_settings.font_color = Color("#fefefe")
	stat_a_value.label_settings = stat_value_settings
	stat_b_value.label_settings = stat_value_settings
	$SafeArea/Root/Content/HeroCard/HeroPadding/HeroContent/QuickStats/StatC/StatCPadding/StatCBody/StatCValue.label_settings = stat_value_settings

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.07, 0.11, 0.2, 0.76)
	panel_style.corner_radius_top_left = 28
	panel_style.corner_radius_top_right = 28
	panel_style.corner_radius_bottom_right = 28
	panel_style.corner_radius_bottom_left = 28
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(1, 1, 1, 0.12)
	panel_style.shadow_size = 18
	panel_style.shadow_color = Color(0, 0, 0, 0.28)
	$SafeArea/Root/Content/HeroCard.add_theme_stylebox_override("panel", panel_style)
	$SafeArea/Root/TopBar.add_theme_stylebox_override("panel", panel_style)
	$SafeArea/Root/BottomDock.add_theme_stylebox_override("panel", panel_style)

	var tip_style := StyleBoxFlat.new()
	tip_style.bg_color = Color(0.98, 0.84, 0.36, 0.14)
	tip_style.corner_radius_top_left = 22
	tip_style.corner_radius_top_right = 22
	tip_style.corner_radius_bottom_right = 22
	tip_style.corner_radius_bottom_left = 22
	tip_style.border_width_left = 1
	tip_style.border_width_top = 1
	tip_style.border_width_right = 1
	tip_style.border_width_bottom = 1
	tip_style.border_color = Color(0.98, 0.84, 0.36, 0.35)
	$SafeArea/Root/Content/TipCard.add_theme_stylebox_override("panel", tip_style)

	for stat_panel in [
		$SafeArea/Root/Content/HeroCard/HeroPadding/HeroContent/QuickStats/StatA,
		$SafeArea/Root/Content/HeroCard/HeroPadding/HeroContent/QuickStats/StatB,
		$SafeArea/Root/Content/HeroCard/HeroPadding/HeroContent/QuickStats/StatC
	]:
		var stat_style := StyleBoxFlat.new()
		stat_style.bg_color = Color(1, 1, 1, 0.08)
		stat_style.corner_radius_top_left = 20
		stat_style.corner_radius_top_right = 20
		stat_style.corner_radius_bottom_right = 20
		stat_style.corner_radius_bottom_left = 20
		stat_panel.add_theme_stylebox_override("panel", stat_style)

	_apply_chip_style(rank_chip, Color("#ff6b6b"))
	_apply_chip_style(ticket_chip, Color("#4cc9f0"))
	_apply_button_styles()
	_apply_pokeball_icon()

func _apply_chip_style(label: Label, accent: Color) -> void:
	label.add_theme_color_override("font_color", accent.lightened(0.25))
	label.add_theme_font_size_override("font_size", 15)

func _apply_button_styles() -> void:
	for button in [pokemon_button, dex_button, train_button, settings_button]:
		var normal := StyleBoxFlat.new()
		normal.bg_color = Color(1, 1, 1, 0.08)
		normal.corner_radius_top_left = 24
		normal.corner_radius_top_right = 24
		normal.corner_radius_bottom_right = 24
		normal.corner_radius_bottom_left = 24
		normal.content_margin_left = 10
		normal.content_margin_right = 10
		button.add_theme_stylebox_override("normal", normal)
		var pressed := normal.duplicate()
		pressed.bg_color = Color("#2a9d8f")
		button.add_theme_stylebox_override("pressed", pressed)
		button.add_theme_stylebox_override("hover", pressed)
		button.add_theme_font_size_override("font_size", 17)

	var primary := StyleBoxFlat.new()
	primary.bg_color = Color("#ef233c")
	primary.corner_radius_top_left = 54
	primary.corner_radius_top_right = 54
	primary.corner_radius_bottom_right = 54
	primary.corner_radius_bottom_left = 54
	primary.shadow_size = 22
	primary.shadow_color = Color(0, 0, 0, 0.25)
	primary.border_width_left = 6
	primary.border_width_top = 6
	primary.border_width_right = 6
	primary.border_width_bottom = 6
	primary.border_color = Color.WHITE
	factory_button.add_theme_stylebox_override("normal", primary)
	var primary_hover := primary.duplicate()
	primary_hover.bg_color = Color("#f94144")
	factory_button.add_theme_stylebox_override("hover", primary_hover)
	factory_button.add_theme_stylebox_override("pressed", primary_hover)
	factory_button.add_theme_font_size_override("font_size", 20)

func _apply_pokeball_icon() -> void:
	if ResourceLoader.exists(POKEBALL_ICON):
		factory_button.icon = load(POKEBALL_ICON)
		factory_button.expand_icon = true

func _load_summary_data() -> void:
	var pokemon_data := _load_json("res://data/pokemon.json")
	var item_data := _load_json("res://data/items.json")
	stat_a_value.text = str(pokemon_data.size())
	stat_b_value.text = str(item_data.size())
	player_name.text = "Factory Master"
	status_label.text = "霓虹都市 · 数据已同步 %s 项" % pokemon_data.size()
	tip_text.text = "今日工厂词条：可租借 %s 只宝可梦、%s 种战术道具，建议优先围绕高速控场构筑。" % [pokemon_data.size(), item_data.size()]

func _connect_buttons() -> void:
	pokemon_button.pressed.connect(_select_tab.bind("pokemon"))
	dex_button.pressed.connect(_select_tab.bind("dex"))
	factory_button.pressed.connect(_select_tab.bind("factory"))
	train_button.pressed.connect(_select_tab.bind("train"))
	settings_button.pressed.connect(_select_tab.bind("settings"))

func _select_tab(tab_id: String) -> void:
	selected_tab = tab_id
	var copy: Dictionary = NAV_COPY.get(tab_id, NAV_COPY["factory"])
	hero_title.text = copy.title
	hero_description.text = copy.description
	_update_button_state()

func _update_button_state() -> void:
	pokemon_button.disabled = selected_tab == "pokemon"
	dex_button.disabled = selected_tab == "dex"
	factory_button.disabled = selected_tab == "factory"
	train_button.disabled = selected_tab == "train"
	settings_button.disabled = selected_tab == "settings"

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
