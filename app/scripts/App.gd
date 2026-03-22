extends Control

const BACKGROUND_TEXTURE := "res://assets/bg/main-bg.png"
const HERO_TEXTURE := "res://assets/bg/gymCard.png"
const POKEBALL_ICON := "res://assets/icons/pokeball.svg"
const POKEMON_SPRITE_DIR := "res://assets/sprites/pokemon/"
const FACTORY_HISTORY_FILE := "user://battle_factory_history.save"
const FACTORY_TARGET_TEAM_SIZE := 3
const FACTORY_TOTAL_PICKS := 3
const PHONE_WIDTH_THRESHOLD := 520.0

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

const FACTORY_OPTION_COPY := [
	{
		"id": "battle_factory",
		"label": "对战工厂",
		"description": "检查历史记录并进入租借三选一流程。"
	},
	{
		"id": "factory_guide",
		"label": "规则说明",
		"description": "查看对战工厂基础流程与换怪规则。"
	},
	{
		"id": "reward_preview",
		"label": "奖励预览",
		"description": "预览当前赛段可获得的工厂点数与奖励。"
	}
]

@onready var background: TextureRect = $Background
@onready var hero_art: TextureRect = $SafeArea/Root/Content/HeroCard/HeroPadding/HeroContent/HeroHeader/HeroArt
@onready var hero_description: Label = $SafeArea/Root/Content/HeroCard/HeroPadding/HeroContent/HeroHeader/HeroText/HeroDescription
@onready var stat_a_value: Label = $SafeArea/Root/Content/HeroCard/HeroPadding/HeroContent/QuickStats/StatA/StatAPadding/StatABody/StatAValue
@onready var stat_b_value: Label = $SafeArea/Root/Content/HeroCard/HeroPadding/HeroContent/QuickStats/StatB/StatBPadding/StatBBody/StatBValue
@onready var stat_c_value: Label = $SafeArea/Root/Content/HeroCard/HeroPadding/HeroContent/QuickStats/StatC/StatCPadding/StatCBody/StatCValue
@onready var hero_title: Label = $SafeArea/Root/Content/HeroCard/HeroPadding/HeroContent/HeroHeader/HeroText/HeroTitle
@onready var tip_text: Label = $SafeArea/Root/Content/TipCard/TipPadding/TipText
@onready var player_name: Label = $SafeArea/Root/TopBar/TopBarPadding/TopBarRow/TrainerInfo/PlayerName
@onready var status_label: Label = $SafeArea/Root/TopBar/TopBarPadding/TopBarRow/TrainerInfo/StatusLabel
@onready var rank_chip: Label = $SafeArea/Root/TopBar/TopBarPadding/TopBarRow/ResourceInfo/RankChip
@onready var ticket_chip: Label = $SafeArea/Root/TopBar/TopBarPadding/TopBarRow/ResourceInfo/TicketChip

@onready var flow_panel: PanelContainer = $SafeArea/Root/Content/FlowPanel
@onready var flow_title: Label = $SafeArea/Root/Content/FlowPanel/FlowPadding/FlowContent/FlowHeader/FlowTitleBox/FlowTitle
@onready var flow_step: Label = $SafeArea/Root/Content/FlowPanel/FlowPadding/FlowContent/FlowHeader/FlowTitleBox/FlowStep
@onready var flow_body: Label = $SafeArea/Root/Content/FlowPanel/FlowPadding/FlowContent/FlowBody
@onready var option_bar: BoxContainer = $SafeArea/Root/Content/FlowPanel/FlowPadding/FlowContent/OptionBar
@onready var selection_grid: GridContainer = $SafeArea/Root/Content/FlowPanel/FlowPadding/FlowContent/SelectionGrid
@onready var action_row: BoxContainer = $SafeArea/Root/Content/FlowPanel/FlowPadding/FlowContent/ActionRow
@onready var continue_button: Button = $SafeArea/Root/Content/FlowPanel/FlowPadding/FlowContent/ActionRow/ContinueButton
@onready var reset_button: Button = $SafeArea/Root/Content/FlowPanel/FlowPadding/FlowContent/ActionRow/ResetButton
@onready var team_panel: PanelContainer = $SafeArea/Root/Content/FlowPanel/FlowPadding/FlowContent/TeamPanel
@onready var team_status: Label = $SafeArea/Root/Content/FlowPanel/FlowPadding/FlowContent/TeamPanel/TeamPadding/TeamContent/TeamHeader/TeamStatus
@onready var team_icons: HBoxContainer = $SafeArea/Root/Content/FlowPanel/FlowPadding/FlowContent/TeamPanel/TeamPadding/TeamContent/TeamIcons

