local S = minetest.get_translator("arena_lib")

local function property_val_to_string() end
local function table_to_string() end



function arena_lib.print_minigames(sender)
  local mgs = {}
  local str = "-------------------------\n"

  for mod, _ in pairs(arena_lib.mods) do
    table.insert(mgs, mod)
  end
  table.sort(mgs, function(a, b) return a < b end)

  for id, mod in pairs(mgs) do
    str = str .. id .. ". " .. mod .. "\n"
  end

  str = str .. "-------------------------"
  minetest.chat_send_player(sender, str)
end


function arena_lib.print_arenas(sender, mod)
  local mod_ref = arena_lib.mods[mod]

  if not mod_ref then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] This minigame doesn't exist!")))
    return end

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

  local thumbnail = arena.thumbnail == "" and "---" or arena.thumbnail

  -- calcolo eventuale musica sottofondo
  local arena_bgm = "---"
  if arena.bgm then
    arena_bgm = arena.bgm.track .. ".ogg"
  end

  local mod_ref = arena_lib.mods[mod]
  local arena_min_players = arena.min_players * #arena.teams
  local arena_max_players = arena.max_players * #arena.teams
  local teams = ""
  local min_players_per_team = ""
  local max_players_per_team = ""
  local players_inside_per_team = ""
  local spectators_inside_per_team = ""

  -- calcolo eventuali squadre
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

  -- calcolo eventuali danni disabilitati
  local disabled_damage_types = ""
  if next(mod_ref.disabled_damage_types) then
    for _, dmg_type in pairs(mod_ref.disabled_damage_types) do
      disabled_damage_types = disabled_damage_types .. " " .. dmg_type
    end
  else
    disabled_damage_types = "---"
  end

  -- calcolo nomi giocatori
  local p_names = ""
  for pl, stats in pairs(arena.players) do
    p_names = p_names .. " " .. pl
  end

  -- calcolo nomi spettatori
  local sp_names = ""
  for sp_name, stats in pairs(arena.spectators) do
    sp_names = sp_names .. " " .. sp_name
  end

  -- calcolo giocatori e spettatori (per verificare che campo sia giusto)
  local psp_names = ""
  local psp_amount = 0
  for psp_name, _ in pairs(arena.players_and_spectators) do
    psp_names = psp_names .. " " .. psp_name
    psp_amount = psp_amount + 1
  end

  -- calcolo giocatori presenti e passati
  local ppp_names = ""
  local ppp_names_amount = 0
  for ppp_name, _ in pairs(arena.past_present_players) do
    ppp_names = ppp_names .. " " .. ppp_name
    ppp_names_amount = ppp_names_amount + 1
  end

  -- calcolo giocatori presenti e passati
  local ppp_names_inside = ""
  local ppp_names_inside_amount = 0
  for ppp_name_inside, _ in pairs(arena.past_present_players_inside) do
    ppp_names_inside = ppp_names_inside .. " " .. ppp_name_inside
    ppp_names_inside_amount = ppp_names_inside_amount + 1
  end

  -- calcolo eventuali entità/aree seguibili
  local spectatable_entities = ""
  local spectatable_areas = ""
  if mod_ref.spectate_mode then
    local entities = ""
    local areas = ""
    if arena.in_game then
      for en_name, _ in pairs(arena_lib.get_spectate_entities(mod, arena_name)) do
        entities = entities .. en_name .. ", "
      end
      for ar_name, _ in pairs(arena_lib.get_spectate_areas(mod, arena_name)) do
        areas = areas .. ar_name .. ", "
      end
      entities = entities:sub(1, -3)
      areas = areas:sub(1, -3)
    else
      entities = "---"
      areas = "---"
    end

    spectatable_entities = minetest.colorize("#eea160", S("Current spectatable entities: ")) .. minetest.colorize("#cfc6b8", entities) .. "\n"
    spectatable_areas = minetest.colorize("#eea160", S("Current spectatable areas: ")) .. minetest.colorize("#cfc6b8", areas) .. "\n\n"
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

  -- calcolo entrata
  if arena.entrance == nil then
    entrance = "---"
  else
    entrance = arena_lib.entrances[arena.entrance_type].print(arena.entrance)
  end

  -- calcolo coordinate punto di spawn
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

  -- calcolo eventuale volta celeste personalizzata
  local celvault = ""
  if arena.celestial_vault then
    for elem, params in pairs(arena.celestial_vault) do
      if next(params) then
        celvault = celvault .. string.upper(elem) .. ": " .. table_to_string(params) .. "\n"
      end
    end
  else
    celvault = "---"
  end

  -- calcolo eventuale illuminazione personalizzata
  local lighting = ""
  if arena.lighting then
    lighting = table_to_string(arena.lighting)
  else
    lighting = "---"
  end

  --calcolo proprietà
  local properties = ""
  if next(mod_ref.properties) then
    for property, _ in pairs(mod_ref.properties) do
      local value = property_val_to_string(arena[property])
      properties = properties .. property .. " = " .. value .. "; "
    end
  else
    properties = "---"
  end

  --calcolo proprietà temporanee
  local temp_properties = ""
  if next(mod_ref.temp_properties) then
    if arena.in_game == true then
      for temp_property, _ in pairs(mod_ref.temp_properties) do
        local value = property_val_to_string(arena[temp_property])
        temp_properties = temp_properties .. temp_property .. " = " .. value .. "; "
      end
    else
      for temp_property, _ in pairs(mod_ref.temp_properties) do
        temp_properties = temp_properties .. temp_property .. "; "
      end
    end
  else
    temp_properties = "---"
  end

  local team_properties = ""
  if not arena.teams_enabled then
    team_properties = "---"
  else
    if arena.in_game == true then
      for i = 1, #arena.teams do
        team_properties = team_properties .. arena.teams[i].name .. ": "
        for team_property, _ in pairs(mod_ref.team_properties) do
          local value = property_val_to_string(arena.teams[i][team_property])
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
    minetest.colorize("#eea160", "ID: ") .. minetest.colorize("#cfc6b8", arena_ID) .. "\n" ..
    minetest.colorize("#eea160", S("Author: ")) .. minetest.colorize("#cfc6b8", arena.author) .. "\n" ..
    minetest.colorize("#eea160", S("Thumbnail: ")) .. minetest.colorize("#cfc6b8", thumbnail) .. "\n" ..
    minetest.colorize("#eea160", S("BGM: ")) .. minetest.colorize("#cfc6b8", arena_bgm) .. "\n" ..
    minetest.colorize("#eea160", S("Teams: ")) .. minetest.colorize("#cfc6b8", teams) .. "\n" ..
    minetest.colorize("#eea160", S("Disabled damage types: ")) .. minetest.colorize("#cfc6b8", disabled_damage_types) .. "\n\n" ..

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
    minetest.colorize("#eea160", S("Past and present players inside: ")) .. minetest.colorize("#cfc6b8", ppp_names_inside_amount .. " ( " .. ppp_names_inside .. " )") .."\n\n" ..

    spectatable_entities ..
    spectatable_areas ..

    minetest.colorize("#eea160", S("Enabled: ")) .. minetest.colorize("#cfc6b8", tostring(arena.enabled)) .. "\n" ..
    minetest.colorize("#eea160", S("Status: ")) .. minetest.colorize("#cfc6b8", status) .. "\n" ..
    minetest.colorize("#eea160", S("Entrance: ")) .. minetest.colorize("#cfc6b8", "(" .. arena.entrance_type .. ") " .. entrance) .. "\n" ..
    minetest.colorize("#eea160", S("Spawn points: ")) .. minetest.colorize("#cfc6b8", #arena.spawn_points .. " ( " .. spawners_pos .. ")") .. "\n\n" ..

    time ..
    minetest.colorize("#eea160", S("Custom sky: ")) .. minetest.colorize("#cfc6b8", celvault) .. "\n" ..
    minetest.colorize("#eea160", S("Custom lighting: ")) .. minetest.colorize("#cfc6b8", lighting) .. "\n\n" ..

    minetest.colorize("#eea160", S("Properties: ")) .. minetest.colorize("#cfc6b8", properties) .. "\n" ..
    minetest.colorize("#eea160", S("Temp properties: ")) .. minetest.colorize("#cfc6b8", temp_properties) .. "\n" ..
    minetest.colorize("#eea160", S("Team properties: ")) .. minetest.colorize("#cfc6b8", team_properties)
  )
end



function arena_lib.flush_arena(mod, arena_name, sender)

  local id, arena = arena_lib.get_arena_by_name(mod, arena_name)

  if not ARENA_LIB_EDIT_PRECHECKS_PASSED(sender, arena) then return end

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

function property_val_to_string(value)
  if type(value) == "table" then
    return tostring(dump(value)):gsub("\n", "")
  else
    return tostring(value)
  end
end



function table_to_string(table)
  local str = ""
  for k, v in pairs(table) do
    local val = ""

    if type(v) == "table" then
      if next(v) then
        val = "{ " .. table_to_string(v) .. "}"
      end
    else
      val = tostring(v)
    end

    if val ~= "" then
      str = str .. k .. " = " .. val .. "; "
    end
  end

  return str
end
