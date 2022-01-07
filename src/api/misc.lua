-- channel: "players", "spectators", "both"
function arena_lib.send_message_in_arena(arena, channel, msg, teamID, except_teamID)

  if channel == "players" then
    if teamID then
      if except_teamID then
        for pl_name, pl_stats in pairs(arena.players) do
          if pl_stats.teamID ~= teamID then
            minetest.chat_send_player(pl_name, msg)
          end
        end
      else
        for pl_name, pl_stats in pairs(arena.players) do
          if pl_stats.teamID == teamID then
            minetest.chat_send_player(pl_name, msg)
          end
        end
      end
    else
      for pl_name, _ in pairs(arena.players) do
        minetest.chat_send_player(pl_name, msg)
      end
    end

  elseif channel == "spectators" then
    for sp_name, _ in pairs(arena.spectators) do
      minetest.chat_send_player(sp_name, msg)
    end

  elseif channel == "both" then
    for psp_name, _ in pairs(arena.players_and_spectators) do
      minetest.chat_send_player(psp_name, msg)
    end
  end
end





----------------------------------------------
-----------------GETTERS----------------------
----------------------------------------------

function arena_lib.get_arena_by_name(mod, arena_name)

  if not arena_lib.mods[mod] then return end

  for id, arena in pairs(arena_lib.mods[mod].arenas) do
    if arena.name == arena_name then
      return id, arena end
  end
end



function arena_lib.get_arena_spawners_count(arena, team_ID)
  local count = 0
  for _, spawner in pairs(arena.spawn_points) do
    if team_ID then
      if spawner.teamID == team_ID then
        count = count +1
      end
    else
      count = count +1
    end
  end
  return count
end



function arena_lib.get_random_spawner(arena, team_ID)
  if arena.teams_enabled then
    local min = 1 + (arena.max_players * (team_ID - 1))
    local max = arena.max_players * team_ID
    return arena.spawn_points[math.random(min, max)].pos
  else
    return arena.spawn_points[math.random(1,table.maxn(arena.spawn_points))].pos
  end
end






----------------------------------------------
------------------DEPRECATED------------------
----------------------------------------------

-- to remove in 7.0
function arena_lib.send_message_players_in_arena(arena, msg, teamID, except_teamID)
  minetest.log("warning", "[ARENA_LIB] send_message_players_in_arena is deprecated. Please use send_message_in_arena instead")
  arena_lib.send_message_in_arena(arena, "players", msg, teamID, except_teamID)
end
