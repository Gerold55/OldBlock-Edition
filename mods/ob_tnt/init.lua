-- ob_tnt/init.lua
-- TNT block (non-functional, decorative only for OldBlock Edition 0.1)

local S = function(s) return s end

minetest.register_node("ob_tnt:tnt", {
    description = S("TNT"),
    tiles = {
        "ob_tnt_top.png",     -- top
        "ob_tnt_bottom.png",  -- bottom
        "ob_tnt_side.png",    -- sides
    },
    groups = {oddly_breakable_by_hand = 1, flammable = 1},
    sounds = default and default.node_sound_wood_defaults() or nil,
    -- No explosives yet!
    on_blast = function() end, -- placeholder
})
