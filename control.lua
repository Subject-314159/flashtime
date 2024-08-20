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

    -- 10% chance per tick to draw lightning
    if math.random(1, 100) < 101 then

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
            local offy = math.random(0, 10) / 10
            surface.create_entity {
                name = "electric-beam",
                position = {pos.x + offx, pos.y + offy},
                target_position = {pos.x + offx, pos.y + offy},
                source_position = {oldpos.x + offx, oldpos.y + offy - 0.5},
                duration = math.random(10, 30)
            }
        end

        -- Update last position
        gp.last_position = player.character.position
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
        -- Enable flashtime, set game speed and init player position array
        global.flashtime = true
        global.game_speed = game.speed
        game.speed = 0.2

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

        -- Update the force speed modifier
        for k, v in pairs(global.forces) do
            local frc = game.forces[k]
            frc.character_running_speed_modifier = v.last_speed_modifier + 50
        end
    end
end

local init = function()
    if not global.players then
        global.players = {}
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

script.on_event(defines.events.on_tick, function(e)

end)

script.on_event(defines.events.on_player_changed_position, function(e)
    if global.flashtime then
        process_lightning(e.player_index)
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
