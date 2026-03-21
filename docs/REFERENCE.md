# PokeChill Web → Godot 转换参考文档

## 1. 项目概述

这是一个 Pokemon 风格的网页游戏 (play-pokechill)，核心玩法：
- 回合制战斗系统
- 宝可梦捕捉与培养
- 队伍管理
- 遗传基因系统
- 多个区域/地图探索

---

## 2. 数据结构

### 2.1 宝可梦数据结构 (pkmnDictionary.js)

```javascript
// 基础宝可梦对象结构
pkmn.bulbasaur = {
    type: ["grass", "poison"],              // 属性类型数组
    bst: {                                  // 基础种族值
        hp: 45,
        atk: 49,
        def: 49,
        satk: 65,
        sdef: 65,
        spe: 45,
    },
    evolve: function() {                    // 进化函数
        return { 1: { pkmn: pkmn.ivysaur, level: 30 } }
    },
    hiddenAbility: ability.thickFat,        // 隐藏特性
    signature: move.frenzyPlant              // 专属技能
}

// 宝可梦实例数据结构 (在队伍中使用)
let pkmnInstance = {
    id: "bulbasaur",        // 宝可梦ID
    level: 50,              // 等级
    shiny: false,           // 闪光状态
    caught: 1,              // 捕捉次数 (用于IV计算)
    movepool: ["tackle", "vine-whip", ...],  // 已学会技能池
    moves: {                // 当前装备的4个技能
        slot1: "tackle",
        slot2: "vine-whip",
        slot3: null,
        slot4: null
    },
    newMoves: [],           // 新可学习的技能
    ability: "overgrow",    // 当前特性
    ivs: {                  // 个体值 (0-31)
        hp: 31,
        atk: 31,
        def: 31,
        satk: 31,
        sdef: 31,
        spe: 31
    },
    evs: {                  // 努力值
        hp: 0,
        atk: 0,
        def: 0,
        satk: 0,
        sdef: 0,
        spe: 0
    },
    buffs: {               // 战斗增益/减益
        atk: 0,
        def: 0,
        // ...
    },
    status: null,           // 异常状态 (burn, poison, etc.)
    item: null              // 携带道具
}
```

**Godot 转换建议:**
```gdscript
# Pokemon.gd
class_name Pokemon
extends Resource

@export var id: String
@export var level: int = 1
@export var shiny: bool = false
@export var caught: int = 1

@export var types: Array[String] = []
@export var base_stats: Dictionary = {}  # {hp: 45, atk: 49, ...}

var ivs: Dictionary = {}
var evs: Dictionary = {}
var moves: Array = [null, null, null, null]
var movepool: Array = []
var ability: String = ""
var item: String = ""
var status: String = ""
var buffs: Dictionary = {}

func _init():
    randomize_ivs()

func randomize_ivs():
    for stat in ["hp", "atk", "def", "satk", "sdef", "spe"]:
        ivs[stat] = randi() % 32

func calculate_stat(stat_name: String) -> int:
    var base = base_stats.get(stat_name, 1)
    var iv = ivs.get(stat_name, 0)
    var ev = evs.get(stat_name, 0)
    var level = self.level
    
    if stat_name == "hp":
        return ((2 * base + iv + ev / 4) * level / 100) + level + 10
    else:
        return ((2 * base + iv + ev / 4) * level / 100) + 5
```

---

### 2.2 技能数据结构 (moveDictionary.js)

```javascript
const move = {}

// 技能对象结构
move.tackle = {
    name: "Tackle",
    type: "normal",                    // 技能属性
    category: "physical",              // 物理/特殊/变化 (physical/special/status)
    power: 40,                        // 威力
    accuracy: 100,                     // 命中率
    pp: 35,                           // PP
    max_pp: 57,                       // 最大PP
    priority: 0,                      // 优先级
    rarity: 1,                         // 稀有度 (1-3)
    moveset: ["all"],                  // 可学习标签
    effect: {                          // 特殊效果
        chance: 0,                    // 触发概率
        status: null,                 // 附加状态
        stat_change: null,            // 属性变化
        // ...
    },
    target: "enemy",                   // 目标
    contact: true,                     // 是否接触技能
    notUsableByEnemy: false,           // 敌人能否使用
    restricted: false                   # 是否限制
}
```

**Godot 转换建议:**
```gdscript
# Move.gd
class_name Move
extends Resource

enum Category { PHYSICAL, SPECIAL, STATUS }
enum Target { ENEMY, ALLY, SELF, BOTH }

@export var id: String
@export var name: String
@export var type: String
@export var category: int = Category.PHYSICAL
@export var power: int = 0
@export var accuracy: int = 100
@export var pp: int = 35
@export var max_pp: int = 57
@export var priority: int = 0
@export var rarity: int = 1
@export var moveset_tags: Array[String] = []
@export var target: int = Target.ENEMY
@export var contact: bool = true
@export var restricted: bool = false

var current_pp: int

func _init():
    current_pp = pp

func use() -> bool:
    if current_pp <= 0:
        return false
    current_pp -= 1
    return true
```

