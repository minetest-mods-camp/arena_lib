local S = minetest.get_translator("arena_lib")
local waypoints = {} -- KEY: player name; VALUE: {Waypoints IDs}



function arena_lib.show_waypoints(p_name, mod, arena)
  local player = minetest.get_player_by_name(p_name)

  -- se sto aggiornando, devo prima rimuovere i vecchi
  if waypoints[p_name] then
    arena_lib.remove_waypoints(p_name)
  end

  waypoints[p_name] = {}

  minetest.after(0.1, function()
    -- punti rinascita
    if not arena.teams_enabled then
      for ID, pos in pairs(arena.spawn_points) do
        local HUD_ID = player:hud_add({
          name = "#" .. ID,
          hud_elem_type = "waypoint",
          precision = 0,
          world_pos = pos
        })

        table.insert(waypoints[p_name], HUD_ID)
      end
    else
      for i = 1, #arena.teams do
        for ID, pos in pairs(arena.spawn_points[i]) do
          local HUD_ID = player:hud_add({
            name = "#" .. ID .. ", " .. arena.teams[i].name,
            hud_elem_type = "waypoint",
            precision = 0,
            world_pos = pos
          })

          table.insert(waypoints[p_name], HUD_ID)
        end
      end
    end

    -- punto di ritorno
    local HUD_ID = player:hud_add({
      name = arena.custom_return_point and S("Return point (custom)") or S("Return point"),
      hud_elem_type = "waypoint",
      precision = 0,
      world_pos = arena.custom_return_point or arena_lib.mods[mod].settings.return_point
    })

    table.insert(waypoints[p_name], HUD_ID)
  end)
end



function arena_lib.remove_waypoints(p_name)
  local player = minetest.get_player_by_name(p_name)

  -- potrebbe essersi disconnesso. Evito di computare in caso
  if player then
    for _, waypoint_ID in pairs(waypoints[p_name]) do
      player:hud_remove(waypoint_ID)
    end
  end

  waypoints[p_name] = nil
end



function arena_lib.update_waypoints(p_name, mod, arena)
  if waypoints[p_name] then
    arena_lib.show_waypoints(p_name, mod, arena)
  end
end
