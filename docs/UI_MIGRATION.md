# PokeChill UI 迁移方案

## 1. 当前问题

### 1.1 屏幕适配问题
- **原项目**: 竖屏移动端优先 (50% 宽度)
- **Godot项目**: 1280x720 (16:9 横屏)
- **解决方案**: 调整为竖屏布局

### 1.2 资源缺失问题
原项目资源需要迁移到 Godot:

| 资源类型 | 数量 | 源路径 | 目标路径 |
|----------|------|--------|----------|
| 宝可梦精灵 | 1,393 | img/pkmn/sprite/ | assets/sprites/pokemon/ |
| 闪光精灵 | ~1,393 | img/pkmn/shiny/ | assets/sprites/shiny/ |
| 道具图标 | 315 | img/items/ | assets/items/ |
| 属性图标 | 18 | img/icons/ | assets/icons/ |
| 背景图 | 多个 | img/bg/ | assets/bg/ |
| 装饰物 | 多个 | img/decor/ | assets/decor/ |
| 训练家 | 多个 | img/trainers/ | assets/trainers/ |

---

## 2. UI布局适配方案

### 2.1 屏幕配置调整

修改 `project.godot`:

```ini
[display]

# 竖屏模式
window/size/viewport_width=480
window/size/viewport_height=800
window/orientation=1  # portrait
window/stretch/mode="canvas_items"
window/stretch/aspect="expand"

# 移动端适配
window/size/resizable=false
```

### 2.2 界面布局结构调整

原项目布局结构:
```
┌─────────────────┐
│   顶部导航栏    │  ← 60px
├─────────────────┤
│                │
│   主内容区域    │  ← 自适应
│                │
│                │
├─────────────────┤
│   底部操作区    │  ← 100px (战斗时)
└─────────────────┘
```

Godot 适配:
- 使用 `Control` 节点 + `Anchor` 定位
- 顶部: 固定 60px
- 中间: `Size Flags: Expand + Fill`
- 底部: 根据需要显示

---

## 3. 资源迁移步骤

### 3.1 复制资源文件

```powershell
# 创建目标目录
New-Item -ItemType Directory -Path "D:\GodoT\PokeChill\assets\sprites\pokemon"
New-Item -ItemType Directory -Path "D:\GodoT\PokeChill\assets\sprites\shiny"
New-Item -ItemType Directory -Path "D:\GodoT\PokeChill\assets\items"
New-Item -ItemType Directory -Path "D:\GodoT\PokeChill\assets\icons"
New-Item -ItemType Directory -Path "D:\GodoT\PokeChill\assets\bg"

# 复制图片
Copy-Item "D:\GodoT\play-pokechill.github.io-main\play-pokechill.github.io-main\img\pkmn\sprite\*" -Destination "D:\GodoT\PokeChill\assets\sprites\pokemon\"
Copy-Item "D:\GodoT\play-pokechill.github.io-main\play-pokechill.github.io-main\img\pkmn\shiny\*" -Destination "D:\GodoT\PokeChill\assets\sprites\shiny\"
Copy-Item "D:\GodoT\play-pokechill.github.io-main\play-pokechill.github.io-main\img\items\*" -Destination "D:\GodoT\PokeChill\assets\items\"
Copy-Item "D:\GodoT\play-pokechill.github.io-main\play-pokechill.github.io-main\img\icons\*" -Destination "D:\GodoT\PokeChill\assets\icons\"
```

### 3.2 资源加载脚本

创建资源加载器 `ResourceLoader.gd`:

```gdscript
extends Node

const SPRITE_PATH = "res://assets/sprites/pokemon/"
const ITEM_PATH = "res://assets/items/"
const ICON_PATH = "res://assets/icons/"

func get_pokemon_sprite(pokemon_id: String, shiny: bool = false) -> Texture2D:
	var path = SPRITE_PATH + ("shiny/" if shiny else "pokemon/") + pokemon_id + ".png"
	if ResourceLoader.exists(path):
		return load(path)
	return load(SPRITE_PATH + "pokemon/placeholder.png")

func get_item_icon(item_id: String) -> Texture2D:
	var path = ITEM_PATH + item_id + ".png"
	if ResourceLoader.exists(path):
		return load(path)
	return load(ITEM_PATH + "placeholder.png")

func get_type_icon(type_name: String) -> Texture2D:
	var path = ICON_PATH + type_name + ".svg"
	if ResourceLoader.exists(path):
		return load(path)
	return load(ICON_PATH + "placeholder.png")
```

---

## 4. UI组件改造

### 4.1 主场景布局 (MainScene.tscn)

```gdscript
# 竖屏布局
extends Node2D

func _ready():
	# 设置画布大小
	get_tree().root.content_scale_size = Vector2i(480, 800)
	
	# 布局: 顶部(60) + 内容(自适应) + 底部(可选)
	
	# 顶部导航
	$CanvasLayer/UI/TopNav.custom_minimum_size.y = 60
	
	# 主内容区域
	$CanvasLayer/UI/MainContent.set_anchors_preset(Control.PRESET_FULL_RECT)
	$CanvasLayer/UI/MainContent.offset_top = 60
	$CanvasLayer/UI/MainContent.offset_bottom = -100
	
	# 底部区域
	$CanvasLayer/UI/BottomPanel.custom_minimum_size.y = 100
	$CanvasLayer/UI/BottomPanel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
```

### 4.2 组件尺寸调整

| 组件 | 原尺寸 | 新尺寸 (竖屏) |
|------|--------|--------------|
| 队伍槽位 | 350x120 | 420x140 |
| 技能按钮 | 250x70 | 200x60 |
| 宝可梦精灵 | 80x80 | 64x64 |
| 图鉴条目 | 90x110 | 80x100 |

---

## 5. 实施计划

### Phase 1: 屏幕适配
- [ ] 修改 project.godot 为竖屏
- [ ] 调整 MainScene.tscn 布局
- [ ] 测试各界面显示

### Phase 2: 资源迁移
- [ ] 复制图片资源到 assets/
- [ ] 创建 ResourceLoader.gd
- [ ] 更新 UI 组件加载图片

### Phase 3: UI 完善
- [ ] 修复按钮点击事件
- [ ] 添加图片显示
- [ ] 完善交互效果

---

## 6. 颜色主题 (从 styles.css 提取)

```css
:root {
    --dark1: #36342F;
    --dark2: #444138;
    --light1: #94886B;
    --light2: #ECDEB7;
    --accent: #ffe15e;
    
    --type-bug: #92BD2D;
    --type-dark: #595761;
    --type-dragon: #0C6AC8;
    --type-electric: #F2D94E;
    --type-fairy: #EF90E6;
    --type-fighting: #D3425F;
    --type-fire: #FBA64C;
    --type-flying: #A1BBEC;
    --type-ghost: #5F6DBC;
    --type-grass: #60BE58;
    --type-ground: #DA7C4D;
    --type-ice: #76D1C1;
    --type-normal: #A0A29F;
    --type-poison: #B763CF;
    --type-psychic: #FA8582;
    --type-rock: #C9BC8A;
    --type-steel: #5795A3;
    --type-water: #539DDF;
}
```

---

*方案生成时间: 2026-03-21*
