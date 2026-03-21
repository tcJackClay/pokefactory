extends Node2D

var loading_progress: ProgressBar
var loading_label: Label
var load_step = 0

func _ready():
	loading_progress = $CanvasLayer/LoadingUI/Center/VBox/ProgressBar
	loading_label = $CanvasLayer/LoadingUI/Center/VBox/StatusLabel
	
	# 立即开始加载
	start_loading()

func start_loading():
	load_step = 0
	loading_progress.value = 0
	
	# 开始加载流程
	_load_step1_pokemon()

func _load_step1_pokemon():
	load_step += 1
	loading_progress.value = load_step
	loading_label.text = "Loading Pokemon..."
	
	await get_tree().create_timer(0.5).timeout
	_load_step2_moves()

func _load_step2_moves():
	load_step += 1
	loading_progress.value = load_step
	loading_label.text = "Loading moves..."
	await get_tree().create_timer(0.3).timeout
	_load_step3_items()

func _load_step3_items():
	load_step += 1
	loading_progress.value = load_step
	loading_label.text = "Loading items..."
	await get_tree().create_timer(0.3).timeout
	_load_step4_areas()

func _load_step4_areas():
	load_step += 1
	loading_progress.value = load_step
	loading_label.text = "Loading areas..."
	await get_tree().create_timer(0.3).timeout
	_load_step5_abilities()

func _load_step5_abilities():
	load_step += 1
	loading_progress.value = load_step
	loading_label.text = "Loading abilities..."
	await get_tree().create_timer(0.3).timeout
	_load_step6_finish()

func _load_step6_finish():
	load_step += 1
	loading_progress.value = load_step
	loading_label.text = "Ready!"
	
	await get_tree().create_timer(0.5).timeout
	
	# 切换到主场景
	get_tree().change_scene_to_file("res://scenes/MainScene.tscn")
