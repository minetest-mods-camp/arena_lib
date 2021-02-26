-- in here: whatever needs to access the storage (minigames and arenas management) + deprecations
arena_lib = {}
arena_lib.mods = {}

local S = minetest.get_translator("arena_lib")
local storage = minetest.get_mod_storage()



----------------------------------------------
---------------DICHIARAZIONI------------------
----------------------------------------------

local function load_settings() end
local function init_storage() end
local function update_storage() end
local function check_for_properties() end
local function next_available_ID() end
local function is_arena_name_allowed() end

local arena_default = {
  name = "",
  author = "???",
  sign = {},
  players = {},                       -- KEY: player name, VALUE: {kills, deaths, teamID, <player_properties>}
  spectators = {},                    -- KEY: player name, VALUE: true
  players_and_spectators = {},        -- KEY: pl/sp name,  VALUE: true
  past_present_players = {},          -- KEY: player_name, VALUE: true
  past_present_players_inside = {},   -- KEY: player_name, VALUE: true
  teams = {-1},
  teams_enabled = false,
  players_amount = 0,
  players_amount_per_team = nil,
  spectators_amount = 0,
  spectators_amount_per_team = nil,
  spawn_points = {},          -- KEY: ids, VALUE: {pos, teamID}
  max_players = 4,
  min_players = 2,
  bgm = nil,
  initial_time = nil,
  current_time = nil,
  in_queue = false,
  in_loading = false,
  in_game = false,
  in_celebration = false,
  enabled = false
}



-- per inizializzare. Da lanciare all'inizio di ogni mod
function arena_lib.register_minigame(mod, def)

  local highest_arena_ID = storage:get_int(mod .. ".HIGHEST_ARENA_ID")

  --v------------------ LEGACY UPDATE, to remove in 6.0 -------------------v
  if def.hub_spawn_point then
    minetest.log("warning", "[ARENA_LIB] (" .. mod .. ") hub_spawn_point is deprecated. The parameter must be edited in game through /minigamesettings " .. mod)
  end

  if def.queue_waiting_time then
    minetest.log("warning", "[ARENA_LIB] (" .. mod .. ") queue_waiting_time is deprecated. The parameter must be edited in game through /minigamesettings " .. mod)
  end

  if def.time_mode and type(def.time_mode) == "number" then
    minetest.log("warning", "[ARENA_LIB] (" .. mod .. ") time_mode with numeric values is deprecated. Use `none`, `incremental` or `decremental` instead")
    if def.time_mode == nil or def.time_mode == 0 then
      def.time_mode = "none"
    elseif def.time_mode == 1 then
      def.time_mode = "incremental"
    elseif def.time_mode == 2 then
      def.time_mode = "decremental"
    else
      def.time_mode = "none"
    end
  end
  --^------------------ LEGACY UPDATE, to remove in 6.0 -------------------^

  arena_lib.mods[mod] = {}
  arena_lib.mods[mod].arenas = {}           -- KEY: (int) arenaID , VALUE: (table) arena properties
  arena_lib.mods[mod].highest_arena_ID = highest_arena_ID

  local mod_ref = arena_lib.mods[mod]

  -- /minigamesettings parameters
  load_settings(mod)

  --default parameters
  mod_ref.prefix = "[Arena_lib] "
  mod_ref.teams = {-1}
  mod_ref.teams_color_overlay = nil
  mod_ref.is_team_chat_default = false
  mod_ref.chat_all_prefix = "[" .. S("arena") .. "] "
  mod_ref.chat_team_prefix = "[" .. S("team") .. "] "
  mod_ref.chat_spectate_prefix = "[" .. S("spectator") .. "] "
  mod_ref.chat_all_color = "#ffffff"
  mod_ref.chat_team_color = "#ddfdff"
  mod_ref.chat_spectate_color = "#dddddd"
  mod_ref.fov = nil
  mod_ref.camera_offset = nil
  mod_ref.hotbar = nil
  mod_ref.join_while_in_progress = false
  mod_ref.spectate_mode = true
  mod_ref.keep_inventory = false
  mod_ref.show_nametags = false
  mod_ref.show_minimap = false
  mod_ref.time_mode = "none"
  mod_ref.load_time = 5           -- time in the loading phase (the pre-match)
  mod_ref.celebration_time = 5    -- time in the celebration phase
  mod_ref.in_game_physics = nil
  mod_ref.disabled_damage_types = {}
  mod_ref.properties = {}
  mod_ref.temp_properties = {}
  mod_ref.player_properties = {}
  mod_ref.team_properties = {}

  if def.prefix then
    mod_ref.prefix = def.prefix
  end

  if def.teams and type(def.teams) == "table" then
    mod_ref.teams = def.teams

    if def.teams_color_overlay then
      mod_ref.teams_color_overlay = def.teams_color_overlay
    end

    if def.is_team_chat_default == true then
      mod_ref.is_team_chat_default = def.is_team_chat_default
    end

    if def.chat_team_prefix then
      mod_ref.chat_team_prefix = def.chat_team_prefix
    end

    if def.chat_team_color then
      mod_ref.chat_team_color = def.chat_team_color
    end
  end

  if def.chat_all_prefix then
    mod_ref.chat_all_prefix = def.chat_all_prefix
  end

  if def.chat_all_color then
    mod_ref.chat_all_color = def.chat_all_color
  end

  if def.chat_spectate_prefix then
    mod_ref.chat_spectate_prefix = def.chat_spectate_prefix
  end

  if def.chat_spectate_color then
    mod_ref.chat_spectate_color = def.chat_spectate_color
  end

  if def.fov then
    mod_ref.fov = def.fov
  end

  if def.camera_offset and type(def.camera_offset) == "table" then
    mod_ref.camera_offset = def.camera_offset
  end

  if def.hotbar and type(def.hotbar) == "table" then
    mod_ref.hotbar = {}
    mod_ref.hotbar.slots = def.hotbar.slots
    mod_ref.hotbar.background_image = def.hotbar.background_image
    mod_ref.hotbar.selected_image = def.hotbar.selected_image
  end

  if def.join_while_in_progress == true then
    mod_ref.join_while_in_progress = def.join_while_in_progress
  end

  if def.spectate_mode == false then
    mod_ref.spectate_mode = false
  end

  if def.keep_inventory == true then
    mod_ref.keep_inventory = true
  end

  if def.show_nametags == true then
    mod_ref.show_nametags = true
  end

  if def.show_minimap == true then
    mod_ref.show_minimap = true
  end

  if def.time_mode then
    mod_ref.time_mode = def.time_mode
  end

  if def.load_time then
    mod_ref.load_time = def.load_time
  end

  if def.celebration_time then
    mod_ref.celebration_time = def.celebration_time
  end

  if def.in_game_physics and type(def.in_game_physics) == "table" then
    mod_ref.in_game_physics = def.in_game_physics
  end

  if def.disabled_damage_types and type(def.disabled_damage_types) == "table" then
    mod_ref.disabled_damage_types = def.disabled_damage_types
  end

  if def.properties then
    mod_ref.properties = def.properties
  end

  if def.temp_properties then
    mod_ref.temp_properties = def.temp_properties
  end

  if def.player_properties then
    mod_ref.player_properties = def.player_properties
  end

  if def.team_properties then
    mod_ref.team_properties = def.team_properties
  end

  init_storage(mod, mod_ref)

