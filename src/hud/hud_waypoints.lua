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
    for ID, spawn in pairs(arena.spawn_points) do
      local caption = "#" .. ID

      -- se ci sono squadre, lo specifico nel nome
      if arena.teams_enabled then
        caption = caption .. ", " .. arena.teams[spawn.teamID].name
      end

      local HUD_ID = player:hud_add({
        name = caption,
        hud_elem_type = "waypoint",
        precision = 0,
        world_pos = spawn.pos
      })

      table.insert(waypoints[p_name], HUD_ID)
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
  if not waypoints[p_name] then
    minetest.chat_send_player(p_name, minetest.colorize("#e6482e", S("[!] Waypoints are not enabled!"))) --TODO: guarda se ha senso metterla nella documentazione, sennò rimuovi 'sta stringa
    return end

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
