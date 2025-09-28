-- ob_creative_rules: creative-only rules
-- (instant break, no drops, no health/breath HUD, no other mods)

-- === block all other mods ===
minetest.register_on_mods_loaded(function()
  for name,_ in pairs(minetest.registered_nodes) do
    if not name:match("^ob_core:") 
   and not name:match("^ob_mapgen:")
   and not name:match("^ob_tnt:")
   and not name:match("^ob_creative_rules")
   and name ~= "air"
   and name ~= "ignore" then
      -- override to air to disable outside mods
      minetest.override_item(name, {drawtype="airlike", walkable=false})
    end
  end
end)

local EXCLUDE = {
  ["air"]               = true,
  ["ignore"]            = true,
  ["ob_core:bedrock"]   = true,
  ["ob_core:border"]    = true,
}

local function copy_groups(src)
  local dst = {}
  if src then
    for k, v in pairs(src) do dst[k] = v end
  end
  return dst
end

-- === instant break + no drops ===
minetest.register_on_mods_loaded(function()
  for name, def in pairs(minetest.registered_nodes) do
    if not EXCLUDE[name] then
      local groups = copy_groups(def.groups)
      groups.dig_immediate = 3
      groups.unbreakable   = nil

      local override = {
        groups = groups,
        drop   = "",
      }

      if def.on_dig then
        override.on_dig = function(pos, node, digger)
          minetest.node_dig(pos, node, digger)
        end
      end

      minetest.override_item(name, override)
    end
  end
end)

-- === disable survival HUD ===
minetest.register_on_joinplayer(function(player)
  player:set_hp(20)
  player:set_armor_groups({immortal = 1})

  player:hud_set_flags({
    healthbar = false,
    breathbar = false,
    crosshair = true,
    hotbar    = true,
    wielditem = true,
  })
end)