end



function arena_lib.change_mod_settings(sender, mod, setting, new_value)

  local mod_settings = arena_lib.mods[mod].settings

  -- se la proprietà non esiste
  if mod_settings[setting] == nil then
    if sender then minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] Parameters don't seem right!")))
    else minetest.log("warning", "[ARENA_LIB] [!] Settings - Parameters don't seem right!") end
    return end

  ----- v inizio conversione stringa nel tipo corrispettivo v -----
  local func, error_msg = loadstring("return (" .. new_value .. ")")

  -- se non ritorna una sintassi corretta
  if not func then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", "[SYNTAX!] " .. error_msg))
    return end

  setfenv(func, {})

  local good, result = pcall(func)

  -- se le operazioni della funzione causano errori
  if not good then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", "[RUNTIME!] " .. result))
    return end

  new_value = result
  ----- ^ fine conversione stringa nel tipo corrispettivo ^ -----

  -- se il tipo è diverso dal precedente
  if type(mod_settings[setting]) ~= type(new_value) then
    if sender then minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] You can't change type!")))
    else minetest.log("warning", "[ARENA_LIB] [!] Minigame parameters - You can't change type!") end
    return end

  mod_settings[setting] = new_value
  storage:set_string(mod .. ".SETTINGS", minetest.serialize(mod_settings))

  if sender then minetest.chat_send_player(sender, S("Parameter @1 successfully overwritten", setting))
  else minetest.log("action", "[ARENA_LIB] Parameter " .. setting .. " successfully overwritten") end

end





----------------------------------------------
---------------GESTIONE ARENA-----------------
----------------------------------------------

function arena_lib.create_arena(sender, mod, arena_name, min_players, max_players)

  local mod_ref = arena_lib.mods[mod]
  local ID = next_available_ID(mod_ref)

  -- controllo nome
  if not is_arena_name_allowed(sender, mod, arena_name) then return end

  -- controllo che non abbiano messo parametri assurdi per i giocatori minimi/massimi
  if min_players and max_players then
    if min_players > max_players or min_players == 0 or max_players < 2 then
      minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] Parameters don't seem right!")))
      return end
  end

  -- creo l'arena
  mod_ref.arenas[ID] = table.copy(arena_default)

  local arena = mod_ref.arenas[ID]

  -- sovrascrivo con i parametri della funzione
  arena.name = arena_name
  if min_players and max_players then
    arena.min_players = min_players
    arena.max_players = max_players
  end

  -- eventuali squadre
  if #mod_ref.teams > 1 then
    arena.teams = {}
    arena.teams_enabled = true
    arena.players_amount_per_team = {}

    for k, t_name in pairs(mod_ref.teams) do
      arena.teams[k] = {name = t_name}
      arena.players_amount_per_team[k] = 0
    end

    if mod_ref.spectate_mode then
      arena.spectators_amount_per_team = {}
      for k, t_name in pairs(mod_ref.teams) do
        arena.spectators_amount_per_team[k] = 0
      end
    end
  end

  -- eventuale tempo
  if mod_ref.time_mode == "incremental" then
    arena.initial_time = 0
  elseif mod_ref.time_mode == "decremental" then
    arena.initial_time = 300
  end

  -- aggiungo eventuali proprietà
  for property, value in pairs(mod_ref.properties) do
    arena[property] = value
  end

  mod_ref.highest_arena_ID = table.maxn(mod_ref.arenas)

  -- aggiungo allo storage
  update_storage(false, mod, ID, arena)
  -- aggiorno l'ID globale nello storage
  storage:set_int(mod .. ".HIGHEST_ARENA_ID", mod_ref.highest_arena_ID)

  minetest.chat_send_player(sender, mod_ref.prefix .. S("Arena @1 successfully created", arena_name))

