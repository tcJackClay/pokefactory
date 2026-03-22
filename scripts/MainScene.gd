extends Control

const BG_TEXTURE_PATH := "res://assets/bg/main-bg.png"
const POKEBALL_ICON_PATH := "res://assets/icons/pokeball.svg"
const POKEDEX_SCENE_PATH := "res://scenes/PokedexScreen.tscn"
const BATTLE_FACTORY_SCENE_PATH := "res://scenes/BattleFactoryFlow.tscn"
const FACTORY_OPPONENT_SCENE_PATH := "res://scenes/FactoryOpponentScene.tscn"
const FACTORY_BATTLE_SCENE_PATH := "res://scenes/FactoryBattleScene.tscn"

@onready var background: TextureRect = $Background
@onready var streak_label: Label = $SafeArea/Root/TopBar/TopPadding/TopRow/InfoBox/StreakLabel
@onready var ticket_label: Label = $SafeArea/Root/TopBar/TopPadding/TopRow/InfoBox/TicketLabel
@onready var option_bar: VBoxContainer = $SafeArea/Root/Content/OptionBar
@onready var battle_factory_host: MarginContainer = $SafeArea/Root/Content/BattleFactoryHost
@onready var bottom_dock: PanelContainer = $BottomDock

@onready var team_button: Button = $BottomDock/BottomPadding/NavRow/TeamButton
@onready var dex_button: Button = $BottomDock/BottomPadding/NavRow/DexButton
@onready var factory_button: Button = $BottomDock/BottomPadding/NavRow/FactoryButtonWrap/FactoryButton
@onready var train_button: Button = $BottomDock/BottomPadding/NavRow/TrainButton
@onready var settings_button: Button = $BottomDock/BottomPadding/NavRow/SettingsButton

var option_expanded := false
var option_button: Button
var current_factory_view: Control
var last_player_team_ids: Array = []

func _ready() -> void:
	apply_mobile_window_limits()
	apply_assets()
	apply_styles()
	apply_top_info()
	connect_buttons()
	build_option_bar()
	call_deferred("_apply_bottom_dock_adaptive_spacing")
	get_viewport().size_changed.connect(_apply_bottom_dock_adaptive_spacing)

func apply_mobile_window_limits() -> void:
	var root_window := get_window()
	if root_window:
		root_window.min_size = Vector2i(360, 760)

func apply_assets() -> void:
	if ResourceLoader.exists(BG_TEXTURE_PATH):
		background.texture = load(BG_TEXTURE_PATH)
	if ResourceLoader.exists(POKEBALL_ICON_PATH):
		factory_button.icon = load(POKEBALL_ICON_PATH)
		factory_button.expand_icon = true

func apply_styles() -> void:
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.07, 0.1, 0.18, 0.82)
	panel_style.corner_radius_top_left = 24
	panel_style.corner_radius_top_right = 24
	panel_style.corner_radius_bottom_left = 24
	panel_style.corner_radius_bottom_right = 24
	panel_style.border_width_left = 1
	panel_style.border_width_top = 1
	panel_style.border_width_right = 1
	panel_style.border_width_bottom = 1
	panel_style.border_color = Color(1, 1, 1, 0.12)
	$SafeArea/Root/TopBar.add_theme_stylebox_override("panel", panel_style)
	$BottomDock.add_theme_stylebox_override("panel", panel_style)

	for nav_button in [team_button, dex_button, train_button, settings_button]:
		var normal_style := StyleBoxFlat.new()
		normal_style.bg_color = Color(1, 1, 1, 0.08)
		normal_style.corner_radius_top_left = 22
		normal_style.corner_radius_top_right = 22
		normal_style.corner_radius_bottom_left = 8
		normal_style.corner_radius_bottom_right = 8
		normal_style.content_margin_top = 2
		nav_button.add_theme_stylebox_override("normal", normal_style)
		var active_style := normal_style.duplicate()
		active_style.bg_color = Color(0.2, 0.57, 0.86, 0.9)
		nav_button.add_theme_stylebox_override("hover", active_style)
		nav_button.add_theme_stylebox_override("pressed", active_style)
		nav_button.add_theme_font_size_override("font_size", 15)

	var factory_style := StyleBoxFlat.new()
	factory_style.bg_color = Color("#ef233c")
	factory_style.corner_radius_top_left = 42
	factory_style.corner_radius_top_right = 42
	factory_style.corner_radius_bottom_left = 14
	factory_style.corner_radius_bottom_right = 14
	factory_style.border_width_left = 5
	factory_style.border_width_top = 5
	factory_style.border_width_right = 5
	factory_style.border_width_bottom = 5
	factory_style.border_color = Color(1, 1, 1, 0.95)
	factory_style.shadow_size = 20
	factory_style.shadow_color = Color(0, 0, 0, 0.28)
	factory_button.add_theme_stylebox_override("normal", factory_style)
	var factory_hover := factory_style.duplicate()
	factory_hover.bg_color = Color("#ff3852")
	factory_button.add_theme_stylebox_override("hover", factory_hover)
	factory_button.add_theme_stylebox_override("pressed", factory_hover)
	factory_button.add_theme_font_size_override("font_size", 17)

