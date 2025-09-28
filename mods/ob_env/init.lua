-- mods/ob_env/init.lua
-- Border enforcement + spawn + hotbar + temporary fly

local BORDER = 128           -- world edges are [-128..127]
local YMAX   = 63
local DEV_ALLOW_FLY = true   -- <<< set to false for 0.1 release

local DEFAULTS = {"ob_core:stone","ob_core:dirt","ob_core:sand"}

local function clamp(v,a,b) if v<a then return a elseif v>b then return b else return v end end
local function within_border_pos(pos)
  return pos.x >= -BORDER and pos.x < BORDER and pos.z >= -BORDER and pos.z < BORDER
end

---------------------------------------------------------------------
-- Hotbar (3 slots, keep topped up)
---------------------------------------------------------------------
local function ensure_hotbar(player)
  local inv=player:get_inventory(); if not inv then return end
  player:hud_set_hotbar_itemcount(3)
  for i=1,3 do
    local want=DEFAULTS[i]
    local st=inv:get_stack("main",i)
    if st:is_empty() then inv:set_stack("main", i, ItemStack(want.." 99"))
    elseif st:get_name()==want and st:get_count()<99 then st:set_count(99); inv:set_stack("main",i,st) end
  end
end

---------------------------------------------------------------------
-- Robust surface spawn (wait for emerge, then place on surface)
---------------------------------------------------------------------
local function highest_solid_y(x,z)
  for y=YMAX,1,-1 do
    local n=minetest.get_node_or_nil({x=x,y=y,z=z})
    if n and n.name ~= "air" then return y end
  end
  return 1
end

local function place_after_emerge(name, x, z)
  x = clamp(math.floor(x+0.5), -BORDER+2, BORDER-3)
  z = clamp(math.floor(z+0.5), -BORDER+2, BORDER-3)
  local minp={x=x-8,y=0,z=z-8}; local maxp={x=x+8,y=YMAX,z=z+8}
  minetest.emerge_area(minp, maxp, function(_,_,left,_)
    if left==0 then
      local y = highest_solid_y(x,z) + 2
      local p = minetest.get_player_by_name(name)
      if p then p:set_pos({x=x+0.5,y=y,z=z+0.5}) end
    end
  end)
end

minetest.register_on_newplayer(function(player)
  ensure_hotbar(player)
  place_after_emerge(player:get_player_name(), 0, 0)
end)

minetest.register_on_joinplayer(function(player)
  ensure_hotbar(player)
  -- TEMP: grant/strip fly depending on flag
  local name = player:get_player_name()
  local privs = minetest.get_player_privs(name)
  if DEV_ALLOW_FLY then
    privs.fly = true; privs.noclip = nil
  else
    privs.fly = nil; privs.noclip = nil
  end
  minetest.set_player_privs(name, privs)
end)

minetest.register_on_respawnplayer(function(player)
  ensure_hotbar(player)
  local p = player:get_pos() or {x=0,y=0,z=0}
  place_after_emerge(player:get_player_name(), p.x, p.z)
  return true
end)

---------------------------------------------------------------------
-- Enforce border: clamp movement & block build/dig outside
---------------------------------------------------------------------
minetest.register_globalstep(function(dtime)
  for _,player in ipairs(minetest.get_connected_players()) do
    local p = player:get_pos()
    if not p then goto continue end
    local nx = clamp(p.x, -BORDER+0.5, BORDER-0.5)
    local nz = clamp(p.z, -BORDER+0.5, BORDER-0.5)
    if nx ~= p.x or nz ~= p.z then
      -- stop momentum when clamping
      player:add_velocity({x=-(player:get_velocity().x or 0), y=0, z=-(player:get_velocity().z or 0)})
      player:set_pos({x=nx, y=p.y, z=nz})
    end
    ::continue::
  end
end)

local function outside(x,z) return (x < -BORDER or x >= BORDER or z < -BORDER or z >= BORDER) end

minetest.register_on_placenode(function(pos, newnode, placer, oldnode, itemstack, pointed_thing)
  if outside(pos.x, pos.z) then return true end -- cancel placement
end)

minetest.register_on_dignode(function(pos, oldnode, digger)
  if outside(pos.x, pos.z) then return true end -- cancel dig
end)