end



function arena_lib.remove_arena(sender, mod, arena_name, in_editor)

  local id, arena = arena_lib.get_arena_by_name(mod, arena_name)

  if not in_editor then
    if not ARENA_LIB_EDIT_PRECHECKS_PASSED(sender, arena) then return end
  end

  -- rimozione cartello coi rispettivi metadati
  if arena.sign ~= nil then
    minetest.set_node(arena.sign, {name = "air"})
    end

  local mod_ref = arena_lib.mods[mod]

  -- rimozione arena e aggiornamento highest_arena_ID
  mod_ref.arenas[id] = nil
  mod_ref.highest_arena_ID = table.maxn(mod_ref.arenas)

  -- rimozione nello storage
  update_storage(true, mod, id)

  minetest.chat_send_player(sender, mod_ref.prefix .. S("Arena @1 successfully removed", arena_name))

end



function arena_lib.rename_arena(sender, mod, arena_name, new_name, in_editor)

  local id, arena = arena_lib.get_arena_by_name(mod, arena_name)

  if not in_editor then
    if not ARENA_LIB_EDIT_PRECHECKS_PASSED(sender, arena) then return end
  end

  -- controllo nome
  if not is_arena_name_allowed(sender, mod, new_name) then return end

  local old_name = arena.name

  arena.name = new_name

  -- aggiorno il cartello, se esiste
  if next(arena.sign) then
    arena_lib.update_sign(arena)
  end

  update_storage(false, mod, id, arena)

  minetest.chat_send_player(sender, arena_lib.mods[mod].prefix .. S("Arena @1 successfully renamed in @2", old_name, new_name))
  return true
end



function arena_lib.set_author(sender, mod, arena_name, author, in_editor)

  local id, arena = arena_lib.get_arena_by_name(mod, arena_name)

  if not in_editor then
    if not ARENA_LIB_EDIT_PRECHECKS_PASSED(sender, arena) then return end
  end

  if type(author) ~= "string" then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] Parameters don't seem right!")))
    return
  elseif author == nil or not string.match(author, "[%w%p]+") then
    arena.author = "???"
    minetest.chat_send_player(sender, arena_lib.mods[mod].prefix .. S("@1's author succesfully removed", arena.name))
  else
    arena.author = author
    minetest.chat_send_player(sender, arena_lib.mods[mod].prefix .. S("@1's author succesfully changed to @2", arena.name, arena.author))
  end

  update_storage(false, mod, id, arena)
end



function arena_lib.change_arena_property(sender, mod, arena_name, property, new_value, in_editor)

  local id, arena = arena_lib.get_arena_by_name(mod, arena_name)

  if not in_editor then
    if not ARENA_LIB_EDIT_PRECHECKS_PASSED(sender, arena) then return end
  end

  -- se la proprietà non esiste
  if arena[property] == nil then
    if sender then minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] Parameters don't seem right!")))
    else minetest.log("warning", "[ARENA_LIB] [!] Properties - Parameters don't seem right!") end
    return end

  -- se da editor, converto la stringa nel tipo corrispettivo
  if in_editor then
    local func, error_msg = loadstring("return (" .. new_value .. ")")

    -- se non ritorna una sintassi corretta
    if not func then
      minetest.chat_send_player(sender, minetest.colorize("#e6482e", "[SYNTAX!] " .. error_msg))
      return end

    setfenv(func, {})

    local good, result = pcall(func)

    -- se le operazioni della funzione causano errori
    if not good then
      minetest.chat_send_player(sender, minetest.colorize("#e6482e", "[RUNTIME!] " .. result))
      return end

    new_value = result
  end

  -- se il tipo è diverso dal precedente
  if type(arena[property]) ~= type(new_value) then
    if sender then minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] You can't change type!")))
    else minetest.log("warning", "[ARENA_LIB] [!] Properties - You can't change type!") end
    return end

  arena[property] = new_value
  update_storage(false, mod, id, arena)

  if sender then minetest.chat_send_player(sender, S("Parameter @1 successfully overwritten", property))
  else minetest.log("action", "[ARENA_LIB] Parameter " .. property .. " successfully overwritten") end
end



function arena_lib.change_players_amount(sender, mod, arena_name, min_players, max_players, in_editor)

  local id, arena = arena_lib.get_arena_by_name(mod, arena_name)

  if not in_editor then
    if not ARENA_LIB_EDIT_PRECHECKS_PASSED(sender, arena) then return end
  end

  -- salvo i vecchi parametri così da poterne modificare anche solo uno senza if lunghissimi
  local old_min_players = arena.min_players
  local old_max_players = arena.max_players

  arena.min_players = min_players or arena.min_players
  arena.max_players = max_players or arena.max_players

  -- se ha parametri assurdi, annullo
  if arena.min_players > arena.max_players or arena.min_players == 0 or arena.max_players < 2 then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] Parameters don't seem right!")))
    arena.min_players = old_min_players
    arena.max_players = old_max_players
  return end

  -- se i giocatori massimi sono cambiati, svuoto i vecchi spawner per evitare problemi
  if max_players and old_max_players ~= max_players then
    arena_lib.set_spawner(sender, mod, arena_name, nil, "deleteall", nil, in_editor)
  end

  -- aggiorno il cartello, se esiste
  if next(arena.sign) then
    arena_lib.update_sign(arena)
  end

  update_storage(false, mod, id, arena)

  minetest.chat_send_player(sender, arena_lib.mods[mod].prefix .. S("Players amount successfully changed ( min @1 | max @2 )", arena.min_players, arena.max_players))

  -- ritorno true per procedere al cambio di stack nell'editor
  return true
