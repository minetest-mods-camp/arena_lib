---
--- Link these functions to your mod through some commands, ie. /yourmod info arena_name
---
local S = minetest.get_translator("arena_lib")

local function value_to_string() end


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

  if not arena then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] This arena doesn't exist!")))
    return end

  local mod_ref = arena_lib.mods[mod]
  local arena_min_players = arena.min_players * #arena.teams
  local arena_max_players = arena.max_players * #arena.teams
  local teams = ""
  local min_players_per_team = ""
  local max_players_per_team = ""
  local players_inside_per_team = ""
  local spectators_inside_per_team = ""

  -- concateno eventuali team
  if arena.teams_enabled then
    min_players_per_team = minetest.colorize("#eea160", S("Players required per team: ")) .. minetest.colorize("#cfc6b8", arena.min_players) .. "\n"
    max_players_per_team = minetest.colorize("#eea160", S("Players supported per team: ")) .. minetest.colorize("#cfc6b8", arena.max_players) .. "\n"
    for i = 1, #arena.teams do
      teams = teams .. "'" .. arena.teams[i].name .. "' "
      players_inside_per_team = players_inside_per_team .. "'" .. arena.teams[i].name .. "' : " .. arena.players_amount_per_team[i] .. " "
      if mod_ref.spectate_mode then
        spectators_inside_per_team = spectators_inside_per_team .. "'" .. arena.teams[i].name .. "' : " .. arena.spectators_amount_per_team[i] .. " "
      end
    end
    players_inside_per_team = minetest.colorize("#eea160", S("Players inside per team: ")) .. minetest.colorize("#cfc6b8", players_inside_per_team) .. "\n"
    if mod_ref.spectate_mode then
      spectators_inside_per_team = minetest.colorize("#eea160", S("Spectators inside per team: ")) .. minetest.colorize("#cfc6b8", spectators_inside_per_team) .. "\n"
    end
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
  local p_names = ""
  for pl, stats in pairs(arena.players) do
    p_names = p_names .. " " .. pl
  end

  -- concateno nomi spettatori
  local sp_names = ""
  for sp_name, stats in pairs(arena.spectators) do
    sp_names = sp_names .. " " .. sp_name
  end

  -- concateno giocatori e spettatori (per verificare che campo sia giusto)
  local psp_names = ""
  local psp_amount = 0
  for psp_name, _ in pairs(arena.players_and_spectators) do
    psp_names = psp_names .. " " .. psp_name
    psp_amount = psp_amount + 1
  end

  -- concateno giocatori presenti e passati
  local ppp_names = ""
  local ppp_names_amount = 0
  for ppp_name, _ in pairs(arena.past_present_players) do
    ppp_names = ppp_names .. " " .. ppp_name
    ppp_names_amount = ppp_names_amount + 1
  end

  -- concateno giocatori presenti e passati
  local ppp_names_inside = ""
  local ppp_names_inside_amount = 0
  for ppp_name_inside, _ in pairs(arena.past_present_players_inside) do
    ppp_names_inside = ppp_names_inside .. " " .. ppp_name_inside
    ppp_names_inside_amount = ppp_names_inside_amount + 1
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
  if next(arena.sign) then
    sign_pos = minetest.pos_to_string(arena.sign)
  else
    sign_pos = "---"
  end

  -- calcolo coordinate spawn point
  local spawners_pos = ""
  if arena.teams_enabled then

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

  -- calcolo eventuale tempo
  local time = ""
  if mod_ref.time_mode ~= "none" then
    local current_time = not arena.current_time and "---" or arena.current_time
    time = minetest.colorize("#eea160", S("Initial time: ")) .. minetest.colorize("#cfc6b8", arena.initial_time .. " (" .. S("current: ") .. current_time .. ")") .. "\n"
  end

  --calcolo proprietà
  local properties = ""
  for property, _ in pairs(mod_ref.properties) do
    local value = value_to_string(arena[property])
    properties = properties .. property .. " = " .. value .. "; "
  end

  --calcolo proprietà temporanee
  local temp_properties = ""
  if arena.in_game == true then
    for temp_property, _ in pairs(mod_ref.temp_properties) do
      local value = value_to_string(arena[temp_property])
      temp_properties = temp_properties .. temp_property .. " = " .. value .. "; "
    end
  else
    for temp_property, _ in pairs(mod_ref.temp_properties) do
      temp_properties = temp_properties .. temp_property .. "; "
    end
  end

  local team_properties = ""
  if not arena.teams_enabled then
    team_properties = "---"
  else
    if arena.in_game == true then
      for i = 1, #arena.teams do
        team_properties = team_properties .. arena.teams[i].name .. ": "
        for team_property, _ in pairs(mod_ref.team_properties) do
          local value = value_to_string(arena.teams[i][team_property])
          team_properties = team_properties .. " " .. team_property .. " = " .. value .. ";"
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
    minetest.colorize("#eea160", S("Author: ")) .. minetest.colorize("#cfc6b8", arena.author ) .. "\n" ..
    minetest.colorize("#eea160", "ID: ") .. minetest.colorize("#cfc6b8", arena_ID) .. "\n" ..
    minetest.colorize("#eea160", S("Teams: ")) .. minetest.colorize("#cfc6b8", teams) .. "\n" ..
    minetest.colorize("#eea160", S("Disabled damage types: ")) .. minetest.colorize("#cfc6b8", disabled_damage_types) .. "\n" ..
    min_players_per_team ..
    max_players_per_team ..
    minetest.colorize("#eea160", S("Players required: ")) .. minetest.colorize("#cfc6b8", arena_min_players) .. "\n" ..
    minetest.colorize("#eea160", S("Players supported: ")) .. minetest.colorize("#cfc6b8", arena_max_players) .. "\n" ..
    minetest.colorize("#eea160", S("Players inside: ")) .. minetest.colorize("#cfc6b8", arena.players_amount .. " ( ".. p_names .. " )") .. "\n" ..
    players_inside_per_team ..
    minetest.colorize("#eea160", S("Spectators inside: ")) .. minetest.colorize("#cfc6b8", arena.spectators_amount .. " ( ".. sp_names .. " )") .. "\n" ..
    spectators_inside_per_team ..
    minetest.colorize("#eea160", S("Players and spectators inside: ")) .. minetest.colorize("#cfc6b8", psp_amount .. " ( ".. psp_names .. " )") .. "\n" ..
    minetest.colorize("#eea160", S("Past and present players: ")) .. minetest.colorize("#cfc6b8", ppp_names_amount .. " ( " .. ppp_names .. " )") .."\n" ..
    minetest.colorize("#eea160", S("Past and present players inside: ")) .. minetest.colorize("#cfc6b8", ppp_names_inside_amount .. " ( " .. ppp_names_inside .. " )") .."\n" ..
    minetest.colorize("#eea160", S("Enabled: ")) .. minetest.colorize("#cfc6b8", tostring(arena.enabled)) .. "\n" ..
    minetest.colorize("#eea160", S("Status: ")) .. minetest.colorize("#cfc6b8", status) .. "\n" ..
    minetest.colorize("#eea160", S("Sign: ")) .. minetest.colorize("#cfc6b8", sign_pos) .. "\n" ..
    minetest.colorize("#eea160", S("Spawn points: ")) .. minetest.colorize("#cfc6b8", #arena.spawn_points .. " ( " .. spawners_pos .. ")") .. "\n" ..
    time ..
    minetest.colorize("#eea160", S("Properties: ")) .. minetest.colorize("#cfc6b8", properties) .. "\n" ..
    minetest.colorize("#eea160", S("Temp properties: ")) .. minetest.colorize("#cfc6b8", temp_properties) .. "\n" ..
    minetest.colorize("#eea160", S("Team properties: ")) .. minetest.colorize("#cfc6b8", team_properties)
  )

