extends CanvasLayer

## 视差背景 - 还原原项目效果

var sprite: Sprite2D
var scroll_speed = 0.5

func _ready():
	sprite = $BackgroundPattern
	_load_bg_pattern()

func _load_bg_pattern():
	if not sprite:
		return
	
	# 加载 main-bg.png (原项目: url('img/bg/main-bg.png'))
	var bg_path = "res://assets/bg/main-bg.png"
	if ResourceLoader.exists(bg_path):
		var tex = load(bg_path)
		sprite.texture = tex
		
		# 原项目: opacity: 0.1
		sprite.modulate = Color(1, 1, 1, 0.1)
		
		# 缩放适应
		var vp = get_viewport()
		if vp:
			var size = vp.get_visible_rect().size
			sprite.scale = Vector2(
				max(size.x / tex.get_width(), 1.0),
				max(size.y / tex.get_height(), 1.0)
			) * 2.0

func _process(delta):
	if sprite and sprite.texture:
		# 原项目: animation: bg-horizontal 600s linear infinite reverse
		# 反向慢速滚动
		sprite.position.x -= scroll_speed * delta
		if sprite.position.x < -sprite.texture.get_width() * sprite.scale.x:
			sprite.position.x = 0