end



function arena_lib.toggle_teams_per_arena(sender, mod, arena_name, enable, in_editor)      -- enable can be 0 or 1

  local id, arena = arena_lib.get_arena_by_name(mod, arena_name)

  if not in_editor then
    if not ARENA_LIB_EDIT_PRECHECKS_PASSED(sender, arena) then return end
  end

  -- se non ci sono team nella mod, annullo
  if not next(arena_lib.mods[mod].teams) then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] Teams are not enabled!")))
    return end

  -- se i team sono già in quello stato, annullo
  if enable == arena.teams_enabled then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] Nothing to do here!")))
    return end

  -- se abilito
  if enable == 1 then
    arena.teams = {}
    arena.players_amount_per_team = {}

    for k, t_name in pairs(arena_lib.mods[mod].teams) do
      arena.teams[k] = {name = t_name}
      arena.players_amount_per_team[k] = 0
    end

    arena.teams_enabled = true

    minetest.chat_send_player(sender, S("Teams successfully enabled for the arena @1", arena_name))

  -- se disabilito
  elseif enable == 0 then
    arena.teams = {-1}
    arena.players_amount_per_team = nil
    arena.teams_enabled = false
    minetest.chat_send_player(sender, S("Teams successfully disabled for the arena @1", arena_name))

  -- sennò ho scritto male e annullo
  else
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] Parameters don't seem right!")))
    return
  end

  -- svuoto i vecchi spawner per evitare problemi
  arena_lib.set_spawner(sender, mod, arena_name, nil, "deleteall", nil, in_editor)

  -- aggiorno il cartello, se esiste
  if next(arena.sign) then
    arena_lib.update_sign(arena)
  end

  update_storage(false, mod, id, arena)
end



-- Gli spawn points si impostano prendendo la coordinata del giocatore che lancia il comando.
-- Non ci possono essere più spawn points del numero massimo di giocatori.
-- 'param' può essere: "overwrite", "delete", "deleteall"
function arena_lib.set_spawner(sender, mod, arena_name, teamID_or_name, param, ID, in_editor)

  local id, arena = arena_lib.get_arena_by_name(mod, arena_name)

  if not in_editor then
    if not ARENA_LIB_EDIT_PRECHECKS_PASSED(sender, arena) then return end
  end

  local mod_ref = arena_lib.mods[mod]
  local team
  local team_ID

  if teamID_or_name then
    if type(teamID_or_name) == "number" then
      team_ID = teamID_or_name
      team = mod_ref.teams[teamID_or_name]
    elseif type(teamID_or_name) == "string" then
      team = teamID_or_name
    end

    -- controllo team
    if not arena_lib.is_team_declared(mod_ref, team) then
      minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] This team doesn't exist!")))
      return end
  end

  local pos = vector.round(minetest.get_player_by_name(sender):get_pos())       -- tolgo i decimali per immagazzinare un int
  local mod_ref = arena_lib.mods[mod]

  -- controllo parametri
  if param then
    -- se overwrite, sovrascrivo
    if param == "overwrite" then

      -- è inutile specificare un team. Avviso per non confondere
      if team then
        minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] No team must be specified for this function!")))
        return end

      -- se lo spawner da sovrascrivere non esiste, annullo
      if arena.spawn_points[ID].pos == nil then
        minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] No spawner with that ID to overwrite!")))
        return end

      arena.spawn_points[ID].pos = pos
      minetest.chat_send_player(sender, mod_ref.prefix .. S("Spawn point #@1 successfully overwritten", ID))

    -- se delete, cancello
    elseif param == "delete" then

      -- è inutile specificare un team. Avviso per non confondere
      if team then
        minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] No team must be specified for this function!")))
        return end

      if arena.spawn_points[ID] == nil then
        minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] No spawner with that ID to delete!")))
        return end

      arena.spawn_points[ID] = nil

      -- se i waypoint sono mostrati, li aggiorno
      if arena_lib.are_waypoints_shown(sender) then
        arena_lib.show_waypoints(sender, arena)
      end

      minetest.chat_send_player(sender, mod_ref.prefix .. S("Spawn point #@1 successfully deleted", ID))

    -- se deleteall, li cancello tutti
    elseif param == "deleteall" then

      if team then
        for id, spawner in pairs(arena.spawn_points) do
          if spawner.teamID == team_ID then
            arena.spawn_points[id] = nil
          end
        end
        minetest.chat_send_player(sender, S("All the spawn points belonging to team @1 have been removed", team))
      else
        arena.spawn_points = {}
        minetest.chat_send_player(sender, S("All the spawn points have been removed"))
      end

      -- se i waypoint sono mostrati, li aggiorno
      if arena_lib.are_waypoints_shown(sender) then
        arena_lib.show_waypoints(sender, arena)
      end

    else
      minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] Unknown parameter!")))
    end

  update_storage(false, mod, id, arena)
  return
  end

  -- sennò sto creando un nuovo spawner

  -- se c'è già uno spawner in quel punto, annullo
  for id, spawn in pairs(arena.spawn_points) do
    if minetest.serialize(pos) == minetest.serialize(spawn.pos) then
      minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] There's already a spawn in this point!")))
      return end
  end

  local spawn_points_count = arena_lib.get_arena_spawners_count(arena, team_ID)    -- (se team_ID è nil, ritorna in automatico i punti spawn totali)

  -- se provo a impostare uno spawn point di troppo, annullo
  if spawn_points_count == arena.max_players then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] Spawn points can't exceed the maximum number of players!")))
  return end

  local next_available_spawnID = 1

  if team then
    -- ottengo l'ID del team se non mi è stato passato come parametro
    if type(team_ID) ~= "number" then
      for i = 1, #arena.teams do
        if arena.teams[i].name == team then
          team_ID = i
        end
      end
    end

    -- prendo il primo spawner di quel team
    next_available_spawnID = 1 + (arena.max_players * (team_ID -1))

    -- se già esiste...
    if arena.spawn_points[next_available_spawnID] then

      -- ...itero tra gli spawner seguenti finché non ne trovo uno vuoto
      while next(arena.spawn_points, next_available_spawnID) do
        -- ma se il next mi trova uno spawner con distacco > 1, vuol dire che sono al capolinea
        -- perché quello trovato appartiene o a un altro team o è un buco nello stesso team (ottenuto dal cancellare). Rompo l'iterare
        if next(arena.spawn_points, next_available_spawnID) ~= next_available_spawnID +1 then
          break
        end
        next_available_spawnID = next_available_spawnID +1
      end

      -- trovato quello vuoto, porto next_available_spawnID alla sua posizione (+1)
      next_available_spawnID = next_available_spawnID +1
    end

  else
    -- ottengo l'ID del prossimo spawner disponibile
    for k, v in ipairs(arena.spawn_points) do
      next_available_spawnID = k +1
    end
  end

  -- imposto lo spawner
  arena.spawn_points[next_available_spawnID] = {pos = pos, teamID = team_ID}

  -- se i waypoint sono mostrati, li aggiorno
  if arena_lib.are_waypoints_shown(sender) then
    arena_lib.show_waypoints(sender, arena)
  end

  minetest.chat_send_player(sender, mod_ref.prefix .. S("Spawn point #@1 successfully set", next_available_spawnID))

  update_storage(false, mod, id, arena)