func apply_top_info() -> void:
	var gm := GameManager.get_instance()
	if gm == null:
		streak_label.text = "Win Streak: 0"
		ticket_label.text = "Factory Tickets: 0"
		return
	var service = gm.get_battle_factory_service() if gm.has_method("get_battle_factory_service") else null
	if service == null:
		streak_label.text = "Win Streak: 0"
		ticket_label.text = "Factory Tickets: 0"
		return
	var state: Dictionary = service.get_state()
	streak_label.text = "Win Streak: %d" % int(state.get("win_streak", 0))
	ticket_label.text = "Factory Tickets: %d" % int(state.get("tickets", 0))

func connect_buttons() -> void:
	factory_button.pressed.connect(_on_factory_pressed)
	team_button.pressed.connect(func() -> void: pass)
	dex_button.pressed.connect(_on_dex_pressed)
	train_button.pressed.connect(func() -> void: pass)
	settings_button.pressed.connect(func() -> void: pass)

func build_option_bar() -> void:
	option_bar.visible = false
	option_button = Button.new()
	option_button.text = "对战工厂\n检查历史记录并进入宝可梦三选一流程"
	option_button.custom_minimum_size = Vector2(0, 64)
	option_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	option_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	apply_option_button_style(option_button, false)
	option_button.pressed.connect(_on_factory_option_pressed)
	option_bar.add_child(option_button)

func apply_option_button_style(button: Button, selected: bool) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#2a9d8f") if selected else Color("#17324f")
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(1, 1, 1, 0.15)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)

func _on_factory_pressed() -> void:
	option_expanded = not option_expanded
	option_bar.visible = option_expanded

func _on_factory_option_pressed() -> void:
	apply_option_button_style(option_button, true)
	show_factory_flow()

func show_factory_flow() -> void:
	var view := _instantiate_scene(BATTLE_FACTORY_SCENE_PATH)
	if view == null:
		return
	_set_factory_view(view)
	if view.has_signal("team_built"):
		view.connect("team_built", _on_factory_team_built)
	if view.has_method("enter_flow"):
		view.call("enter_flow")

func _on_factory_team_built(team_ids: Array) -> void:
	last_player_team_ids = team_ids.duplicate()
	show_opponent_generation(team_ids)

func show_opponent_generation(team_ids: Array) -> void:
	var view := _instantiate_scene(FACTORY_OPPONENT_SCENE_PATH)
	if view == null:
		return
	_set_factory_view(view)
	if view.has_signal("battle_start_requested"):
		view.connect("battle_start_requested", _on_battle_start_requested)
	if view.has_signal("back_requested"):
		view.connect("back_requested", func() -> void:
			show_factory_flow()
		)
	if view.has_method("setup"):
		view.call("setup", team_ids)

func _on_battle_start_requested(player_team_ids: Array, opponent_team_ids: Array) -> void:
	show_battle_scene(player_team_ids, opponent_team_ids)

func show_battle_scene(player_team_ids: Array, opponent_team_ids: Array) -> void:
	var view := _instantiate_scene(FACTORY_BATTLE_SCENE_PATH)
	if view == null:
		return
	_set_factory_view(view)
	if view.has_signal("battle_finished"):
		view.connect("battle_finished", _on_battle_finished)
	if view.has_signal("back_requested"):
		view.connect("back_requested", func() -> void:
			show_opponent_generation(last_player_team_ids)
		)
	if view.has_method("setup"):
		view.call("setup", player_team_ids, opponent_team_ids)

func _on_battle_finished(result: Dictionary) -> void:
	var player_win := bool(result.get("player_win", false))
	if player_win:
		streak_label.text = "Win Streak: %d" % (int(streak_label.text.get_slice(":", 1).strip_edges()) + 1) if ":" in streak_label.text else "Win Streak: 1"
	else:
		streak_label.text = "Win Streak: 0"

func _instantiate_scene(path: String) -> Control:
	if not ResourceLoader.exists(path):
		return null
	var packed: PackedScene = load(path)
	if packed == null:
		return null
	return packed.instantiate()

func _set_factory_view(view: Control) -> void:
	for child in battle_factory_host.get_children():
		child.queue_free()
	current_factory_view = view
	current_factory_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	current_factory_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	battle_factory_host.add_child(current_factory_view)

func _apply_bottom_dock_adaptive_spacing() -> void:
	var reserve := int(max(96.0, bottom_dock.size.y + 14.0))
	battle_factory_host.add_theme_constant_override("margin_bottom", reserve)

func _on_dex_pressed() -> void:
	if ResourceLoader.exists(POKEDEX_SCENE_PATH):
		get_tree().change_scene_to_file(POKEDEX_SCENE_PATH)
