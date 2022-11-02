local waypoints = {} -- KEY: player name; VALUE: {Waypoints IDs}

function arena_lib.show_waypoints(p_name, arena)

  local player = minetest.get_player_by_name(p_name)

  -- se sto aggiornando, devo prima rimuovere i vecchi
  if waypoints[p_name] then
    arena_lib.remove_waypoints(p_name)
  end

  waypoints[p_name] = {}

  minetest.after(0.01, function()
    for ID, spawn in pairs(arena.spawn_points) do

      local caption = "#" .. ID

      -- se ci sono team, lo specifico nel nome
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



function arena_lib.are_waypoints_shown(p_name)
  if waypoints[p_name] then return true
  else return false
  end
end