end



-- 2 approcci: da editor e da linea di comando (chat)
-- l'editor utilizza sender, pos e remove. Colpisce un cartello (pos) e fa una determinata azione (remove true/false)
-- la linea di comando usa sender, mod e arena_name. Prende dove guarda il giocatore e si accerta che è un cartello (non richiede quindi hotbar o inventari di alcun tipo)
function arena_lib.set_sign(sender, pos, remove, mod, arena_name)

  local id = 0
  local arena = {}

  -- se uso la riga di comando, controllo se sto guardando un cartello
  if mod then
    id, arena = arena_lib.get_arena_by_name(mod, arena_name)

    if not ARENA_LIB_EDIT_PRECHECKS_PASSED(sender, arena) then return end

    local player = minetest.get_player_by_name(sender)
    local p_pos = player:get_pos()
    local p_eye_pos = { x = p_pos.x, y = p_pos.y + 1.475, z = p_pos.z }
    local to = vector.add(p_eye_pos, vector.multiply(player:get_look_dir(), 5))
    local ray = Raycast(p_eye_pos, to)

    -- cerco un cartello
    for hit in ray do
      if hit.type == "node" then
        local node = minetest.get_node(hit["under"])
        if string.match(node.name, "arena_lib:sign") then
          pos = hit["under"]
          break
        end
      end
    end

    -- se non ha trovato niente, esco
    if pos == nil then
      minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] That's not an arena_lib sign!")))
    return end

  -- se uso l'editor
  else

    local player = minetest.get_player_by_name(sender)

    mod = player:get_meta():get_string("arena_lib_editor.mod")
    id, arena = arena_lib.get_arena_by_name(mod, player:get_meta():get_string("arena_lib_editor.arena"))
  end

  local mod_ref = arena_lib.mods[mod]

  -- se c'è già un cartello assegnato
  if next(arena.sign) ~= nil then
    -- dal linea di comando non fa distinzione (nil), sennò sto usando lo strumento per rimuovere da editor (remove == true)
    if remove == nil or remove == true then
      if minetest.serialize(pos) == minetest.serialize(arena.sign) then
        minetest.set_node(pos, {name = "air"})
        arena.sign = {}
        minetest.chat_send_player(sender, mod_ref.prefix .. S("Sign of arena @1 successfully removed", arena.name))
        update_storage(false, mod, id, arena)
      else
        minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] This sign doesn't belong to @1!", arena.name)))
      end
    elseif remove == false then
      minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] There is already a sign for this arena!")))
    end
  return
  elseif remove == true then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] There is no sign to remove assigned to @1!", arena.name)))
    return
  end

  -- aggiungo il cartello ai cartelli dell'arena
  arena.sign = pos
  update_storage(false, mod, id, arena)

  -- cambio la scritta
  arena_lib.update_sign(arena)

  -- salvo il nome della mod e l'ID come metadato nel cartello
  minetest.get_meta(pos):set_string("mod", mod)
  minetest.get_meta(pos):set_int("arenaID", id)

  minetest.chat_send_player(sender, mod_ref.prefix .. S("Sign of arena @1 successfully set", arena.name))

end



