#!/usr/bin/env node

/**
 * PokeChill 数据转换器
 * 将 JS 数据文件转换为 Godot 可用的 JSON 格式
 * 
 * 使用方法:
 *   node data_converter.js <源目录> <输出目录>
 * 
 * 示例:
 *   node data_converter.js "D:\GodoT\play-pokechill.github.io-main\play-pokechill.github.io-main\scripts" "D:\GodoT\PokeChill\data"
 */

const fs = require('fs');
const path = require('path');

const SOURCE_DIR = process.argv[2] || './source';
const OUTPUT_DIR = process.argv[3] || './output';

// 确保输出目录存在
if (!fs.existsSync(OUTPUT_DIR)) {
    fs.mkdirSync(OUTPUT_DIR, { recursive: true });
}

// 读取 JS 文件并提取数据
function extractJSData(jsFilePath) {
    const content = fs.readFileSync(jsFilePath, 'utf-8');
    
    // 移除注释
    let cleaned = content.replace(/\/\/.*$/gm, '').replace(/\/\*[\s\S]*?\*\//g, '');
    
    // 尝试解析为 JS 对象
    try {
        // 提取 pkmn = { ... } 格式
        const match = cleaned.match(/const\s+\w+\s*=\s*\{([\s\S]*?)\n\};/);
        if (match) {
            // 简单解析 - 实际项目中需要更复杂的解析器
            return parseJSObject(match[0]);
        }
    } catch (e) {
        console.error(`Error parsing ${jsFilePath}:`, e.message);
    }
    
    return null;
}

// 简单的 JS 对象解析器
function parseJSObject(jsString) {
    // 这是一个简化版本 - 实际需要更完整的解析
    const result = {};
    
    // 匹配 key = value 格式
    const keyValuePattern = /(\w+)\s*=\s*\{([^}]+)\}/g;
    let match;
    
    while ((match = keyValuePattern.exec(jsString)) !== null) {
        const key = match[1];
        const value = match[2];
        
        // 检查是否是嵌套对象
        if (value.includes('{')) {
            result[key] = parseNestedObject(value);
        } else {
            result[key] = parseValue(value);
        }
    }
    
    return result;
}

