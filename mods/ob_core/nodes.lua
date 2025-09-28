-- ob_core/nodes.lua  — OldBlock Edition (MCPE 0.1.0 set)
-- Single source of truth for node registration (no saplings, no crafts).

local S = function(s) return s end

----------------------------------------------------------------------
-- Terrain
----------------------------------------------------------------------
minetest.register_node("ob_core:bedrock", {
  description = S("Bedrock"),
  tiles = {"ob_bedrock.png"},
  groups = {unbreakable = 1},
  is_ground_content = false,
  diggable = false, pointable = false,
  drop = "",
})

minetest.register_node("ob_core:stone", {
  description = S("Stone"),
  tiles = {"ob_stone.png"},
  groups = {cracky = 3, stone = 1},
})

minetest.register_node("ob_core:cobble", {
  description = S("Cobblestone"),
  tiles = {"ob_cobble.png"},
  groups = {cracky = 3, stone = 1},
})

minetest.register_node("ob_core:dirt", {
  description = S("Dirt"),
  tiles = {"ob_dirt.png"},
  groups = {crumbly = 3, soil = 1},
})


-- ob_core/dirt_with_grass.lua
-- One grass block, dynamically colored by biome on placement.

local biome_colors = {
  plains        = "#7FB238",
  forest        = "#6AAA2A",
  birch_forest  = "#89C266",
  beach         = "#8CCB6A",
}

local COLORIZE_STRENGTH = 135
local TX_DIRT           = "ob_dirt.png"
local TX_GRASS_TOP      = "ob_grass_top.png"
local TX_GRASS_SIDEO    = "ob_grass_side_overlay.png"

-- Default (used in inventory/wield and fallback)
local DEFAULT_COLOR = biome_colors.plains or "#7FB238"

minetest.register_node("ob_core:dirt_with_grass", {
  description = "Grass Block",

  tiles = {
    TX_GRASS_TOP .. "^[colorize:" .. DEFAULT_COLOR .. ":" .. COLORIZE_STRENGTH,
    TX_DIRT,
    TX_DIRT .. "^(" .. TX_GRASS_SIDEO .. "^[colorize:" .. DEFAULT_COLOR .. ":" .. COLORIZE_STRENGTH .. ")",
  },
  drop   = "ob_core:dirt",
  groups = {crumbly = 3, soil = 1},
  sunlight_propagates = true,
  paramtype = "light",
  is_ground_content = true,

  -- Swap texture overlays to biome-appropriate variant on placement
  on_construct = function(pos)
    local ok, data = pcall(minetest.get_biome_data, pos)
    if not ok or not data then return end

    local biome_id   = data.biome
    local biome_name = minetest.get_biome_name(biome_id)
    local hex        = biome_colors[biome_name] or DEFAULT_COLOR

    local meta = minetest.get_meta(pos)
    meta:set_string("color_hex", hex)

    -- apply param2 colorization (for mapblocks that respect it)
    -- or leave meta for ABMs/LBMs to re-texture later if needed
  end,

  on_place = function(itemstack, placer, pointed_thing)
    if not pointed_thing or not pointed_thing.above then
      return itemstack
    end
    local pos = pointed_thing.above
    minetest.set_node(pos, {name = "ob_core:dirt_with_grass"})
    if placer and not minetest.is_creative_enabled(placer:get_player_name()) then
      itemstack:take_item()
    end
    return itemstack
  end,
})

minetest.register_node("ob_core:sand", {
  description = S("Sand"),
  tiles = {"ob_sand.png"},
  groups = {crumbly = 3, falling_node = 1, sand = 1},
})

minetest.register_node("ob_core:gravel", {
  description = S("Gravel"),
  tiles = {"ob_gravel.png"},
  groups = {crumbly = 2, falling_node = 1},
})

----------------------------------------------------------------------
-- Wood set
----------------------------------------------------------------------
minetest.register_node("ob_core:log_oak", {
  description = S("Oak Log"),
  tiles = {"ob_log_oak_top.png", "ob_log_oak_top.png", "ob_log_oak.png"},
  paramtype2 = "facedir",
  on_place = minetest.rotate_node,
  groups = {tree = 1, choppy = 2},
})

minetest.register_node("ob_core:planks_oak", {
  description = S("Oak Planks"),
  tiles = {"ob_planks_oak.png"},
  groups = {choppy = 3, oddly_breakable_by_hand = 3, wood = 1},
})

-- Oak Leaves (MCPE 0.1 style, with green tint applied)
local LEAF_HEX          = "#7FB238"   -- same green as grass
local COLORIZE_STRENGTH = 135