function arena_lib.set_bgm(sender, mod, arena_name, track, title, author, volume, pitch, in_editor)

  local id, arena = arena_lib.get_arena_by_name(mod, arena_name)

  if not in_editor then
    if not ARENA_LIB_EDIT_PRECHECKS_PASSED(sender, arena) then return end
  end

  if track == nil then
    arena.bgm = nil
  else
    arena.bgm = {
      track  = track,
      title  = title,
      author = author,
      gain   = volume,
      pitch  = pitch
    }
  end

  update_storage(false, mod, id, arena)
  minetest.chat_send_player(sender, arena_lib.mods[mod].prefix .. S("Background music of arena @1 successfully overwritten", arena.name))
end



function arena_lib.set_timer(sender, mod, arena_name, timer, in_editor)

  local id, arena = arena_lib.get_arena_by_name(mod, arena_name)

  if not in_editor then
    if not ARENA_LIB_EDIT_PRECHECKS_PASSED(sender, arena) then return end
  end

  local mod_ref = arena_lib.mods[mod]

  -- se la mod non supporta i timer
  if mod_ref.time_mode ~= "decremental" then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] [!] Timers are not enabled in this mod!") .. " (time_mode = 'decremental')"))
    return end

  -- se è inferiore a 1
  if timer < 1 then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] Parameters don't seem right!")))
    return end

  arena.initial_time = timer
  update_storage(false, mod, id, arena)

  minetest.chat_send_player(sender, mod_ref.prefix .. S("Arena @1's timer is now @2 seconds", arena_name, timer))
end



function arena_lib.enable_arena(sender, mod, arena_name, in_editor)

  local id, arena = arena_lib.get_arena_by_name(mod, arena_name)

  if not in_editor then
    if not ARENA_LIB_EDIT_PRECHECKS_PASSED(sender, arena) then return end
  end

  local arena_max_players = arena.max_players * #arena.teams

  -- check requisiti: spawner
  if arena_lib.get_arena_spawners_count(arena) < arena_max_players then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] Insufficient spawners, the arena can't be enabled!")))
    arena.enabled = false
  return end

  -- cartello
  if not next(arena.sign) then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] Sign not set, the arena can't be enabled!")))
    arena.enabled = false
  return end

  local mod_ref = arena_lib.mods[mod]

  -- eventuali controlli personalizzati
  if mod_ref.on_enable then
    if not mod_ref.on_enable(arena, sender) then return end
  end

  -- se sono nell'editor, vengo buttato fuori
  if arena_lib.is_player_in_edit_mode(sender) then
    arena_lib.quit_editor(minetest.get_player_by_name(sender))
  end

  -- abilito
  arena.enabled = true
  arena_lib.update_sign(arena)
  update_storage(false, mod, id, arena)

  minetest.chat_send_player(sender, mod_ref.prefix .. S("Arena @1 successfully enabled", arena_name))
  return true
end



function arena_lib.disable_arena(sender, mod, arena_name)

  local mod_ref = arena_lib.mods[mod]
  local id, arena = arena_lib.get_arena_by_name(mod, arena_name)

  if not ARENA_LIB_EDIT_PRECHECKS_PASSED(sender, arena, true) then return end

  -- se è già disabilitata, annullo
  if not arena.enabled then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] The arena is already disabled!")))
    return end

  -- se una partita è in corso, annullo
  if arena.in_loading or arena.in_game or arena.in_celebration then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] You can't disable an arena during an ongoing game!")))
    return end

  -- eventuali controlli personalizzati
  if mod_ref.on_disable then
    if not mod_ref.on_disable(arena, sender) then return end
  end

  -- se c'è gente rimasta è in coda: annullo la coda e li avviso della disabilitazione
  for pl_name, stats in pairs(arena.players) do
    arena_lib.remove_player_from_queue(pl_name)
    minetest.chat_send_player(pl_name, minetest.colorize("#e6482e", S("[!] The arena you were queueing for has been disabled... :(")))
  end

  -- disabilito
  arena.enabled = false
  arena_lib.update_sign(arena)
  update_storage(false, mod, id, arena)

  minetest.chat_send_player(sender, mod_ref.prefix .. S("Arena @1 successfully disabled", arena_name))
  return true
end





----------------------------------------------
--------------------UTILS---------------------
----------------------------------------------

-- internal use only
function arena_lib.store_inventory(player)

  if arena_lib.STORE_INVENTORY_MODE == "mod_db" then

    local p_inv = player:get_inventory()
    local stored_inv = {}

    -- itero ogni lista non vuota per convertire tutti gli itemstack in tabelle (sennò non li serializza)
    for listname, content in pairs(p_inv:get_lists()) do
      if not p_inv:is_empty(listname) then
        stored_inv[listname] = {}
        for i_name, i_def in pairs(content) do
          stored_inv[listname][i_name] = i_def:to_table()
        end
      end
    end

    storage:set_string(player:get_player_name() .. ".INVENTORY", minetest.serialize(stored_inv))
  -- TODO: storaggio database esterno
  --elseif arena_lib.STORE_INVENTORY_MODE == "external_db" then
  end

  player:get_inventory():set_list("main",{})
  player:get_inventory():set_list("craft",{})
end