function parseNestedObject(str) {
    const obj = {};
    
    // 匹配简单的 key: value 对
    const pattern = /(\w+):\s*("[^"]*"|\d+|\[\]|\{[^}]*\})/g;
    let match;
    
    while ((match = pattern.exec(str)) !== null) {
        const key = match[1];
        const value = match[2].replace(/["\[\]\{\}]/g, '');
        obj[key] = isNaN(value) ? value : parseInt(value);
    }
    
    return obj;
}

function parseValue(val) {
    val = val.trim();
    if (val.startsWith('"') && val.endsWith('"')) {
        return val.slice(1, -1);
    }
    if (val === 'true') return true;
    if (val === 'false') return false;
    if (val === 'undefined') return null;
    if (!isNaN(val)) return parseFloat(val);
    return val;
}

// 转换宝可梦数据
function convertPokemonData(sourceDir) {
    const pkmnFile = path.join(sourceDir, 'pkmnDictionary.js');
    if (!fs.existsSync(pkmnFile)) {
        console.error('pkmnDictionary.js not found!');
        return;
    }
    
    const content = fs.readFileSync(pkmnFile, 'utf-8');
    const pokemon = {};
    
    // 匹配 pkmn.id = { ... } 格式
    const regex = /pkmn\.(\w+)\s*=\s*\{([\s\S]*?)\n\}/g;
    let match;
    
    while ((match = regex.exec(content)) !== null) {
        const id = match[1];
        const objContent = match[2];
        
        const pkmnData = {
            id: id,
            name: id.charAt(0).toUpperCase() + id.slice(1).replace(/([A-Z])/g, ' $1').trim()
        };
        
        // 提取 type
        const typeMatch = objContent.match(/type:\s*\[([^\]]+)\]/);
        if (typeMatch) {
            pkmnData.types = typeMatch[1].split(',').map(t => t.trim().replace(/"/g, ''));
        }
        
        // 提取 bst
        const bstMatch = objContent.match(/bst:\s*\{([^}]+)\}/);
        if (bstMatch) {
            pkmnData.bst = {};
            const stats = bstMatch[1].split(',');
            for (const stat of stats) {
                const [key, value] = stat.split(':').map(s => s.trim());
                if (key && value) {
                    pkmnData.bst[key] = parseFloat(value);
                }
            }
        }
        
        // 提取进化信息
        const evolveMatch = objContent.match(/evolve:\s*function\(\)\s*\{\s*return\s*\{([^}]+)\}/);
        if (evolveMatch) {
            const evolveContent = evolveMatch[1];
            const evolveLevelMatch = evolveContent.match(/level:\s*(\d+)/);
            const evolvePkmnMatch = evolveContent.match(/pkmn:\s*pkmn\.(\w+)/);
            
            if (evolvePkmnMatch) {
                pkmnData.evolve_to = evolvePkmnMatch[1];
                pkmnData.evolve_level = evolveLevelMatch ? parseInt(evolveLevelMatch[1]) : null;
            }
        }
        
        // 提取隐藏特性
        const hiddenAbilityMatch = objContent.match(/hiddenAbility:\s*ability\.(\w+)/);
        if (hiddenAbilityMatch) {
            pkmnData.hidden_ability = hiddenAbilityMatch[1];
        }
        
        // 提取专属技能
        const signatureMatch = objContent.match(/signature\s*:\s*move\.(\w+)/);
        if (signatureMatch) {
            pkmnData.signature_move = signatureMatch[1];
        }
        
        pokemon[id] = pkmnData;
    }
    
    // 保存到文件
    fs.writeFileSync(
        path.join(OUTPUT_DIR, 'pokemon.json'),
        JSON.stringify(pokemon, null, 2)
    );
    
    console.log(`Converted ${Object.keys(pokemon).length} Pokemon!`);
    return pokemon;
}

// 转换技能数据
function convertMoveData(sourceDir) {
    const moveFile = path.join(sourceDir, 'moveDictionary.js');
    if (!fs.existsSync(moveFile)) {
        console.error('moveDictionary.js not found!');
        return;
    }
    
    const content = fs.readFileSync(moveFile, 'utf-8');
    const moves = {};
    
    // 匹配 move.id = { ... } 格式
    const regex = /move\.(\w+)\s*=\s*\{([\s\S]*?)\n\}/g;
    let match;
    
    while ((match = regex.exec(content)) !== null) {
        const id = match[1];
        const objContent = match[2];
        
        const moveData = { id: id };
        
        // 提取属性
        const props = ['type', 'category', 'power', 'accuracy', 'pp', 'max_pp', 'priority', 
                       'rarity', 'effect_chance', 'target', 'contact', 'restricted'];
        
        for (const prop of props) {
            const propMatch = objContent.match(new RegExp(`${prop}:\\s*("[^"]*"|\\d+|true|false|\\[.*?\\])`));
            if (propMatch) {
                let value = propMatch[1];
                if (value === 'true') moveData[prop] = true;
                else if (value === 'false') moveData[prop] = false;
                else if (!isNaN(value)) moveData[prop] = parseFloat(value);
                else if (value.startsWith('"')) moveData[prop] = value.slice(1, -1);
                else if (value.startsWith('[')) {
                    // 数组
                    moveData[prop] = value.replace(/[\[\]]/g, '').split(',').map(s => s.trim().replace(/"/g, ''));
                }
            }
        }
        
        // 处理 category 字符串
        const catMatch = objContent.match(/category:\s*"(\w+)"/);
        if (catMatch) {
            const cat = catMatch[1].toLowerCase();
            if (cat === 'physical') moveData.category = 0;
            else if (cat === 'special') moveData.category = 1;
            else if (cat === 'status') moveData.category = 2;
        }
        
        moves[id] = moveData;
    }
    
    fs.writeFileSync(
        path.join(OUTPUT_DIR, 'moves.json'),
        JSON.stringify(moves, null, 2)
    );
    
    console.log(`Converted ${Object.keys(moves).length} moves!`);
    return moves;
}

// 转换道具数据
function convertItemData(sourceDir) {
    const itemFile = path.join(sourceDir, 'itemDictionary.js');
    if (!fs.existsSync(itemFile)) {
        console.error('itemDictionary.js not found!');
        return;
    }
    
    const content = fs.readFileSync(itemFile, 'utf-8');
    const items = {};
    
    // 匹配 item.id = { ... } 格式
    const regex = /item\.(\w+)\s*=\s*\{([\s\S]*?)\n\}/g;
    let match;
    
    while ((match = regex.exec(content)) !== null) {
        const id = match[1];
        const objContent = match[2];
        
        const itemData = { id: id };
        
        // 提取基本属性
        const nameMatch = objContent.match(/name:\s*"([^"]+)"/);
        if (nameMatch) itemData.name = nameMatch[1];
        
        const descMatch = objContent.match(/desc:\s*"([^"]+)"/);
        if (descMatch) itemData.description = descMatch[1];
        
        const priceMatch = objContent.match(/price:\s*(\d+)/);
        if (priceMatch) itemData.price = parseInt(priceMatch[1]);
        
        const typeMatch = objContent.match(/type:\s*"(\w+)"/);
        if (typeMatch) itemData.type = typeMatch[1];
        
        const catMatch = objContent.match(/category:\s*(\d+)/);
        if (catMatch) itemData.category = parseInt(catMatch[1]);
        
        items[id] = itemData;
    }
    
    fs.writeFileSync(
        path.join(OUTPUT_DIR, 'items.json'),
        JSON.stringify(items, null, 2)
    );
    
    console.log(`Converted ${Object.keys(items).length} items!`);
    return items;
}

// 转换区域数据
function convertAreaData(sourceDir) {
    const areaFile = path.join(sourceDir, 'areasDictionary.js');
    if (!fs.existsSync(areaFile)) {
        console.error('areasDictionary.js not found!');
        return;
    }
    
    const content = fs.readFileSync(areaFile, 'utf-8');
    const areas = {};
    
    // 匹配 areas.id = { ... } 格式
    const regex = /areas\.(\w+)\s*=\s*\{([\s\S]*?)\n\}/g;
    let match;
    
    while ((match = regex.exec(content)) !== null) {
        const id = match[1];
        const objContent = match[2];
        
        const areaData = { id: id };
        
        // 提取属性
        const nameMatch = objContent.match(/name:\s*"([^"]+)"/);
        if (nameMatch) areaData.name = nameMatch[1];
        
        const typeMatch = objContent.match(/type:\s*"(\w+)"/);
        if (typeMatch) areaData.type = typeMatch[1];
        
        const levelMatch = objContent.match(/level_range:\s*\[(\d+),\s*(\d+)\]/);
        if (levelMatch) {
            areaData.level_min = parseInt(levelMatch[1]);
            areaData.level_max = parseInt(levelMatch[2]);
        }
        
        const rotationMatch = objContent.match(/rotation:\s*(true|false)/);
        if (rotationMatch) areaData.rotation = rotationMatch[1] === 'true';
        
        const trainerMatch = objContent.match(/trainers:\s*(true|false)/);
        if (trainerMatch) areaData.trainers = trainerMatch[1] === 'true';
        
        const bossMatch = objContent.match(/bosses:\s*(true|false)/);
        if (bossMatch) areaData.bosses = bossMatch[1] === 'true';
        
        areas[id] = areaData;
    }
    
    fs.writeFileSync(
        path.join(OUTPUT_DIR, 'areas.json'),
        JSON.stringify(areas, null, 2)
    );
    
    console.log(`Converted ${Object.keys(areas).length} areas!`);
    return areas;
}

// 主函数
function main() {
    console.log('=== PokeChill Data Converter ===');
    console.log(`Source: ${SOURCE_DIR}`);
    console.log(`Output: ${OUTPUT_DIR}`);
    console.log('');
    
    // 执行转换
    convertPokemonData(SOURCE_DIR);
    convertMoveData(SOURCE_DIR);
    convertItemData(SOURCE_DIR);
    convertAreaData(SOURCE_DIR);
    
    console.log('');
    console.log('Conversion complete!');
    console.log(`Output files saved to: ${OUTPUT_DIR}`);
}

main();
