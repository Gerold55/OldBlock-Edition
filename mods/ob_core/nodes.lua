local S = function(s) return s end

-- Terrain
minetest.register_node("ob_core:stone", {description=S("Stone"), tiles={"ob_stone.png"}, groups={cracky=3, stone=1}})
minetest.register_node("ob_core:dirt", {description=S("Dirt"), tiles={"ob_dirt.png"}, groups={crumbly=3, soil=1}})
minetest.register_node("ob_core:dirt_with_grass", {
    description=S("Grass Block"),
    tiles={"ob_grass_top.png","ob_dirt.png","ob_grass_side.png"},
    groups={crumbly=3, soil=1},
    drop="ob_core:dirt",
})
minetest.register_node("ob_core:sand", {description=S("Sand"), tiles={"ob_sand.png"}, groups={crumbly=3, falling_node=1, sand=1}})
minetest.register_node("ob_core:gravel", {description=S("Gravel"), tiles={"ob_gravel.png"}, groups={crumbly=2, falling_node=1}})

-- Wood set
minetest.register_node("ob_core:log_oak", {
    description=S("Oak Log"),
    tiles={"ob_log_oak_top.png","ob_log_oak_top.png","ob_log_oak.png"},
    paramtype2="facedir",
    on_place=minetest.rotate_node,
    groups={tree=1, choppy=2},
})
minetest.register_node("ob_core:leaves_oak", {
    description=S("Oak Leaves"),
    drawtype="allfaces_optional",
    waving=1,
    tiles={"ob_leaves_oak.png"},
    paramtype="light",
    groups={snappy=3, leaves=1},
    drop={ max_items=1, items={{items={"ob_core:sapling_oak"}, rarity=20}, {items={"ob_core:leaves_oak"}} } },
})
minetest.register_node("ob_core:planks_oak", {description=S("Oak Planks"), tiles={"ob_planks_oak.png"}, groups={choppy=3, oddly_breakable_by_hand=3, wood=1}})
minetest.register_node("ob_core:sapling_oak", {
    description=S("Oak Sapling"),
    drawtype="plantlike",
    tiles={"ob_sapling_oak.png"},
    inventory_image="ob_sapling_oak.png",
    wield_image="ob_sapling_oak.png",
    paramtype="light",
    sunlight_propagates=true,
    walkable=false,
    groups={snappy=2, dig_immediate=3, attached_node=1},
    selection_box={type="fixed", fixed={-0.3,-0.5,-0.3, 0.3,0.3,0.3}},
})

-- QoL craft
minetest.register_craft({output="ob_core:planks_oak 4", recipe={{"ob_core:log_oak"}}})
