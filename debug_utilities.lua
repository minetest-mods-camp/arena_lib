---
--- Link these functions to your mod through some commands, ie. /yourmod info arena_name
---
local S = minetest.get_translator("arena_lib")


function arena_lib.print_arenas(sender, mod)

  local n = 0
  for id, arena in pairs(arena_lib.mods[mod].arenas) do
    n = n+1
    minetest.chat_send_player(sender, "ID: " .. id .. ", " .. S("name: ") .. arena.name )
  end

  minetest.chat_send_player(sender, S("Total arenas: ") .. n )

end



function arena_lib.print_arena_info(sender, mod, arena_name)
  local arena_ID, arena = arena_lib.get_arena_by_name(mod, arena_name)
  if arena == nil then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] This arena doesn't exist!")))
  return end

  local mod_ref = arena_lib.mods[mod]
  local arena_min_players = arena.min_players * #arena.teams
  local arena_max_players = arena.max_players * #arena.teams
  local teams = ""
  local min_players_per_team = ""
  local max_players_per_team = ""
  local players_inside_per_team = ""

  -- concateno eventuali team
  if #arena.teams > 1 then
    min_players_per_team = minetest.colorize("#eea160", S("Players required per team: ")) .. minetest.colorize("#cfc6b8", arena.min_players) .. "\n"
    max_players_per_team = minetest.colorize("#eea160", S("Players supported per team: ")) .. minetest.colorize("#cfc6b8", arena.max_players) .. "\n"
    for i = 1, #arena.teams do
      teams = teams .. "'" .. arena.teams[i] .. "' "
      players_inside_per_team = players_inside_per_team .. "'" .. arena.teams[i] .. "' : " .. arena.players_amount_per_team[i] .. " "
    end
    players_inside_per_team = minetest.colorize("#eea160", S("Players inside per team: ")) .. minetest.colorize("#cfc6b8", players_inside_per_team) .. "\n"
  else
    teams = "---"
  end

  -- concateno eventuali danni disabilitati
  local disabled_damage_types = ""
  if next(mod_ref.disabled_damage_types) then
    for _, dmg_type in pairs(mod_ref.disabled_damage_types) do
      disabled_damage_types = disabled_damage_types .. " " .. dmg_type
    end
  else
    disabled_damage_types = "---"
  end

  -- concateno nomi giocatori
  local names = ""
  for pl, stats in pairs(arena.players) do
    names = names .. " " .. pl
  end

  -- calcolo stato arena
  local status
  if arena.in_queue then
    status = S("in queue")
  elseif arena.in_loading then
    status = S("loading")
  elseif arena.in_game then
    status = S("in game")
  elseif arena.in_celebration then
    status = S("celebrating")
  else
    status = S("waiting")
  end

  -- calcolo cartello
  local sign_pos
  if arena.sign.x ~= nil then
    sign_pos = minetest.pos_to_string(arena.sign)
  else
    sign_pos = "---"
  end

  -- calcolo coordinate spawn point
  local spawners_pos = ""
  if #arena.teams > 1 then

    for i = 1, #arena.teams do
      spawners_pos = spawners_pos .. arena.teams[i].name .. ": "
      for j = 1 + (arena.max_players * (i-1)), arena.max_players * i  do
        if arena.spawn_points[j] then
          spawners_pos = spawners_pos .. " " .. minetest.pos_to_string(arena.spawn_points[j].pos) .. " "
        end
      end
      spawners_pos = spawners_pos .. "; "
    end

  else
    for spawn_id, spawn_params in pairs(arena.spawn_points) do
      spawners_pos = spawners_pos .. " " .. minetest.pos_to_string(spawn_params.pos) .. " "
    end
  end

  -- calcolo eventuale timer
  local timer = ""
  if arena.timer then
    if arena.timer_current then
      timer = S("Timer: ") .. arena.timer .. " (" .. S("current: ") .. arena.timer_current .. ")\n"
    else
      timer = S("Timer: ") .. arena.timer .. " (" .. S("current: ") .. "--- )\n"
    end
  end

  --calcolo proprietà
  local properties = ""
  for property, _ in pairs(mod_ref.properties) do
    properties = properties .. property .. " = " .. arena[property] .. "; "
  end

  --calcolo proprietà temporanee
  local temp_properties = ""
  if arena.in_game == true then
    for temp_property, _ in pairs(mod_ref.temp_properties) do
      temp_properties = temp_properties .. temp_property .. " = " .. arena[temp_property] .. "; "
    end
  else
    for temp_property, _ in pairs(mod_ref.temp_properties) do
      temp_properties = temp_properties .. temp_property .. "; "
    end
  end

  local team_properties = ""
  if not next(mod_ref.team_properties) then
    team_properties = "---"
  else
    if arena.in_game == true then
      for i = 1, #arena.teams do
        team_properties = team_properties .. arena.teams[i].name .. ": "
        for team_property, _ in pairs(mod_ref.team_properties) do
          team_properties = team_properties .. " " .. team_property .. " = " .. arena.teams[i][team_property] .. ";"
        end
        team_properties = team_properties .. "|"
      end
    else
      for team_property, _ in pairs(mod_ref.team_properties) do
        team_properties = team_properties .. team_property .. "; "
      end
    end
  end


  minetest.chat_send_player(sender,
    minetest.colorize("#cfc6b8", "====================================") .. "\n" ..
    minetest.colorize("#eea160", S("Name: ")) .. minetest.colorize("#cfc6b8", arena_name ) .. "\n" ..
    minetest.colorize("#eea160", "ID: ") .. minetest.colorize("#cfc6b8", arena_ID) .. "\n" ..
    minetest.colorize("#eea160", S("Teams: ")) .. minetest.colorize("#cfc6b8", teams) .. "\n" ..
    minetest.colorize("#eea160", S("Disabled damage types: ")) .. minetest.colorize("#cfc6b8", disabled_damage_types) .. "\n" ..
    min_players_per_team ..
    max_players_per_team ..
    minetest.colorize("#eea160", S("Players required: ")) .. minetest.colorize("#cfc6b8", arena_min_players) .. "\n" ..
    minetest.colorize("#eea160", S("Players supported: ")) .. minetest.colorize("#cfc6b8", arena_max_players) .. "\n" ..
    minetest.colorize("#eea160", S("Players inside: ")) .. minetest.colorize("#cfc6b8", arena.players_amount .. " ( ".. names .. " )") .. "\n" ..
    players_inside_per_team ..
    minetest.colorize("#eea160", S("Enabled: ")) .. minetest.colorize("#cfc6b8", tostring(arena.enabled)) .. "\n" ..
    minetest.colorize("#eea160", S("Status: ")) .. minetest.colorize("#cfc6b8", status) .. "\n" ..
    minetest.colorize("#eea160", S("Sign: ")) .. minetest.colorize("#cfc6b8", sign_pos) .. "\n" ..
    minetest.colorize("#eea160", S("Spawn points: ")) .. minetest.colorize("#cfc6b8", #arena.spawn_points .. " ( " .. spawners_pos .. ")") .. "\n" ..
    timer ..
    minetest.colorize("#eea160", S("Properties: ")) .. minetest.colorize("#cfc6b8", properties) .. "\n" ..
    minetest.colorize("#eea160", S("Temp properties: ")) .. minetest.colorize("#cfc6b8", temp_properties) .. "\n" ..
    minetest.colorize("#eea160", S("Team properties: ")) .. minetest.colorize("#cfc6b8", team_properties)
  )

end



function arena_lib.print_arena_stats(sender, mod, arena_name)

  local arena_ID, arena = arena_lib.get_arena_by_name(mod, arena_name)
  if arena == nil then  minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] This arena doesn't exist!"))) return end

  if not arena.in_game and not arena.in_celebration then minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] No ongoing game!"))) return end

  for pl_name, stats in pairs(arena.players) do

    -- calcolo proprietà del giocatore
    local p_properties = ""
    for k, v in pairs(arena_lib.mods[mod].player_properties) do
      p_properties = p_properties .. ",  " .. k .. ": " .. tostring(stats[k])
    end

    minetest.chat_send_player(sender,
      S("Player: ") .. pl_name ..
      S(",  kills: ") .. stats.kills ..
      S(",  deaths: ") .. stats.deaths ..
      p_properties)
  end

end