@onready var pokemon_button: Button = $SafeArea/Root/BottomDock/BottomDockPadding/NavRow/PokemonButton
@onready var dex_button: Button = $SafeArea/Root/BottomDock/BottomDockPadding/NavRow/DexButton
@onready var factory_button: Button = $SafeArea/Root/BottomDock/BottomDockPadding/NavRow/FactoryButtonWrap/FactoryButton
@onready var train_button: Button = $SafeArea/Root/BottomDock/BottomDockPadding/NavRow/TrainButton
@onready var settings_button: Button = $SafeArea/Root/BottomDock/BottomDockPadding/NavRow/SettingsButton
@onready var safe_area: MarginContainer = $SafeArea
@onready var quick_stats: GridContainer = $SafeArea/Root/Content/HeroCard/HeroPadding/HeroContent/QuickStats
@onready var nav_row: HBoxContainer = $SafeArea/Root/BottomDock/BottomDockPadding/NavRow
@onready var factory_button_wrap: CenterContainer = $SafeArea/Root/BottomDock/BottomDockPadding/NavRow/FactoryButtonWrap

var selected_tab := "factory"
var pokemon_catalog: Array = []
var selected_team: Array = ["pikachu"]
var current_choices: Array = []
var pending_selected_pokemon := ""
var battle_history: Dictionary = {}
var option_buttons: Dictionary = {}
var team_icon_cache: Dictionary = {}
var factory_option_expanded := false
var history_checked := false
var pick_round := 0

func _ready() -> void:
	_apply_mobile_theme()
	_apply_art()
	_apply_styles()
	_apply_responsive_layout()
	get_viewport().size_changed.connect(_apply_responsive_layout)
	_load_summary_data()
	_load_pokemon_catalog()
	_load_history()
	_connect_buttons()
	_build_factory_option_bar()
	_refresh_team_icons()
	_reset_factory_flow(false)
	_select_tab(selected_tab)

func _apply_mobile_theme() -> void:
	var root := get_window()
	if root:
		root.min_size = Vector2i(360, 760)

