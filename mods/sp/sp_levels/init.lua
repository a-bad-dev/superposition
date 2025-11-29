-- SUPERPOSITION: LEVELS
local modpath = minetest.get_modpath("sp_levels")

sp.player = "singleplayer" -- temporary multiplayer support (so that my friends can play :D)

sp.levels = {}

-- @param level_data: table
-- level_data.spawn: vector
-- level_data.on_init: function()
-- level_data.on_step: function(player, dtime)
-- @return boolean
function sp.levels.register_level(level_data)
    if not level_data then
        return false
    end
    local level_spawn     = level_data.spawn
    local level_position  = level_data.position
    local level_items     = level_data.items
    local level_on_init   = level_data.on_init
    local level_on_load   = level_data.on_load
    local level_on_step   = level_data.on_step

    if not level_spawn or not level_on_init or not level_on_step then
        return false
    end

    table.insert(sp.levels, level_data)
    return true
end

-- @param player: player
-- @param level_id: number
-- @return boolean
function sp.levels.set_active_level(player, level_id)
    if not player or not level_id then
        return false
    end

    local level = sp.levels[level_id]
    if not level then
        return false
    end

    player:get_meta():set_int("active_level", level_id)
    clear_inv(player)


    local items = level.items
    if items then
        local inv = player:get_inventory()

        for i = 1, #items do
            inv:add_item("main", items[i])
        end
    end

    local on_load = level.on_load
    if on_load then
        on_load(player)
    end

    return true
end

-- @param player: player
-- @return number
function sp.levels.get_active_level(player)
    if not player then
        return false
    end

    return player:get_meta():get_int("active_level") or 1
end

core.register_on_joinplayer(function(player)
    for i = 1, #sp.levels do
        local level = sp.levels[i]
        if level.on_init then
            level.on_init()
        end
    end

    local current_level = sp.levels.get_active_level(player)

    if current_level == 0 then
        sp.levels.set_active_level(player, 1)
        current_level = sp.levels.get_active_level(player)
    end


    local level = sp.levels[current_level]
    if not level then
        core.log("error", "sp_levels: No level defined for level: " .. current_level)
        return
    end

    sp.levels.set_active_level(player, current_level)

    player:set_pos(level.spawn)
    player:override_day_night_ratio(0) -- B L A C K

    player:hud_set_flags({
        crosshair   = false,
        basic_debug = false -- disable basic debug like position and whatnot
    })

    player:hud_add({
        type        = "image",
        text        = "sp_crosshair.png",
        position    = {x = 0.5, y = 0.5},
        scale       = {x = 1, y = 1},
        z_index     = 10000,
    })

    player:set_camera({
        mode = "first"
    })

    local inv = player:get_inventory()
    inv:set_size("main", 8)
end)

core.register_globalstep(function(dtime)
    local player = core.get_player_by_name(sp.player)
    if not player then
        return
    end

    local meta = player:get_meta()
    local active_level = meta:get_int("active_level")
    if not active_level then
        return
    end

    local level = sp.levels[active_level]
    if not level then
        return
    end

    level.on_step(player, dtime)
end)

local locator_1 = vector.zero();
local locator_2 = nil;
-- get the relative position of the clicked pos from the level_vec
core.register_craftitem("sp_levels:dev_locator", {
    description = "Its a locator! :D",
    inventory_image = "sp_levels_locator.png",
    on_use = function(itemstack, user, pointed_thing)
        locator_1 = pointed_thing.under
    end,

    on_place = function(itemstack, user, pointed_thing)
        locator_2 = pointed_thing.under

        core.show_formspec(user:get_player_name(), "blah", "size[2,0.5]textarea[0.5,0;2,0.5;;"..vector.to_string(vector.round(vector.subtract(locator_2, locator_1)))..";]")
    end
})

core.register_chatcommand("set_level", {
    description = "Set the level you are currently on",
    privs = {server = true},
    func = function(name, param)
        sp.levels.set_active_level(core.get_player_by_name(name), tonumber(param))
    end
})



-- SCRIPTS

-- TRANSITIONS
dofile(modpath .. "/transition.lua")

-- LEVELS

dofile(modpath .. "/level1.lua")
dofile(modpath .. "/level2.lua")
dofile(modpath .. "/level3.lua")
dofile(modpath .. "/level4.lua")
dofile(modpath .. "/level5.lua")