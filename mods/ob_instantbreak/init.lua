
-- ob_instantbreak v2: safer instant break for ob_core nodes
-- Strategy: only add dig_immediate=3; preserve all existing groups.
-- Order: run after all mods + one tick to avoid conflicts.

local function add_instant_group(name)
    local def = minetest.registered_nodes[name]
    if not def then return end
    local groups = {}
    -- preserve existing groups
    if def.groups then
        for k,v in pairs(def.groups) do groups[k] = v end
    end
    groups.dig_immediate = 3
    minetest.override_item(name, { groups = groups })
end

local function apply_all()
    for nodename,_ in pairs(minetest.registered_nodes) do
        if nodename:sub(1,8) == "ob_core:" then
            add_instant_group(nodename)
        end
    end
    minetest.log("action", "[ob_instantbreak] dig_immediate=3 applied to all ob_core nodes.")
end

-- Wait until *all* mods are loaded, then one tick for good measure.
minetest.register_on_mods_loaded(function()
    minetest.after(0, apply_all)
end)