-- internal use only
function arena_lib.restore_inventory(p_name)

  if arena_lib.STORE_INVENTORY_MODE == "mod_db" and storage:get_string(p_name .. ".INVENTORY") ~= "" then

    local stored_inv = minetest.deserialize(storage:get_string(p_name .. ".INVENTORY"))
    local current_inv = minetest.get_player_by_name(p_name):get_inventory()

    -- ripristino l'inventario
    for listname, content in pairs(stored_inv) do
      -- se una lista non esiste più (es. son cambiate le mod), la rimuovo
      if not current_inv:get_list(listname) then
        stored_inv[listname] = nil
      else
        for i_name, i_def in pairs(content) do
          stored_inv[listname][i_name] = ItemStack(i_def)
        end
      end
    end

    -- quando una lista viene salvata, la sua grandezza equivarrà all'ultimo slot contenente
    -- un oggetto. Per evitare quindi che reimpostando la lista, l'inventario si rimpicciolisca,
    -- salvo prima la grandezza dell'inventario immacolato, applico la lista e poi reimposto la grandezza.
    -- Questo mi evita di dover salvare nel database la grandezza di ogni lista.
    for listname, _ in pairs (current_inv:get_lists()) do
      local list_size = current_inv:get_size(listname)
      current_inv:set_list(listname, stored_inv[listname])
      current_inv:set_size(listname, list_size)
    end

    storage:set_string(p_name .. ".INVENTORY", "")
  -- TODO: storaggio database esterno
  --elseif arena_lib.STORE_INVENTORY_MODE == "external_db" then
  end
end





----------------------------------------------
---------------FUNZIONI LOCALI----------------
----------------------------------------------

function load_settings(mod)

  -- primo avvio
  if storage:get_string(mod .. ".SETTINGS") == "" then
    local default_settings = {
      hub_spawn_point = { x = 0, y = 20, z = 0},
      queue_waiting_time = 10
    }
    arena_lib.mods[mod].settings = default_settings
    storage:set_string(mod .. ".SETTINGS", minetest.serialize(default_settings))
  else
    arena_lib.mods[mod].settings = minetest.deserialize(storage:get_string(mod .. ".SETTINGS"))
  end
end



