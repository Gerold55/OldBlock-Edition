local BORDER = 128
local function clamp(v, lo, hi) if v < lo then return lo elseif v > hi then return hi else return v end end
local function out_of_bounds(p) return p.x < -BORDER or p.x >= BORDER or p.z < -BORDER or p.z >= BORDER end

minetest.register_globalstep(function(dtime)
  for _, player in ipairs(minetest.get_connected_players()) do
    local p = player:get_pos()
    if out_of_bounds(p) then
      p.x = clamp(p.x, -BORDER + 0.5, BORDER - 0.5)
      p.z = clamp(p.z, -BORDER + 0.5, BORDER - 0.5)
      player:set_pos(p)
      local vel = player:get_velocity() or {x=0,y=0,z=0}
      if player.add_player_velocity then
        player:add_player_velocity({x=-vel.x, y=0, z=-vel.z})
      end
      minetest.chat_send_player(player:get_player_name(), "World border: classic size.")
    end
  end
end)

minetest.register_on_placenode(function(pos) if out_of_bounds(pos) then return true end end)
minetest.register_on_dignode(function(pos) if out_of_bounds(pos) then return true end end)