end



function arena_lib.print_arena_stats(sender, mod, arena_name)

  local arena_ID, arena = arena_lib.get_arena_by_name(mod, arena_name)

  if arena == nil then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] This arena doesn't exist!")))
    return end

  if not arena.in_game and not arena.in_celebration then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] No ongoing game!")))
    return end

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



function arena_lib.flush_arena(mod, arena, sender)

  if arena.in_queue or arena.in_game then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] You can't perform this action during an ongoing game!")))
    return end

  arena.players = {}
  arena.spectators = {}
  arena.players_and_spectators = {}
  arena.past_present_players = {}
  arena.past_present_players_inside = {}
  arena.players_amount = 0

  if arena.teams_enabled then
    local mod_ref = arena_lib.mods[mod]
    for i = 1, #arena.teams do
      arena.players_amount_per_team[i] = 0
      if mod_ref.spectate_mode then
        arena.spectators_amount_per_team[i] = 0
      end
    end
  end

  arena.current_time = nil

  minetest.chat_send_player(sender, "Sluuush!")
end





----------------------------------------------
---------------FUNZIONI LOCALI----------------
----------------------------------------------

function value_to_string(value)
  if type(value) == "table" then
    return tostring(dump(value)):gsub("\n", "")
  else
    return tostring(value)
  end
end