---

### 2.3 队伍数据结构 (teams.js)

```javascript
// 玩家队伍 (6个宝可梦槽位)
let team = {
    slot1: {
        pkmn: "bulbasaur",     # 宝可梦实例ID
        turn: 1,               # 战斗回合顺序
        buffs: {},             # 增益状态
        item: null             # 携带道具
    },
    slot2: { pkmn: undefined, ... },
    // ... slot3-6
}

// 预设队伍 (用于不同场景)
saved.previewTeams = {
    preview1: {
        name: "Team 1",
        slot1: { pkmn: "charizard", item: "charizardite-x" },
        slot2: { pkmn: "blastoise", item: null },
        // ...
    },
    // ... preview2-30
}
```

**Godot 转换建议:**
```gdscript
# Team.gd
class_name Team
extends Resource

@export var name: String = "Team 1"
@export var slots: Array[PokemonSlot] = []

func _init():
    slots = []
    for i in range(6):
        slots.append(PokemonSlot.new())

class PokemonSlot:
    var pokemon: Pokemon = null
    var turn_order: int = 1
    var buffs: Dictionary = {}
    var item: String = ""
```

---

### 2.4 区域数据结构 (areasDictionary.js)

```javascript
const areas = {}

areas.forest = {
    id: "forest",
    name: "Verdant Forest",
    type: "wild",                    // wild / vs / dungeon / frontier / etc.
    level_range: [1, 15],            // 等级范围
    rotation: true,                  // 是否轮换
    trainers: false,                 // 是否有训练家
    bosses: false,                   // 是否有Boss
    entry_requirement: null,
    required_division: null,
    
    # 生成函数
    get_pokemon: function() {
        return random_pokemon_filter(...)
    }
}

// 区域类型
# wild - 野生战斗
# vs - 训练家对战
# dungeon - 地下城
# frontier - 挑战设施
# training - 训练区
# event - 活动区域
```

**Godot 转换建议:**
```gdscript
# Area.gd
class_name Area
extends Resource

enum AreaType { WILD, VS, DUNGEON, FRONTIER, TRAINING, EVENT }

@export var id: String
@export var name: String
@export var area_type: int = AreaType.WILD
@export var level_range: Vector2i = Vector2i(1, 100)
@export var rotation: bool = true
@export var trainers: bool = false
@export var bosses: bool = false

@export var required_division: int = 0
@export var entry_requirement: Dictionary = {}

func get_random_pokemon() -> Pokemon:
    # 根据等级范围和类型生成宝可梦
    pass
```

---

## 3. 核心系统

### 3.1 战斗系统 (explore.js)

```javascript
// 战斗回合流程
function battle_turn() {
    // 1. 计算速度决定行动顺序
    // 2. 玩家宝可梦依次行动
    // 3. 敌方宝可梦依次行动
    // 4. 检查战斗结束条件
}

// 伤害计算公式
function calculate_damage(attacker, defender, move) {
    // 基础伤害 = ((2 * 等级 / 5 + 2) * 威力 * A/D) / 50 + 2
    // STAB = 属性一致加成 (1.5x)
    // TypeEffectiveness = 属性相性
    // Random = 随机浮动 (0.85-1.0)
    // Ability = 特性修正
    // Item = 道具修正
    // Weather = 天气修正
    // Field = 场地修正
}

// 速度计算
function calculate_speed(pokemon) {
    let base = pokemon.bst.spe
    let iv = pokemon.ivs.spe
    let ev = pokemon.evs.spe
    let level = pokemon.level
    let nature = 1.0  # 性格修正
    
    return Math.floor(((2 * base + iv + ev/4) * level / 100) + 5) * nature
}

// 经验值计算
function calculate_exp(target, attacker) {
    let level_diff = target.level - attacker.level
    let base_exp = 100
    
    # +-5级内获得相同经验
    # 超过5级差获得更多
    # 10级以上不获得经验
}
```

