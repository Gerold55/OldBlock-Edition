
-- ob_inventory: selected-slot picker with dark UI (no Done button)
-- - Hotbar = 3 slots; prefill-if-empty; selected-slot assignment
-- - Inventory-key friendly; persistent picker; raised layout
-- - Dark gray panel with black border; item images only (no button borders)
-- - NOTE: Hotbar position cannot be changed via Lua API; use gui/hud scaling in config instead.

local GRID_W, GRID_H = 9, 6
local HOTBAR_COUNT   = 3

-- Layout
local CELL_SIZE   = 1.20
local CELL_SPACE  = 0.12
local LEFT, TOP   = 0.6, 0.6
local PAD_R, PAD_B= 0.6, 0.30

-- Visual frame
local FRAME_PAD   = 0.15

local GRID_W_WIDTH  = GRID_W * CELL_SIZE + (GRID_W - 1) * CELL_SPACE
local GRID_H_HEIGHT = GRID_H * CELL_SIZE + (GRID_H - 1) * CELL_SPACE
local WIN_W = LEFT + GRID_W_WIDTH + PAD_R
local WIN_H = TOP + GRID_H_HEIGHT + PAD_B

local FORMNAME = "ob_inventory:picker"

-- dedupe store
local last_click = {}

local blocks_011 = {
    "ob_core:stone",
    "ob_core:dirt",
    "ob_core:dirt_with_grass",
    "ob_core:sand",
    "ob_core:gravel",
    "ob_core:log_oak",
    "ob_core:leaves_oak",
    "ob_core:planks_oak",
    "ob_core:sapling_oak",
}

local function get_blocks()
    local t = {}
    for _,name in ipairs(blocks_011) do
        if minetest.registered_items[name] then
            table.insert(t, name)
        end
    end
    return t
end

local function make_formspec()
    local fs = {}
    fs[#fs+1] = "formspec_version[4]"
    fs[#fs+1] = string.format("size[%.2f,%.2f]", WIN_W, WIN_H)
    fs[#fs+1] = "bgcolor[#00000000]"

    -- Black outer border
    fs[#fs+1] = string.format("box[0,0;%.2f,%.2f;#000000FF]", WIN_W, WIN_H)
    -- Dark gray inner panel
    fs[#fs+1] = string.format("box[%.2f,%.2f;%.2f,%.2f;#2E2E2EFF]",
        FRAME_PAD, FRAME_PAD, WIN_W - 2*FRAME_PAD, WIN_H - 2*FRAME_PAD)

    -- Item image buttons only (no borders)
    fs[#fs+1] = "style_type[item_image_button;border=false;bgimg=;bgimg_hovered=;bgimg_pressed=;alpha=true;noclip=true]"

    local blocks = get_blocks()
    for idx, itemname in ipairs(blocks) do
        if idx > GRID_W * GRID_H then break end
        local col = (idx - 1) % GRID_W
        local row = math.floor((idx - 1) / GRID_W)
        local x = LEFT + col * (CELL_SIZE + CELL_SPACE)
        local y = TOP + row * (CELL_SIZE + CELL_SPACE)
        local field = string.format("pick_%d", idx)
        fs[#fs+1] = string.format("item_image_button[%.2f,%.2f;%.2f,%.2f;%s;%s;]",
            x, y, CELL_SIZE, CELL_SIZE, itemname, field)
    end

    return table.concat(fs)
end

local function ensure_hotbar(player)
    if player.hud_set_hotbar_itemcount then
        player:hud_set_hotbar_itemcount(HOTBAR_COUNT)
    end
    local inv = player:get_inventory()
    if inv:get_size("main") < HOTBAR_COUNT then
        inv:set_size("main", HOTBAR_COUNT)
    end
end

local function prefill_hotbar(player)
    local inv = player:get_inventory()
    local blocks = get_blocks()
    for i = 1, math.min(3, #blocks) do
        local st = inv:get_stack("main", i)
        if st:is_empty() then
            inv:set_stack("main", i, ItemStack(blocks[i] .. " 99"))
        end
    end
end

local function clamp_selected(player)
    local idx = player:get_wield_index() or 1
    if idx < 1 then idx = 1 end
    if idx > HOTBAR_COUNT then idx = HOTBAR_COUNT end
    return idx
end

local function assign_to_selected(player, itemname)
    local inv   = player:get_inventory()
    local slot  = clamp_selected(player)
    inv:set_stack("main", slot, ItemStack(itemname .. " 99"))
    if player.set_wielded_item then
        player:set_wielded_item(inv:get_stack("main", slot))
    end
end

local function show_picker(player)
    ensure_hotbar(player)
    prefill_hotbar(player)
    local fs = make_formspec()
    player:set_inventory_formspec(fs)
    minetest.show_formspec(player:get_player_name(), FORMNAME, fs)
end

minetest.register_on_joinplayer(function(player)
    minetest.after(0.1, function()
        if not player or not player:is_player() then return end
        show_picker(player)
    end)
end)

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= FORMNAME and formname ~= "" then return end

    local name = player:get_player_name()
    local now  = minetest.get_us_time()
    local which_btn = nil

    for k,_ in pairs(fields) do
        local sidx = k:match("^pick_(%d+)$")
        if sidx then which_btn = k break end
    end
    if not which_btn then return end

    local last = last_click[name]
    if last and last.btn == which_btn and (now - last.t) < 150000 then
        return
    end

    local blocks = get_blocks()
    local n = tonumber(which_btn:match("^pick_(%d+)$") or "")
    local itemname = n and blocks[n] or nil
    if itemname then
        assign_to_selected(player, itemname)
        last_click[name] = {btn = which_btn, t = now}
    end
end)

minetest.register_chatcommand("picker", {
    description = "Open the OldBlock block picker",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if not player then return false, "Player not found." end
        show_picker(player)
        return true, "Block picker opened."
    end
})
