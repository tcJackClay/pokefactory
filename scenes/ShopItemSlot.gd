class_name ShopItemSlot
extends PanelContainer

## 商店道具槽位组件

signal item_clicked(item_id: String)
signal item_buy_clicked(item_id: String)

@export var item_id: String = ""
@export var price: int = 0
@export var stock: int = -1  # -1 = 无限

# UI组件
var icon: TextureRect
var name_label: Label
var price_label: Label
var stock_label: Label
var buy_button: Button

func _ready():
	setup_shop_item_ui()

func setup_shop_item_ui():
	custom_minimum_size = Vector2(180, 80)
	
	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 10)
	add_child(hbox)
	
	# 图标
	icon = TextureRect.new()
	icon.name = "Icon"
	icon.custom_minimum_size = Vector2(50, 50)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hbox.add_child(icon)
	
	# 信息区域
	var info_vbox = VBoxContainer.new()
	info_vbox.add_theme_constant_override("separation", 2)
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)
	
	# 名称
	name_label = Label.new()
	name_label.name = "Name"
	name_label.text = "---"
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_child(name_label)
	
	# 价格
	price_label = Label.new()
	price_label.name = "Price"
	price_label.text = "¥0"
	price_label.modulate = Color(1, 0.8, 0.3)
	info_vbox.add_child(price_label)
	
	# 库存
	stock_label = Label.new()
	stock_label.name = "Stock"
	stock_label.text = ""
	stock_label.add_theme_font_size_override("font_size", 10)
	info_vbox.add_child(stock_label)
	
	# 购买按钮
	buy_button = Button.new()
	buy_button.name = "BuyButton"
	buy_button.text = "Buy"
	buy_button.custom_minimum_size = Vector2(50, 30)
	buy_button.pressed.connect(_on_buy_pressed)
	hbox.add_child(buy_button)
	
	# 点击整个条目查看详情
	gui_input.connect(_on_gui_input)

func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			item_clicked.emit(item_id)

func _on_buy_pressed():
	item_buy_clicked.emit(item_id)

## 更新显示
func update_display(item_id: String, data: Dictionary, item_price: int = 0, item_stock: int = -1):
	item_id = item_id
	price = item_price
	stock = item_stock
	
	# 名称
	name_label.text = data.get("name", item_id)
	
	# 价格
	price_label.text = "¥%d" % price
	
	# 库存
	if stock >= 0:
		stock_label.text = "Left: %d" % stock
		if stock == 0:
			buy_button.disabled = true
			modulate = Color(0.5, 0.5, 0.5)
	else:
		stock_label.text = ""
		buy_button.disabled = false
	
	# 图标 (需要从资源加载)
	# icon.texture = load("res://assets/items/%s.png" % item_id)
	
	# 检查玩家金币是否足够
	var player_money = GameManager.get_instance().inventory.get_count("money")
	if player_money < price:
		buy_button.disabled = true
	else:
		buy_button.disabled = false

## 设置为售罄
func set_sold_out():
	buy_button.disabled = true
	stock_label.text = "SOLD OUT"
	modulate = Color(0.5, 0.5, 0.5)