func _apply_responsive_layout() -> void:
	var viewport_size := get_viewport_rect().size
	var is_phone := viewport_size.x <= PHONE_WIDTH_THRESHOLD

	safe_area.add_theme_constant_override("margin_left", 12 if is_phone else 20)
	safe_area.add_theme_constant_override("margin_top", 12 if is_phone else 20)
	safe_area.add_theme_constant_override("margin_right", 12 if is_phone else 20)
	safe_area.add_theme_constant_override("margin_bottom", 12 if is_phone else 20)

	quick_stats.columns = 1 if is_phone else 2
	selection_grid.columns = 2
	nav_row.add_theme_constant_override("separation", 4 if is_phone else 8)
	factory_button_wrap.custom_minimum_size = Vector2(78, 78) if is_phone else Vector2(92, 92)
	factory_button.custom_minimum_size = Vector2(78, 78) if is_phone else Vector2(92, 92)

	var nav_button_height := 56 if is_phone else 62
	for button in [pokemon_button, dex_button, train_button, settings_button]:
		button.custom_minimum_size = Vector2(0, nav_button_height)
		button.add_theme_font_size_override("font_size", 14 if is_phone else 17)
	factory_button.add_theme_font_size_override("font_size", 17 if is_phone else 20)

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
	hero_title.label_settings = title_settings

	var eyebrow_settings := LabelSettings.new()
	eyebrow_settings.font_size = 14
	eyebrow_settings.font_color = Color("#ffd166")
	$SafeArea/Root/Content/HeroCard/HeroPadding/HeroContent/HeroHeader/HeroText/HeroEyebrow.label_settings = eyebrow_settings

	var stat_value_settings := LabelSettings.new()
	stat_value_settings.font_size = 24
	stat_value_settings.font_color = Color("#fefefe")
	stat_a_value.label_settings = stat_value_settings
	stat_b_value.label_settings = stat_value_settings
	stat_c_value.label_settings = stat_value_settings

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
	flow_panel.add_theme_stylebox_override("panel", panel_style)
	team_panel.add_theme_stylebox_override("panel", panel_style)

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

	var action_primary := StyleBoxFlat.new()
	action_primary.bg_color = Color("#ff9f1c")
	action_primary.corner_radius_top_left = 20
	action_primary.corner_radius_top_right = 20
	action_primary.corner_radius_bottom_left = 20
	action_primary.corner_radius_bottom_right = 20
	continue_button.add_theme_stylebox_override("normal", action_primary)
	continue_button.add_theme_stylebox_override("hover", action_primary)
	continue_button.add_theme_stylebox_override("pressed", action_primary)
	continue_button.add_theme_font_size_override("font_size", 18)

	var action_secondary := StyleBoxFlat.new()
	action_secondary.bg_color = Color(1, 1, 1, 0.08)
	action_secondary.corner_radius_top_left = 20
	action_secondary.corner_radius_top_right = 20
	action_secondary.corner_radius_bottom_left = 20
	action_secondary.corner_radius_bottom_right = 20
	reset_button.add_theme_stylebox_override("normal", action_secondary)
	reset_button.add_theme_stylebox_override("hover", action_secondary)
	reset_button.add_theme_stylebox_override("pressed", action_secondary)

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

func _load_pokemon_catalog() -> void:
	pokemon_catalog.clear()
	var pokemon_data := _load_json("res://data/pokemon.json")
	for pokemon_id in pokemon_data.keys():
		var entry: Dictionary = pokemon_data[pokemon_id]
		var types: Array = entry.get("types", [])
		var primary_type := "normal"
		if not types.is_empty():
			primary_type = str(types[0])
		pokemon_catalog.append({
			"id": pokemon_id,
			"name": entry.get("name", pokemon_id.capitalize()),
			"type": primary_type,
			"bst": _sum_bst(entry.get("bst", {}))
		})
	pokemon_catalog.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("bst", 0)) > int(b.get("bst", 0))
	)

func _sum_bst(bst: Dictionary) -> int:
	var total := 0
	for value in bst.values():
		total += int(value)
	return total

func _load_history() -> void:
	battle_history = {}
	if not FileAccess.file_exists(FACTORY_HISTORY_FILE):
		return
	var file := FileAccess.open(FACTORY_HISTORY_FILE, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		battle_history = parsed

func _save_history() -> void:
	var file := FileAccess.open(FACTORY_HISTORY_FILE, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(battle_history))

func _connect_buttons() -> void:
	pokemon_button.pressed.connect(_select_tab.bind("pokemon"))
	dex_button.pressed.connect(_select_tab.bind("dex"))
	factory_button.pressed.connect(_on_factory_button_pressed)
	train_button.pressed.connect(_select_tab.bind("train"))
	settings_button.pressed.connect(_select_tab.bind("settings"))
	continue_button.pressed.connect(_on_continue_pressed)
	reset_button.pressed.connect(_on_reset_pressed)

func _build_factory_option_bar() -> void:
	for child in option_bar.get_children():
		child.queue_free()
	option_buttons.clear()
	for option_data in FACTORY_OPTION_COPY:
		var button := Button.new()
		button.text = "%s\n%s" % [option_data.label, option_data.description]
		button.custom_minimum_size = Vector2(0, 72)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_on_factory_option_pressed.bind(String(option_data.id)))
		_apply_option_button_style(button, false)
		option_bar.add_child(button)
		option_buttons[option_data.id] = button
	option_bar.visible = false

