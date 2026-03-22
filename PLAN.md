# Game Plan: PokeChill

## Game Description

A chill Pokémon-style game where players explore areas, catch Pokémon, build teams, and battle trainers. Migrated from web (play-pokechill.github.io) to Godot 4.

## Project State

### Already Implemented
- ✅ Pokemon/Move/Item/Ability/Area databases (JSON + GDScript)
- ✅ GameManager (singleton, save/load, inventory)
- ✅ Basic UI (menu, pokedex with filters)
- ✅ Parallax background
- ✅ Team management (Team.gd)
- ✅ Type effectiveness system

### Existing Assets
- 1393 Pokémon sprites (assets/sprites/)
- 315 item icons (assets/items/)
- 26 backgrounds (assets/bg/)
- 68 decor images (assets/decor/)
- 101 trainer images (assets/trainers/)

## Tasks

## 1. Explore System - World Map & Movement
- **Depends on:** (none)
- **Goal:** Allow player to explore different areas with visual map
- **Requirements:**
  - Area selection UI (list or visual map)
  - Area transition (load area data, change background)
  - Wild Pokémon encounter system (random encounter based on area)
  - Area-specific Pokémon pools (grass, water, fishing)
- **Assets needed:** Use existing bg/, decor/, sprites/
- **Verify:** Player can select an area, see background change, encounter wild Pokémon

## 2. Battle System - Turn-Based Combat
- **Depends on:** 1
- **Goal:** Full turn-based battle system with moves, damage calculation
- **Requirements:**
  - Battle scene with player/enemy Pokémon display
  - Move selection UI (4 moves per Pokémon)
  - Damage calculation (type effectiveness, STAB, level, stats)
  - Attack animations (sprite shake, flash)
  - HP bar updates
  - Battle flow: select move → calculate → animate → enemy turn → repeat
  - Win/lose conditions (faint, capture)
- **Verify:** Battle starts on encounter, moves deal correct damage, battle ends when one side faints

## 3. Capture System - Catch Pokémon
- **Depends on:** 2
- **Goal:** Catch wild Pokémon with Pokéballs
- **Requirements:**
  - Capture formula (ball type, Pokémon HP, catch rate)
  - Capture animation (ball shake, catch success/fail)
  - Add captured Pokémon to team (or PC)
  - Show caught Pokémon notification
- **Verify:** Can throw ball at wild Pokémon, correct catch rate, add to team

## 4. Shop System - Buy Items
- **Depends on:** (none)
- **Goal:** Purchase items with in-game currency
- **Requirements:**
  - Shop UI with item list and prices
  - Buy functionality (deduct gold, add item)
  - Currency system (gold from battles)
  - Different item categories (balls, healing, evolution items)
- **Verify:** Can browse shop, buy items, inventory updates, gold decreases

## 5. Team Management - Organize Pokémon
- **Depends on:** 2
- **Goal:** Full team management UI
- **Requirements:**
  - View team Pokémon (stats, moves, level)
  - Swap positions in team
  - Switch active Pokémon in battle
  - Release Pokémon
  - Heal team (healing center)
- **Verify:** Can view all team members, reorder, heal at center

## 6. Evolution System
- **Depends on:** 2
- **Goal:** Pokémon evolution mechanics
- **Requirements:**
  - Evolution by level
  - Evolution by stone
  - Evolution by trade
  - Pre-evolution check on level up
  - Evolution animation/scene
- **Verify:** Pokémon evolves when conditions met

## 7. Save/Load Enhancement
- **Depends on:** 1
- **Goal:** Complete save system with all game state
- **Requirements:**
  - Save player position/area
  - Save team (all Pokémon with stats, moves)
  - Save inventory
  - Save gold
  - Save completion flags (defeated trainers, caught Pokémon)
- **Verify:** Save and load preserves all game state correctly

## 8. Trainer Battles
- **Depends on:** 2
- **Goal:** Battles against AI trainers
- **Requirements:**
  - Trainer data (team, name, class)
  - Trainer AI (basic: select strongest move, switch if fainted)
  - Trainer battle initiation
  - Victory rewards (gold, items)
  - Defeat handling (game over or respawn)
- **Verify:** Can battle trainers, win/lose correctly, receive rewards

## 9. Pokedex Enhancement
- **Depends on:** 1, 3
- **Goal:** Complete Pokédex with capture tracking
- **Requirements:**
  - Track seen Pokémon
  - Track caught Pokémon
  - Pokedex entry details (stats, moves, evolution)
  - Completion percentage
- **Verify:** Pokedex updates when encountering/catching Pokémon

## 10. Polish & UI
- **Depends on:** 1-9
- **Goal:** Final UI polish and game feel
- **Requirements:**
  - Sound effects (optional: use placeholders)
  - Smooth transitions between screens
  - Loading screens
  - Settings menu
  - Help/controls display
- **Verify:** Game feels polished, all screens transition smoothly
