----------------------------------------------------------------------
-- ABM: kill lateral flows (keep only falls)
-- If the node *below* is air: allow the flow (so it can drop).
-- Otherwise: remove the flowing node (prevents sideways spread).
----------------------------------------------------------------------
minetest.register_abm({
  label    = "OldBlock water: restrict lateral flow",
  nodenames = { "ob_core:water_flowing" },
  interval  = 1.0,
  chance    = 1,
  action = function(pos, node)
    local below = {x=pos.x, y=pos.y-1, z=pos.z}
    local nb = minetest.get_node(below).name
    if nb == "air" or nb == "ignore" then
      -- allow downward trickle
      return
    end
    -- stop horizontal creep
    minetest.swap_node(pos, {name="air"})
  end
})