func _apply_option_button_style(button: Button, selected: bool) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#17324f") if not selected else Color("#2a9d8f")
	normal.corner_radius_top_left = 18
	normal.corner_radius_top_right = 18
	normal.corner_radius_bottom_left = 18
	normal.corner_radius_bottom_right = 18
	normal.border_width_left = 1
	normal.border_width_top = 1
	normal.border_width_right = 1
	normal.border_width_bottom = 1
	normal.border_color = Color(1, 1, 1, 0.08)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", normal)
	button.add_theme_stylebox_override("pressed", normal)
	button.add_theme_font_size_override("font_size", 15)

func _on_factory_button_pressed() -> void:
	_select_tab("factory")
	factory_option_expanded = not factory_option_expanded
	option_bar.visible = factory_option_expanded
	if factory_option_expanded:
		flow_title.text = "工厂入口已展开"
		flow_step.text = "STEP 1"
		flow_body.text = "点击中心按钮后出现多个选项。请选择第一个『对战工厂』开始检查历史记录。"
		continue_button.visible = false
		pending_selected_pokemon = ""
		_clear_selection_grid()
	else:
		flow_title.text = "工厂入口已收起"
		flow_step.text = "待命中"
		flow_body.text = "再次点击中心按钮，展开对战工厂选项栏。"
	_update_option_button_states("")

func _on_factory_option_pressed(option_id: String) -> void:
	_update_option_button_states(option_id)
	match option_id:
		"battle_factory":
			_start_battle_factory_flow()
		"factory_guide":
			flow_title.text = "规则说明"
			flow_step.text = "说明"
			flow_body.text = "流程：检查历史记录 → 三选一三轮 → 第三轮可替换旧队员，最终队伍保持 3 只。"
			continue_button.visible = false
			_clear_selection_grid()
		"reward_preview":
			flow_title.text = "奖励预览"
			flow_step.text = "说明"
			flow_body.text = "当前演示版本优先完成工厂入口与选怪逻辑，奖励结算将在后续接入。"
			continue_button.visible = false
			_clear_selection_grid()

func _update_option_button_states(active_id: String) -> void:
	for option_id in option_buttons.keys():
		_apply_option_button_style(option_buttons[option_id], option_id == active_id)

func _start_battle_factory_flow() -> void:
	history_checked = true
	var has_active_history := bool(battle_history.get("has_active_run", false))
	if has_active_history:
		flow_title.text = "发现历史对战记录"
		flow_step.text = "STEP 2-3"
		flow_body.text = "检测到上一轮对战工厂记录。点击『放弃并重新开始』可清空记录并进入新的宝可梦三选一画面。"
		continue_button.text = "继续之前的对战"
		continue_button.visible = true
		continue_button.disabled = false
		_clear_selection_grid()
		_refresh_team_icons()
		return
	_reset_factory_flow(true)

func _on_continue_pressed() -> void:
	if bool(battle_history.get("has_active_run", false)):
		flow_title.text = "历史队伍已恢复"
		flow_step.text = "已恢复"
		selected_team = battle_history.get("team", ["pikachu"])
		pick_round = int(battle_history.get("pick_round", 0))
		flow_body.text = "你可以继续之前的工厂对战，或点击『放弃并重新开始』重置进度。"
		_refresh_team_icons()
		continue_button.visible = false
		return
	if pending_selected_pokemon.is_empty():
		return

	_apply_pending_selection()

func _on_reset_pressed() -> void:
	if bool(battle_history.get("has_active_run", false)):
		battle_history = {}
		_save_history()
	_reset_factory_flow(true)