**Godot 转换建议:**
```gdscript
# BattleManager.gd
class_name BattleManager
extends Node

signal damage_dealt(amount)
signal turn_ended()
signal battle_ended(win: bool)

enum BattleState { PLAYER_TURN, ENEMY_TURN, ANIMATING, ENDED }

var state: int = BattleState.PLAYER_TURN
var player_team: Team
var enemy_team: Team
var current_turn: int = 1

func calculate_damage(attacker: Pokemon, defender: Pokemon, move: Move) -> int:
    var level = attacker.level
    var power = move.power
    
    var attack_stat = Move.Category.PHYSICAL if move.category == Move.Category.PHYSICAL else attacker.stats.satk
    var defense_stat = Move.Category.PHYSICAL if move.category == Move.Category.PHYSICAL else defender.stats.sdef
    
    var damage = ((2 * level / 5 + 2) * power * attack_stat / defense_stat / 50 + 2)
    
    # STAB
    if move.type in attacker.types:
        damage *= 1.5
    
    # 属性相性
    damage *= get_type_effectiveness(move.type, defender.types[0])
    if defender.types.size() > 1:
        damage *= get_type_effectiveness(move.type, defender.types[1])
    
    # 随机浮动
    damage *= randf_range(0.85, 1.0)
    
    return int(damage)

func get_type_effectiveness(move_type: String, defender_type: String) -> float:
    # 属性相性表
    var effectiveness = {
        "normal": {"rock": 0.5, "ghost": 0, "steel": 0.5},
        "fire": {"fire": 0.5, "water": 0.5, "grass": 2.0, "ice": 2.0, "bug": 2.0, "rock": 0.5, "dragon": 0.5, "steel": 2.0},
        # ... 完整相性表
    }
    return effectiveness.get(move_type, {}).get(defender_type, 1.0)
```

---

### 3.2 技能学习系统 (script.js)

```javascript
// 宝可梦学习技能
function learnPkmnMove(id, level, mod, exclude = []) {
    let types = pkmn[id].type
    let knownMoves = pkmn[id].movepool || []
    
    # 根据等级决定技能稀有度
    let tier = 1
    if (level >= 10 && rng(0.25)) tier++
    if (level >= 20 && rng(0.25)) tier++
    if (level >= 30 && rng(0.25)) tier++
    tier = Math.min(tier, 3)
    
    # 过滤可选技能
    let allMoves = Object.keys(move).filter(m => {
        return move[m].rarity === tier && 
               !knownMoves.includes(m) &&
               !exclude.includes(m)
    })
    
    # 优先选择属性一致的技能
    let typeMatch = allMoves.filter(m => types.includes(move[m].type))
    
    # 选择技能
    if (typeMatch.length > 0) {
        return typeMatch[Math.floor(Math.random() * typeMatch.length)]
    }
    
    return undefined
}
```

---

### 3.3 存档系统 (save.js)

```javascript
// 保存游戏
function saveGame() {
    const saveData = {
        version: 5.0,
        team: team,
        previewTeams: saved.previewTeams,
        currentArea: saved.currentArea,
        item: item,                          # 道具背包
        pkmn: pkmn,                          # 已捕捉的宝可梦
        settings: {
            theme: saved.theme,
            hideGotPkmn: saved.hideGotPkmn
        },
        game_modes: {
            gamemodNuzlocke: false,
            gamemodHard: false,
            gamemodAfk: false
        },
        rotations: {
            wild: rotationWildCurrent,
            dungeon: rotationDungeonCurrent,
            event: rotationEventCurrent,
            frontier: rotationFrontierCurrent
        }
    }
    
    localStorage.setItem('pokechill_save', JSON.stringify(saveData))
}

// 加载游戏
function loadGame() {
    const saveString = localStorage.getItem('pokechill_save')
    if (!saveString) return
    
    const saveData = JSON.parse(saveString)
    saved = { ...saved, ...saveData }
    
    # 版本迁移
    if (saved.version < 5.0) {
        updateGameVersion()  # 自动更新存档
    }
}
```

**Godot 转换建议:**
```gdscript
# SaveManager.gd
class_name SaveManager
extends Node

const SAVE_FILE = "user://pokechill_save.json"

func save_game():
    var save_data = {
        "version": GameVersion.CURRENT,
        "team": serialize_team(PlayerManager.team),
        "pokedex": serialize_pokedex(),
        "inventory": InventoryManager.get_data(),
        "settings": SettingsManager.get_data(),
        "rotations": RotationManager.get_data()
    }
    
    var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
    file.store_string(JSON.stringify(save_data))
    file.close()

func load_game() -> bool:
    if not FileAccess.file_exists(SAVE_FILE):
        return false
    
    var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
    var save_data = JSON.parse_string(file.get_as_text())
    file.close()
    
    # 版本迁移
    if save_data.get("version", 0) < GameVersion.CURRENT:
        migrate_save(save_data)
    
    apply_save_data(save_data)
    return true
```

---

### 3.4 遗传/基因系统

