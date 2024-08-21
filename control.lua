local tick_update = function()
    -- Only when in flashtime
    if not global.flashtime then
        return
    end

    -- Loop through players
    for id, gp in pairs(global.players) do
        -- Get player & character
        local player = game.get_player(id)
        if player and player.character then
            -- Increase tick counter since last lightning
            gp.ticks_since_lightning = (gp.ticks_since_lightning or 0) + 1

            -- Check if player is standing still too long
            if gp.ticks_since_lightning > (gp.lightning_tick_timeout or 30) then
                -- Add 1-5 random lightning around the character
                for i = 1, math.random(1, 3), 1 do
                    local offx1 = math.random(-5, 5) / 10
                    local offy1 = math.random(0, 10) / 10
                    local offx2 = math.random(-5, 5) / 10
                    local offy2 = math.random(0, 10) / 10
                    local pos = player.character.position
                    player.character.surface.create_entity {
                        name = "electric-beam",
                        position = {pos.x + offx1, pos.y - offy1},
                        target_position = {pos.x + offx1, pos.y - offy1},
                        source_position = {pos.x + offx2, pos.y - offy2},
                        duration = math.random(10, 30)
                    }
                end

                -- Reset ticks since last lightning & timeout
                gp.ticks_since_lightning = 0
                gp.lightning_tick_timeout = math.random(10, 30)
            end
        end
    end
end

local process_lightning = function(player_index)
    -- Get the player
    local player = game.get_player(player_index)
    if not player or not player.character then
        return
    end

    -- Correct for global position
    if not global.players[player_index] then
        global.players[player_index] = {}
    end
    local gp = global.players[player_index]
    if not gp.last_position then
        gp.last_position = player.character.position
    end

    -- 100% chance per tick to draw lightning
    if math.random(1, 100) < 101 then
        -- Reset ticks since last lightning
        gp.ticks_since_lightning = 0

        -- Get the surface & current position
        local surface = player.character.surface
        if not surface then
            return
        end

        local pos = player.character.position
        local oldpos = gp.last_position

        -- Draw the lightning
        for i = 1, 5, 1 do
            local offx = math.random(-5, 5) / 10
            local offy = math.random(-10, 5) / 10
            surface.create_entity {
                name = "electric-beam",
                position = {pos.x + offx, pos.y + offy},
                target_position = {pos.x + offx, pos.y + offy},
                source_position = {oldpos.x + offx, oldpos.y + offy - 0.5},
                duration = math.random(30, 90)
            }
        end

        -- Update last position
        gp.last_position = player.character.position
    end
end

local update_game_force_speed = function()
    -- Update game speed
    game.speed = (settings.global["flashtime-gamespeed-slowdown"].value / 100)
    -- Update the force speed modifier
    for k, v in pairs(global.forces) do
        local frc = game.forces[k]
        frc.character_running_speed_modifier = v.last_speed_modifier +
                                                   settings.global["flashtime-character-speedbonus"].value
    end
end

local toggle_flashtime = function()
    if global.flashtime then
        -- Disable flashtime & reset game speed
        global.flashtime = false
        game.speed = global.game_speed or 1

        -- Restore speed modifier
        for k, v in pairs(global.forces) do
            local frc = game.forces[k]
            frc.character_running_speed_modifier = v.last_speed_modifier
        end
    else
        -- Enable flashtime
        global.flashtime = true

        -- Remember game speed
        global.game_speed = game.speed

        -- Clear the force speed modifyer
        global.forces = {}

        -- Store each player's current position
        for _, p in pairs(game.players) do
            if not global.players[p.index] then
                global.players[p.index] = {}
            end
            local gp = global.players[p.index]
            if p and p.character then
                gp.last_position = p.character.position
            end

            -- Write the force speed modifier
            if not global.forces[p.force_index] then
                global.forces[p.force_index] = {}
            end
            gf = global.forces[p.force_index]
            local frc = game.forces[p.force_index]
            gf.last_speed_modifier = frc.character_running_speed_modifier
        end

        update_game_force_speed()
    end
end

local init = function()
    if not global.players then
        global.players = {}
    end
    for _, p in pairs(game.players) do
        if not global.players[p.index] then
            global.players[p.index] = {}
        end
    end

    if not global.forces then
        global.forces = {}
    end
end

script.on_configuration_changed(function()
    init()
end)

script.on_init(function()
    init()
end)

script.on_event(defines.events.on_player_created, function(e)
    init()
end)

script.on_event(defines.events.on_player_joined_game, function(e)
    init()
end)

script.on_event(defines.events.on_tick, function(e)
    tick_update()
end)

script.on_event(defines.events.on_player_changed_position, function(e)
    if global.flashtime then
        process_lightning(e.player_index)
    end
end)

script.on_event(defines.events.on_runtime_mod_setting_changed, function(e)
    if (e.setting == "flashtime-gamespeed-slowdown" or e.setting == "flashtime-character-speedbonus") and
        global.flashtime then
        update_game_force_speed()
    end
end)

---------------------------------------------------------------------------
-- SHORTCUTS
---------------------------------------------------------------------------

script.on_event(defines.events.on_lua_shortcut, function(e)
    if e.prototype_name == "flashtime-toggle" then
        toggle_flashtime()
    end
end)

script.on_event("flashtime-toggle", function(e)
    toggle_flashtime()
end)
