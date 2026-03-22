# PokeChill - Project Structure

## Dimension: 2D

## Input Actions

| Action | Keys |
|--------|------|
| confirm | Enter, Z |
| cancel | Escape, X |
| menu | Tab |
| up | W, Up |
| down | S, Down |
| left | A, Left |
| right | D, Right |

## Existing Scenes

### MainScene
- **File:** res://scenes/MainScene.tscn
- **Root:** Node2D
- **Children:** ParallaxBackground, UI (CanvasLayer)
- **Purpose:** Main game hub, menu navigation

### LoadingScene
- **File:** res://scenes/LoadingScene.tscn
- **Root:** Control
- **Purpose:** Loading screen while data initializes

### PokedexScreen
- **File:** res://scenes/PokedexScreen.tscn
- **Root:** Control
- **Children:** Filter panel, Grid of entries
- **Purpose:** View all Pokémon with filters

## Existing Scripts

### Database Scripts (res://resources/)
| Script | Purpose |
|--------|---------|
| PokemonDB.gd | Load/query pokemon.json |
| MoveDB.gd | Load/query moves.json |
| ItemDB.gd | Load/query items.json |
| AbilityDB.gd | Load/query abilities |
| AreaDB.gd | Load/query areas.json |
| TypeEffectiveness.gd | Type chart calculations |

### Game Logic (res://scripts/)
| Script | Purpose |
|--------|---------|
| GameManager.gd | Singleton, save/load, inventory |
| GameDataManager.gd | Data loading coordination |
| Team.gd | Player team management |
| Pokemon.gd | Pokémon instance class |
| Move.gd | Move data class |
| Item.gd | Item data class |
| UIManager.gd | UI navigation, menus |
| MainScene.gd | Main scene controller |
| ParallaxBackground.gd | Scrolling background |

### UI Scripts (res://scenes/)
| Script | Purpose |
|--------|---------|
| BattleUI.gd | Battle interface (stub) |
| PokedexScreen.gd | Pokédex display |
| PokedexFilter.gd | Filter logic |
| PokedexEntry.gd | Single entry display |
| TeamSlotUI.gd | Team member slot |
| ShopItemSlot.gd | Shop item display |
| LoadingScene.gd | Loading controller |

## Data Flow

```
JSON Files (data/)
    ↓
Database Classes (resources/)
    ↓
GameManager (singleton)
    ↓
UI Scenes / Battle System
```

## Asset Paths

| Asset Type | Path |
|------------|------|
| Pokémon Sprites | res://assets/sprites/pokemon/{id}.png |
| Items | res://assets/items/{id}.png |
| Backgrounds | res://assets/bg/{name}.png |
| Decor | res://assets/decor/{name}.png |
| Trainers | res://assets/trainers/{name}.png |
| Icons | res://assets/icons/{name}.png |

## Scenes to Create

### ExploreScene
- **File:** res://scenes/ExploreScene.tscn
- **Root:** Node2D
- **Children:** Background, Player(Sprite), EncounterZone(Area2D)
- **Script:** res://scripts/ExploreScene.gd

### BattleScene
- **File:** res://scenes/BattleScene.tscn
- **Root:** Node2D
- **Children:** PlayerSide, EnemySide, UI (MoveMenu, Dialog)
- **Script:** res://scripts/BattleScene.gd

### ShopScene
- **File:** res://scenes/ShopScene.tscn
- **Root:** Control
- **Children:** ItemGrid, BuyButton, GoldDisplay
- **Script:** res://scripts/ShopScene.gd

### TeamScene
- **File:** res://scenes/TeamScene.tscn
- **Root:** Control
- **Children:** TeamSlots, DetailPanel, Actions
- **Script:** res://scripts/TeamScene.gd

## Key Systems

### Battle Flow
1. Wild encounter OR trainer challenge
2. Load BattleScene
3. Player selects move
4. Calculate damage (type effectiveness, stats)
5. Apply damage, show animation
6. Enemy AI selects move
7. Apply damage to player
8. Check faint → swap or end battle
9. Victory: rewards, return to map

### Encounter System
- Area defines wild Pokémon pool
- Random encounter chance per step
- Level range based on area
- Rare/legendary spawns

### Capture Formula
```
catch_rate = (max_hp * 3 - current_hp * 2) * catch_bonus / (max_hp * 3) * ball_rate
```