func _reset_factory_flow(start_selection: bool) -> void:
	selected_team = ["pikachu"]
	pick_round = 0
	pending_selected_pokemon = ""
	battle_history["has_active_run"] = false
	battle_history["team"] = selected_team.duplicate()
	battle_history["pick_round"] = pick_round
	_save_history()
	_refresh_team_icons()
	_update_team_status()
	continue_button.text = "确认选择"
	continue_button.visible = false
	continue_button.disabled = false
	reset_button.text = "放弃并重新开始"
	if start_selection:
		_prepare_next_selection_round()
	else:
		flow_title.text = "对战工厂流程待机"
		flow_step.text = "STEP 0"
		flow_body.text = "1. 点击中心按钮。2. 展开选项栏。3. 选择第一个『对战工厂』进入历史检查与三选一流程。"
		_clear_selection_grid()

func _prepare_next_selection_round() -> void:
	if pick_round >= FACTORY_TOTAL_PICKS:
		_finalize_factory_team()
		return
	pending_selected_pokemon = ""
	current_choices = _generate_choices()
	_render_selection_cards()
	continue_button.visible = false
	flow_title.text = "宝可梦三选一"
	flow_step.text = "STEP %d" % (pick_round + 4)
	var round_text := "第 %d / %d 次选择：选择中的宝可梦会加入队伍。" % [pick_round + 1, FACTORY_TOTAL_PICKS]
	if pick_round == FACTORY_TOTAL_PICKS - 1:
		round_text += " 这是第三次选择，可额外放弃队伍中的一只旧宝可梦，最终保留 3 只。"
	flow_body.text = round_text
	_update_team_status()

func _generate_choices() -> Array:
	var choices: Array = []
	var offset := pick_round * 5
	for entry in pokemon_catalog:
		var pokemon_id := String(entry.get("id", ""))
		if pokemon_id in selected_team:
			continue
		if choices.has(pokemon_id):
			continue
		if offset > 0:
			offset -= 1
			continue
		choices.append(pokemon_id)
		if choices.size() == 3:
			break
	if choices.size() < 3:
		for entry in pokemon_catalog:
			var pokemon_id_fallback := String(entry.get("id", ""))
			if pokemon_id_fallback in selected_team or choices.has(pokemon_id_fallback):
				continue
			choices.append(pokemon_id_fallback)
			if choices.size() == 3:
				break
	return choices

func _render_selection_cards() -> void:
	_clear_selection_grid()
	for pokemon_id in current_choices:
		var card := _create_choice_card(pokemon_id)
		selection_grid.add_child(card)

func _create_choice_card(pokemon_id: String) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 190)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.08)
	style.corner_radius_top_left = 24
	style.corner_radius_top_right = 24
	style.corner_radius_bottom_left = 24
	style.corner_radius_bottom_right = 24
	card.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	card.add_child(margin)

	var content := VBoxContainer.new()
	content.theme_override_constants.separation = 10
	margin.add_child(content)

	var sprite := TextureRect.new()
	sprite.custom_minimum_size = Vector2(88, 88)
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.texture = _load_pokemon_texture(pokemon_id)
	content.add_child(sprite)

	var info := _get_pokemon_display_info(pokemon_id)
	var name_label := Label.new()
	name_label.text = "%s" % info.get("name", pokemon_id.capitalize())
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 18)
	content.add_child(name_label)

	var meta_label := Label.new()
	meta_label.text = "属性：%s  ·  BST %s" % [String(info.get("type", "normal")).capitalize(), str(info.get("bst", 0))]
	meta_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	meta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(meta_label)

	var pick_button := Button.new()
	pick_button.text = "选择这只宝可梦"
	pick_button.pressed.connect(_on_pick_pokemon.bind(pokemon_id))
	content.add_child(pick_button)
	return card

func _on_pick_pokemon(pokemon_id: String) -> void:
	pending_selected_pokemon = pokemon_id
	continue_button.visible = true
	continue_button.text = "确认选择 %s" % _get_pokemon_display_name(pokemon_id)
	flow_body.text = "已选中 %s。点击确认后加入队伍。" % _get_pokemon_display_name(pokemon_id)