minetest.register_node("ob_core:leaves_oak", {
  description = S("Oak Leaves"),
  drawtype = "allfaces_optional",
  waving = 1,
  tiles = {
    "ob_leaves_oak.png^[colorize:"..LEAF_HEX..":"..COLORIZE_STRENGTH,
  },
  paramtype = "light",
  groups = {snappy = 3, leaves = 1, flammable = 2},
  drop = "ob_core:sapling_oak", -- optional: drop saplings like early MCPE
})

-- Birch set
--minetest.register_node("ob_core:log_birch", {
--  description = "Birch Log",
--  tiles = {"ob_log_birch_top.png","ob_log_birch_top.png","ob_log_birch.png"},
--  paramtype2 = "facedir",
--  on_place = minetest.rotate_node,
--  groups = {tree=1, choppy=2},
--})

--minetest.register_node("ob_core:planks_birch", {
--  description = "Birch Planks",
--  tiles = {"ob_planks_birch.png"},
--  groups = {choppy=3, oddly_breakable_by_hand=3, wood=1},
--})

--minetest.register_node("ob_core:leaves_birch", {
--  description = "Birch Leaves",
--  drawtype = "allfaces_optional",
--  tiles = {"ob_leaves_birch.png"},
--  paramtype = "light",
--  waving = 1,
--  groups = {snappy=3, leaves=1, flammable=2},
--})

----------------------------------------------------------------------
-- Utility / decorative
----------------------------------------------------------------------
minetest.register_node("ob_core:glass", {
  description = S("Glass"),
  drawtype = "glasslike",
  tiles = {"ob_glass.png"},
  paramtype = "light",
  sunlight_propagates = true,
  groups = {cracky = 3},
})

minetest.register_node("ob_core:bookshelf", {
    description = "Bookshelf",
    -- top, bottom = planks; sides = bookshelf
    tiles = {
        "ob_planks_oak.png",  -- top
        "ob_planks_oak.png",  -- bottom
        "ob_bookshelf.png",   -- side
    },
    groups = {choppy = 2, flammable = 2},
})

-- Cyan Flower (plantlike, simple)
minetest.register_node("ob_core:flower_cyan", {
  description = "Cyan Flower",
  drawtype = "plantlike",
  waving = 1,
  tiles = {"ob_flower_cyan.png"},
  inventory_image = "ob_flower_cyan.png",
  wield_image = "ob_flower_cyan.png",
  paramtype = "light",
  sunlight_propagates = true,
  walkable = false,
  buildable_to = true,
  groups = {snappy=3, flammable=1, flower=1, attached_node=1, ob_creative_010=1},
  selection_box = { type = "fixed", fixed = {-0.25,-0.5,-0.25, 0.25,0.0,0.25} },
})

----------------------------------------------------------------------
-- Wool (16 colors)
----------------------------------------------------------------------
-- One texture per wool color (no colorization)
local wool_defs = {
  {id="white",       tex="ob_wool_white.png"},
  {id="orange",      tex="ob_wool_orange.png"},
  {id="magenta",     tex="ob_wool_magenta.png"},
  {id="light_blue",  tex="ob_wool_light_blue.png"},
  {id="yellow",      tex="ob_wool_yellow.png"},
  {id="lime",        tex="ob_wool_lime.png"},
  {id="pink",        tex="ob_wool_pink.png"},
  {id="gray",        tex="ob_wool_gray.png"},
  {id="light_gray",  tex="ob_wool_light_gray.png"},
  {id="cyan",        tex="ob_wool_cyan.png"},
  {id="purple",      tex="ob_wool_purple.png"},
  {id="blue",        tex="ob_wool_blue.png"},
  {id="brown",       tex="ob_wool_brown.png"},
  {id="green",       tex="ob_wool_green.png"},
  {id="red",         tex="ob_wool_red.png"},
  {id="black",       tex="ob_wool_black.png"},
}

local function titleize(s) return (s:gsub("^%l", string.upper):gsub("_", " ")) end

for _, def in ipairs(wool_defs) do
  local name = "ob_core:wool_" .. def.id
  minetest.register_node(name, {
    description = titleize(def.id) .. " Wool",
    tiles = { def.tex },
    groups = { snappy=2, oddly_breakable_by_hand=3, flammable=2, wool=1 },
  })
end


----------------------------------------------------------------------
-- Lights / special
----------------------------------------------------------------------
-- OldBlock torch (MC-like)
-- Requires: textures/ob_torch.png

local TORCH_LIGHT = 14