function init_storage(mod, mod_ref)

  arena_lib.mods[mod] = mod_ref

  -- aggiungo le arene
  for i = 1, arena_lib.mods[mod].highest_arena_ID do

    local arena_str = storage:get_string(mod .. "." .. i)

    -- se c'è una stringa con quell'ID, aggiungo l'arena e ne aggiorno l'eventuale cartello
    if arena_str ~= "" then
      local arena = minetest.deserialize(arena_str)
      local to_update = false

      --v------------------ LEGACY UPDATE, to remove in 6.0 -------------------v
      if not arena.author then
        arena.author = "???"
        to_update = true
      end
      --^------------------ LEGACY UPDATE, to remove in 6.0 -------------------^

      --v------------------ LEGACY UPDATE, to remove in 7.0 -------------------v
      if not arena.spectators then
        arena.spectators = {}
        arena.spectators_amount = 0
        arena.players_and_spectators = {}
        arena.past_present_players = {}
        arena.past_present_players_inside = {}
        to_update = true
      end
      --^------------------ LEGACY UPDATE, to remove in 7.0 -------------------^

      -- gestione squadre
      if arena.teams_enabled and not (#mod_ref.teams > 1) then                  -- se avevo abilitato le squadre e ora le ho rimosse
        arena.players_amount_per_team = nil
        arena.teams = {-1}
        arena.teams_enabled = false
        arena.spectators_amount_per_team = nil
      elseif #mod_ref.teams > 1 and arena.teams_enabled then                    -- sennò le genero per tutte le arene con teams_enabled
        arena.players_amount_per_team = {}
        arena.spectators_amount_per_team = {}
        arena.teams = {}

        for k, t_name in pairs(mod_ref.teams) do
          arena.players_amount_per_team[k] = 0
          arena.spectators_amount_per_team[k] = 0
          arena.teams[k] = {name = t_name}
        end

      end

      local arena_max_players = arena.max_players * #arena.teams

      -- resetto spawner se ho cambiato il numero di team
      if arena_max_players ~= #arena.spawn_points then
        to_update = true
        arena.enabled = false
        arena.spawn_points = {}
        minetest.log("action", "[ARENA_LIB] spawn points of arena " .. arena.name ..
          " has been reset due to not coinciding with the maximum amount of players (" .. arena_max_players .. ")")
      end

      -- gestione tempo
      if mod_ref.time_mode == "none" and arena.initial_time then                     -- se avevo abilitato il tempo e ora l'ho rimosso, lo tolgo dalle arene
        arena.initial_time = nil
        to_update = true
      elseif mod_ref.time_mode ~= "none" and not arena.initial_time then             -- se li ho abilitati ora e le arene non ce li hanno, glieli aggiungo
        arena.initial_time = mod_ref.time_mode == "incremental" and 0 or 300
        to_update = true
      elseif mod_ref.time_mode == "incremental" and arena.initial_time > 0 then      -- se ho disabilitato i timer e le arene ce li avevano, porto il tempo a 0
        arena.initial_time = 0
        to_update = true
      elseif mod_ref.time_mode == "decremental" and arena.initial_time == 0 then     -- se ho abilitato i timer e le arene partivano da 0, imposto il timer a 5 minuti
        arena.initial_time = 300
        to_update = true
      end

      arena_lib.mods[mod].arenas[i] = arena

      if to_update then
        update_storage(false, mod, i, arena)
      end

      --signs_lib ha bisogno di un attimo per caricare sennò tira errore
      minetest.after(0.01, function()
        if next(arena.sign) then                                        -- se non è ancora stato registrato nessun cartello per l'arena, evito il crash
          arena_lib.update_sign(arena)
        end
      end)

    end
  end

  check_for_properties(mod, mod_ref)
  minetest.log("action", "[ARENA_LIB] Mini-game " .. mod .. " loaded")
end



function update_storage(erase, mod, id, arena)

  -- ogni mod e ogni arena vengono salvate seguendo il formato mod.ID
  local entry = mod .."." .. id

  if erase then
    storage:set_string(entry, "")
    storage:set_string(mod .. ".HIGHEST_ARENA_ID", arena_lib.mods[mod].highest_arena_ID)
  else
    storage:set_string(entry, minetest.serialize(arena))
  end

end



-- le proprietà vengono salvate nello storage senza valori, in una coppia id-proprietà. Sia per leggerezza, sia perché non c'è bisogno di paragonarne i valori
function check_for_properties(mod, mod_ref)

  local old_properties = storage:get_string(mod .. ".PROPERTIES")
  local has_old_properties = old_properties ~= ""
  local has_new_properties = next(mod_ref.properties) ~= nil

  -- se non ce n'erano prima e non ce ne sono ora, annullo
  if not has_old_properties and not has_new_properties then
    return

  -- se non c'erano prima e ora ci sono, proseguo
  elseif not has_old_properties and has_new_properties then
    minetest.log("action", "[ARENA_LIB] Properties have been declared. Proceeding to add them")

  -- se c'erano prima e ora non ci sono più, svuoto e annullo
  elseif has_old_properties and not has_new_properties then

    for property, _ in pairs(minetest.deserialize(old_properties)) do
      for id, arena in pairs(mod_ref.arenas) do
        arena[property] = nil
        update_storage(false, mod, id, arena)
      end
    end

    minetest.log("action", "[ARENA_LIB] There are no properties left in the declaration of the mini-game. They've been removed from arenas")
    storage:set_string(mod .. ".PROPERTIES", "")
    return

  -- se c'erano sia prima che ora, le confronto
  else

    local new_properties_table = {}

    for property, _ in pairs(mod_ref.properties) do
      table.insert(new_properties_table, property)
    end

    -- se sono uguali in tutto e per tutto, termino qui
    if old_properties ~= minetest.serialize(new_properties_table) then
      minetest.log("action", "[ARENA_LIB] Properties have changed. Proceeding to modify old arenas")
    else
      return end

  end

  local old_table = minetest.deserialize(old_properties)
  local old_properties_table = {}

  -- converto la tabella dello storage in modo che sia compatibile con mod_ref, spostando le proprietà sulle chiavi
  if old_table then
    for _, property in pairs(old_table) do
      old_properties_table[property] = true
    end
  end

  -- aggiungo le nuove proprietà
  for property, v in pairs(mod_ref.properties) do

    if old_properties_table[property] == nil then

      assert(arena_default[property] == nil, "[ARENA_LIB] Custom property " .. property .. " can't be added " ..
                                      " as it has the same name of an arena default property. Please change name")
      minetest.log("action", "[ARENA_LIB] Adding property " .. property)

      for id, arena in pairs(mod_ref.arenas) do
        arena[property] = v
        update_storage(false, mod, id, arena)
      end
    end

  end

  -- rimuovo quelle non più presenti
  for old_property, _ in pairs(old_properties_table) do

    if mod_ref.properties[old_property] == nil then
      minetest.log("action", "[ARENA_LIB] Removing property " .. old_property)

      for id, arena in pairs(mod_ref.arenas) do
        arena[old_property] = nil
        update_storage(false, mod, id, arena)
      end
    end

  end

  local new_properties_table = {}

  -- inverto le proprietà di mod_ref da chiavi a valori per registrarle nello storage
  for property, _ in pairs(mod_ref.properties) do
    table.insert(new_properties_table, property)
  end

  storage:set_string(mod .. ".PROPERTIES", minetest.serialize(new_properties_table))
end



-- l'ID di base parte da 1 (n+1). Se la sequenza è 1, 3, 4, grazie a ipairs la
-- funzione vede che manca 2 nella sequenza e ritornerà 2
function next_available_ID(mod_ref)
  local id = 0
  for k, v in ipairs(mod_ref.arenas) do
    id = k
  end
  return id +1
end



function is_arena_name_allowed(sender, mod, arena_name)

  -- se esiste già un'arena con quel nome, annullo
  if arena_lib.get_arena_by_name(mod, arena_name) then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] An arena with that name exists already!")))
    return end

  local matched_string = string.match(arena_name, "([%w%p%s]+)")

  -- se contiene caratteri non supportati da signs_lib o termina con uno spazio, annullo
  if arena_name ~= matched_string or string.match(arena_name, "#") ~= nil or arena_name:sub(#arena_name, -1) == " " then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] The name contains unsupported characters!")))
    return end

  return true
end





----------------------------------------------
------------------DEPRECATED------------------
----------------------------------------------

-- to remove in 7.0
function arena_lib.remove_from_queue(p_name)
  minetest.log("warning", "[ARENA_LIB] remove_from_queue is deprecated. Please use remove_player_from_queue instead")
  arena_lib.remove_player_from_queue(p_name)
end

function arena_lib.send_message_players_in_arena(arena, msg, teamID, except_teamID)
  minetest.log("warning", "[ARENA_LIB] send_message_players_in_arena is deprecated. Please use send_message_in_arena instead")
  arena_lib.send_message_in_arena(arena, "players", msg, teamID, except_teamID)
end