func _apply_pending_selection() -> void:
	selected_team.append(pending_selected_pokemon)
	pick_round += 1
	if pick_round == FACTORY_TOTAL_PICKS and selected_team.size() > FACTORY_TARGET_TEAM_SIZE:
		var removed_id := String(selected_team[0])
		selected_team.remove_at(0)
		flow_body.text = "第三次选择完成，已放弃原有队伍的 %s，最终队伍保持 3 只。" % _get_pokemon_display_name(removed_id)
	pending_selected_pokemon = ""
	battle_history["has_active_run"] = pick_round < FACTORY_TOTAL_PICKS
	battle_history["team"] = selected_team.duplicate()
	battle_history["pick_round"] = pick_round
	_save_history()
	_refresh_team_icons()
	_update_team_status()
	if pick_round >= FACTORY_TOTAL_PICKS:
		_finalize_factory_team()
	else:
		_prepare_next_selection_round()

func _finalize_factory_team() -> void:
	_clear_selection_grid()
	continue_button.visible = false
	battle_history["has_active_run"] = false
	battle_history["team"] = selected_team.duplicate()
	battle_history["pick_round"] = pick_round
	_save_history()
	flow_title.text = "队伍组建完成"
	flow_step.text = "STEP 6"
	flow_body.text = "初始携带 1 只宝可梦，并完成 3 次三选一后，队伍最终保留 3 只。右下角图标区已显示当前阵容。"
	_update_team_status()

func _refresh_team_icons() -> void:
	for child in team_icons.get_children():
		child.queue_free()
	for pokemon_id in selected_team:
		team_icons.add_child(_create_team_icon(pokemon_id))

func _create_team_icon(pokemon_id: String) -> Control:
	var wrapper := VBoxContainer.new()
	wrapper.custom_minimum_size = Vector2(74, 0)
	wrapper.alignment = BoxContainer.ALIGNMENT_CENTER

	var sprite := TextureRect.new()
	sprite.custom_minimum_size = Vector2(56, 56)
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.texture = _load_pokemon_texture(pokemon_id)
	wrapper.add_child(sprite)

	var label := Label.new()
	label.text = _get_pokemon_display_name(pokemon_id)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	wrapper.add_child(label)
	return wrapper

func _update_team_status() -> void:
	stat_c_value.text = "%02d / %02d" % [selected_team.size(), FACTORY_TARGET_TEAM_SIZE]
	team_status.text = "当前队伍：%d 只 / 最终目标 %d 只" % [selected_team.size(), FACTORY_TARGET_TEAM_SIZE]

func _load_pokemon_texture(pokemon_id: String) -> Texture2D:
	if team_icon_cache.has(pokemon_id):
		return team_icon_cache[pokemon_id]
	var path := "%s%s.png" % [POKEMON_SPRITE_DIR, pokemon_id]
	var texture: Texture2D = null
	if ResourceLoader.exists(path):
		texture = load(path)
	elif ResourceLoader.exists(POKEBALL_ICON):
		texture = load(POKEBALL_ICON)
	team_icon_cache[pokemon_id] = texture
	return texture

func _get_pokemon_display_info(pokemon_id: String) -> Dictionary:
	for entry in pokemon_catalog:
		if String(entry.get("id", "")) == pokemon_id:
			return entry
	return {"id": pokemon_id, "name": pokemon_id.capitalize(), "type": "normal", "bst": 0}

func _get_pokemon_display_name(pokemon_id: String) -> String:
	return String(_get_pokemon_display_info(pokemon_id).get("name", pokemon_id.capitalize()))

func _clear_selection_grid() -> void:
	for child in selection_grid.get_children():
		child.queue_free()

func _select_tab(tab_id: String) -> void:
	selected_tab = tab_id
	var copy: Dictionary = NAV_COPY.get(tab_id, NAV_COPY["factory"])
	hero_title.text = copy.title
	hero_description.text = copy.description
	_update_button_state()

func _update_button_state() -> void:
	pokemon_button.disabled = selected_tab == "pokemon"
	dex_button.disabled = selected_tab == "dex"
	factory_button.disabled = false
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