local function place_wallmounted(itemstack, placer, pointed_thing)
  if not pointed_thing or pointed_thing.type ~= "node" then return itemstack end
  local under = pointed_thing.under
  local above = pointed_thing.above
  local dir = {x = above.x - under.x, y = above.y - under.y, z = above.z - under.z}
  local wdir = minetest.dir_to_wallmounted(dir)

  -- Only place if the attachment node is buildable-to at the target pos
  local pos = above
  local def = minetest.registered_nodes[minetest.get_node(under).name]
  if not def or (def.buildable_to and def.buildable_to == true) then
    return itemstack
  end

  -- Place with wallmounted param2
  local playername = placer and placer:get_player_name() or ""
  if minetest.is_protected(pos, playername) then return itemstack end

  local node = {name = "ob_core:torch", param2 = wdir}
  if minetest.registered_nodes[minetest.get_node(pos).name].buildable_to then
    minetest.set_node(pos, node)
  else
    if minetest.item_place_node(ItemStack("ob_core:torch"), placer, pointed_thing, wdir) then
      -- placed by engine
    else
      return itemstack
    end
  end

  if placer and not minetest.is_creative_enabled(playername) then
    itemstack:take_item()
  end
  return itemstack
end

minetest.register_node("ob_core:torch", {
    description = "Torch",
    drawtype = "torchlike",             -- 3D torchlike model
    tiles = {"ob_torch.png"},
    inventory_image = "ob_torch.png",
    wield_image     = "ob_torch.png",
    paramtype = "light",
    paramtype2 = "wallmounted",         -- supports floor/wall/ceiling
    sunlight_propagates = true,
    walkable = false,
    light_source = 14,                  -- classic torch light
    groups = {choppy=2, dig_immediate=3, attached_node=1, torch=1},
    selection_box = { type = "wallmounted" },
    sounds = {dig = {name="default_dig_crumbly", gain=0.2}},
})


-- Optional: keep floor/wall/ceiling aliases (not shown in creative)
minetest.register_alias("ob_core:torch_wall",    "ob_core:torch")
minetest.register_alias("ob_core:torch_ceiling", "ob_core:torch")

minetest.register_node("ob_core:glowstone", {
  description = S("Glowstone"),
  tiles = {"ob_glowstone.png"},
  light_source = minetest.LIGHT_MAX - 1,
  groups = {cracky = 3},
})

----------------------------------------------------------------------
-- Liquids (simple source-only for 0.1 feel)
----------------------------------------------------------------------
-- Transparent water (classic look with alpha)
local WATER_TEX = "ob_water.png"

-- Source
minetest.register_node("ob_core:water_source", {
  description = "Water",
  drawtype = "liquid",
  tiles = { WATER_TEX },
  special_tiles = {
    { name = WATER_TEX, backface_culling = false },
    { name = WATER_TEX, backface_culling = true  },
  },
  use_texture_alpha = "blend",        -- set to "opaque" if you want solid water
  paramtype = "light",
  walkable = false,
  pointable = false,
  diggable = false,
  buildable_to = true,

  liquidtype = "source",
  liquid_alternative_flowing = "ob_core:water_flowing",
  liquid_alternative_source  = "ob_core:water_source",
  liquid_viscosity = 1,
  liquid_renewable = false,           -- ← no infinite water
  liquid_range = 1,                   -- ← super short range

  groups = { water=1, liquid=1 },
})

-- Flowing (kept for downward trickle; we’ll cull sideways flows with an ABM)
minetest.register_node("ob_core:water_flowing", {
  description = "Flowing Water",
  drawtype = "flowingliquid",
  tiles = { WATER_TEX },
  special_tiles = {
    { name = WATER_TEX, backface_culling = false },
    { name = WATER_TEX, backface_culling = true  },
  },
  use_texture_alpha = "blend",
  paramtype = "light",
  paramtype2 = "flowingliquid",
  walkable = false,
  pointable = false,
  diggable = false,
  buildable_to = true,

  liquidtype = "flowing",
  liquid_alternative_flowing = "ob_core:water_flowing",
  liquid_alternative_source  = "ob_core:water_source",
  liquid_viscosity = 1,
  liquid_renewable = false,
  liquid_range = 1,

  groups = { water=1, liquid=1, not_in_creative_inventory=1 },
})

minetest.register_node("ob_core:lava_source", {
  description = S("Lava"),
  drawtype = "liquid",
  tiles = {"ob_lava.png"},
  special_tiles = {{name = "ob_lava.png", backface_culling = false}},
  use_texture_alpha = "opaque",
  paramtype = "light",
  light_source = minetest.LIGHT_MAX - 1,
  walkable = false, pointable = false, diggable = false, buildable_to = true,
  liquidtype = "source",
  liquid_alternative_flowing = "ob_core:lava_source",
  liquid_alternative_source = "ob_core:lava_source",
  liquid_viscosity = 7,
  groups = {lava = 1, liquid = 1},
})

----------------------------------------------------------------------
-- Invisible, solid border
----------------------------------------------------------------------
minetest.register_node("ob_core:border", {
  description = S("World Border"),
  drawtype   = "airlike",   -- fully invisible
  paramtype  = "light",
  sunlight_propagates = true,
  walkable   = true,        -- solid collision
  pointable  = false,
  diggable   = false,
  buildable_to = false,
  groups     = {unbreakable = 1},
  drop       = "",
})
