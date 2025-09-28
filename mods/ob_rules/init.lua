
-- ob_rules_010: MCPE 0.1 rules
-- - No flying / noclip
-- - Instant break blocks
-- - Leave creative inventory UI available (handled by ob_inventory)

local function apply_player_rules(player)
  -- remove flight-like abilities
  local name = player:get_player_name()
  local privs = minetest.get_player_privs(name)
  privs.fly = nil; privs.noclip = nil
  minetest.set_player_privs(name, privs)
  -- physics overrides
  player:set_physics_override({sneak=true, jump=1.0, speed=1.0, gravity=1.0})
end

minetest.register_on_joinplayer(function(player)
  -- apply a tick later to override other mods
  minetest.after(0.1, function(p) if p and p:is_player() then apply_player_rules(p) end end, player)
end)

-- Instant break: remove node on punch (skip bedrock/border)
local hard = {
  ["ob_core:bedrock"]=true,
  ["ob_core:border"]=true,
}
minetest.register_on_punchnode(function(pos, node, puncher, pointed_thing)
  if not puncher or not puncher:is_player() then return end
  if hard[node.name] then return end
  if minetest.is_protected(pos, puncher:get_player_name()) then return end
  -- emulate creative instant dig
  minetest.remove_node(pos)
end)