```javascript
// 遗传操作
function geneticOperation(host, sample, operations) {
    for (op of operations) {
        switch(op) {
            case "shiny_mutation":
                # 闪光变异 - 100%继承样本的闪光
                host.shiny = sample.shiny
                break
                
            case "iv_inherit":
                # IV继承 - 继承样本的个体值
                host.ivs = sample.ivs
                break
                
            case "ability_swap":
                # 特性交换 - 使用命运连结
                swap_ability(host, sample)
                break
                
            case "move_inherit":
                # 技能继承
                inherit_moves(host, sample)
                break
        }
        
        # 操作后IV自动提升
        boost_random_iv(host)
    }
}

// 兼容性计算
function calculate_compatibility(host, sample) {
    let compat = 0
    
    # 共享一个属性 +1
    # 共享两个属性 +2
    # 同一进化线 +3 (最大)
    
    return compat  # 0-3
}
```

---

## 4. UI 系统

游戏使用纯 HTML/CSS 构建 UI，主要结构：

```
index.html
├── #game-container
│   ├── #top-menu (旅行, 队伍, 商店, 图鉴...)
│   ├── #explore-area (探索区域)
│   ├── #battle-screen (战斗画面)
│   ├── #team-menu (队伍管理)
│   ├── #pokedex-menu (图鉴)
│   ├── #shop-menu (商店)
│   └── #tooltip (信息提示)
```

**Godot 转换建议:**

Godot 中使用 `Control` 节点重建 UI：

```gdscript
# UIManager.gd
class_name UIManager
extends CanvasLayer

@onready var top_menu = $TopMenu
@onready var battle_screen = $BattleScreen
@onready var team_menu = $TeamMenu
@onready var pokedex_menu = $PokedexMenu

func show_menu(menu_name: String):
    hide_all_menus()
    match menu_name:
        "team": team_menu.visible = true
        "pokedex": pokedex_menu.visible = true
        "battle": battle_screen.visible = true
```

---

## 5. 资源迁移

### 5.1 图片资源

Web 版本资源路径：
```
img/
├── pkmn/
│   ├── sprite/     # 普通sprite
│   └── shiny/      # 闪光sprite
├── items/          # 道具图片
├── icons/          # 属性图标
└── backgrounds/    # 背景图
```

迁移到 Godot：
- 放在 `res://assets/sprites/` 目录
- 使用 `TextureRect` 或 `Sprite2D` 显示

### 5.2 数据文件

将 JS 对象转换为 Godot `.tres` 资源文件：

```gdscript
# PokemonDB.gd (Resource)
class_name PokemonDB
extends Resource

@export var pokemon_data: Dictionary = {
    "bulbasaur": {
        "type": ["grass", "poison"],
        "bst": {"hp": 45, "atk": 49, ...},
        "evolve": "ivysaur",
        "evolve_level": 30
    }
}
```

---

## 6. 关键代码片段

### 6.1 随机数生成

```javascript
// 基础随机
function rng(chance) {
    return Math.random() < chance
}

// 种子随机 (用于可复现结果)
function mulberry32(a) {
    return function() {
        a |= 0;
        a = a + 0x6D2B79F5 | 0;
        let t = Math.imul(a ^ a >>> 15, 1 | a);
        t ^= t + Math.imul(t ^ t >>> 7, 61 | t);
        return ((t ^ t >>> 14) >>> 0) / 4294967296;
    }
}
```

### 6.2 字符串格式化

```javascript
function format(input) {
    let str = String(input)
    
    # 重命名检查
    if (move[input]?.rename) str = String(move[input].rename)
    if (pkmn[input]?.rename) str = String(pkmn[input].rename)
    
    # 驼峰转空格首字母大写
    return str
        .replace(/([a-z])([A-Z])/g, '$1 $2')
        .replace(/\b\w/g, c => c.toUpperCase())
}
```

---

## 7. 游戏版本迁移

```javascript
// 版本更新时的存档迁移
function updateGameVersion() {
    if (saved.version < 0.2) {
        saved.tutorial = false
        saved.tutorialStep = "intro"
    }
    
    if (saved.version < 0.9) {
        # 奖励瓶盖
        for (let i in areas) {
            if (areas[i].type === "vs" && areas[i].defeated) {
                item.bottleCap.got++
            }
        }
    }
    
    # ... 更多迁移
    
    saved.version = 5.0
}
```

---

## 8. 转换优先级建议

1. **Phase 1: 基础框架**
   - 项目结构
   - 数据导入 (PokemonDB, MoveDB)
   - 基础 UI 系统

2. **Phase 2: 核心玩法**
   - 队伍管理
   - 战斗系统
   - 存档系统

3. **Phase 3: 内容填充**
   - 地图/区域
   - 商店系统
   - 图鉴

4. **Phase 4: 高级功能**
   - 遗传系统
   - 挑战设施
   - 多人/社交功能

---

*文档生成时间: 2026-03-21*
*源项目: play-pokechill.github.io*
