arena_lib = {}
arena_lib.mods = {}

local S = minetest.get_translator("arena_lib")
local storage = minetest.get_mod_storage()



----------------------------------------------
---------------DICHIARAZIONI------------------
----------------------------------------------

local function init_storage() end
local function update_storage() end
local function check_for_properties() end
local function copy_table() end
local function next_available_ID() end
local function is_arena_name_allowed() end
local function assign_team_spawner() end
local function time_start() end

local players_in_game = {}    -- KEY: player name, VALUE: {(string) minigame, (int) arenaID}
local players_in_queue = {}   -- KEY: player name, VALUE: {(string) minigame, (int) arenaID}

local arena_default = {
  name = "",
  sign = {},
  players = {},               -- KEY: player name, VALUE: {kills, deaths, teamID, player_properties}
  teams = {-1},
  teams_enabled = false,
  players_amount = 0,
  players_amount_per_team = nil,
  spawn_points = {},          -- KEY: ids, VALUE: {position, team}
  max_players = 4,
  min_players = 2,
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

  --v------------------ LEGACY UPDATE, to remove in 5.0 -------------------v
  if def.is_timer_incrementing then
    minetest.log("warning", "[ARENA_LIB] is_timer_incrementing is deprecated. Use time_mode = 1 instead")
    def.time_mode = 1
  end

  if def.timer then
    minetest.log("warning", "[ARENA_LIB] timer is deprecated. Use time_mode = 2 instead")
    def.time_mode = 2
  end

  if def.immunity_time or def.immunity_slot then
    minetest.log("warning", "[ARENA_LIB] Immunity has been removed from arena_lib as a lot of minigames don't need it. It shall be implemented by modders in their own mods")
  end
  --^------------------ LEGACY UPDATE, to remove in 5.0 -------------------^

  arena_lib.mods[mod] = {}
  arena_lib.mods[mod].arenas = {}           -- KEY: (int) arenaID , VALUE: (table) arena properties
  arena_lib.mods[mod].highest_arena_ID = highest_arena_ID

  local mod_ref = arena_lib.mods[mod]

  --default parameters
  mod_ref.prefix = "[Arena_lib] "
  mod_ref.hub_spawn_point = { x = 0, y = 20, z = 0}
  mod_ref.teams = {}
  mod_ref.teams_color_overlay = nil
  mod_ref.is_team_chat_default = false
  mod_ref.chat_all_prefix = ""
  mod_ref.chat_team_prefix = "[" .. S("team") .. "] "
  mod_ref.chat_all_color = "#ffffff"
  mod_ref.chat_team_color = "#ddfdff"
  mod_ref.disabled_damage_types = {}
  mod_ref.join_while_in_progress = false
  mod_ref.keep_inventory = false
  mod_ref.show_nametags = false
  mod_ref.show_minimap = false
  mod_ref.time_mode = 0
  mod_ref.queue_waiting_time = 10
  mod_ref.load_time = 3           -- time in the loading phase (the pre-match)
  mod_ref.celebration_time = 3    -- time in the celebration phase
  mod_ref.properties = {}
  mod_ref.temp_properties = {}
  mod_ref.player_properties = {}
  mod_ref.team_properties = {}

  if def.prefix then
    mod_ref.prefix = def.prefix
  end

  if def.hub_spawn_point then
    mod_ref.hub_spawn_point = def.hub_spawn_point
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

  if def.disabled_damage_types and type(def.disabled_damage_types) == "table" then
    mod_ref.disabled_damage_types = def.disabled_damage_types
  end

  if def.join_while_in_progress == true then
    mod_ref.join_while_in_progress = def.join_while_in_progress
  end

  if def.keep_inventory == true then
    mod_ref.keep_inventory = def.keep_inventory
  end

  if def.show_nametags == true then
    mod_ref.show_nametags = def.show_nametags
  end

  if def.show_minimap == true then
    mod_ref.show_minimap = def.show_minimap
  end

  if def.time_mode then
    mod_ref.time_mode = def.time_mode
  end

  if def.queue_waiting_time then
    mod_ref.queue_waiting_time = def.queue_waiting_time
  end

  if def.load_time then
    mod_ref.load_time = def.load_time
  end

  if def.celebration_time then
    mod_ref.celebration_time = def.celebration_time
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
  mod_ref.arenas[ID] = copy_table(arena_default)

  local arena = mod_ref.arenas[ID]

  -- sovrascrivo con i parametri della funzione
  arena.name = arena_name
  if min_players and max_players then
    arena.min_players = min_players
    arena.max_players = max_players
  end

  -- eventuali team
  if #mod_ref.teams > 1 then
    arena.teams = {}
    arena.teams_enabled = true
    arena.players_amount_per_team = {}

    for k, t_name in pairs(mod_ref.teams) do
      arena.teams[k] = {name = t_name}
      arena.players_amount_per_team[k] = 0
    end
  end

  -- eventuale tempo
  if mod_ref.time_mode == 1 then
    arena.initial_time = 0
  elseif mod_ref.time_mode == 2 then
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

  minetest.chat_send_player(sender, S("Arena @1 successfully renamed in @2", old_name, new_name))
  return true

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
    if sender then minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] You can't change property type!")))
    else minetest.log("warning", "[ARENA_LIB] [!] Properties - You can't change property type!") end
    return end

  arena[property] = new_value
  update_storage(false, mod, id, arena)

  if sender then minetest.chat_send_player(sender, S("Property @1 successfully overwritten", property))
  else minetest.log("action", "[ARENA_LIB] Property " .. property .. " successfully overwritten") end
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

  local arena_ID = 0
  local arena = {}

  -- se uso la riga di comando, controllo se sto guardando un cartello
  if mod then
    arena_ID, arena = arena_lib.get_arena_by_name(mod, arena_name)

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
    arena_ID, arena = arena_lib.get_arena_by_name(mod, player:get_meta():get_string("arena_lib_editor.arena"))
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
        update_storage(false, mod, arena_ID, arena)
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
  update_storage(false, mod, arena_ID, arena)

  -- cambio la scritta
  arena_lib.update_sign(arena)

  -- salvo il nome della mod e l'ID come metadato nel cartello
  minetest.get_meta(pos):set_string("mod", mod)
  minetest.get_meta(pos):set_int("arenaID", arena_ID)

  minetest.chat_send_player(sender, mod_ref.prefix .. S("Sign of arena @1 successfully set", arena.name))

end



function arena_lib.set_timer(sender, mod, arena_name, timer, in_editor)

  local arena_ID, arena = arena_lib.get_arena_by_name(mod, arena_name)

  if not in_editor then
    if not ARENA_LIB_EDIT_PRECHECKS_PASSED(sender, arena) then return end
  end

  local mod_ref = arena_lib.mods[mod]

  -- se la mod non supporta i timer
  if mod_ref.time_mode ~= 2 then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] [!] Timers are not enabled in this mod!") .. " (time_mode = 2)"))
    return end

  -- se è inferiore a 1
  if timer < 1 then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] Parameters don't seem right!")))
    return end

  arena.initial_time = timer
  minetest.chat_send_player(sender, mod_ref.prefix .. S("Arena @1's timer is now @2 seconds", arena_name, timer))
end



function arena_lib.enable_arena(sender, mod, arena_name, in_editor)

  local arena_ID, arena = arena_lib.get_arena_by_name(mod, arena_name)

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
  update_storage(false, mod, arena_ID, arena)
  minetest.chat_send_player(sender, mod_ref.prefix .. S("Arena @1 successfully enabled", arena_name))

end



function arena_lib.disable_arena(sender, mod, arena_name)

  local mod_ref = arena_lib.mods[mod]
  local arena_ID, arena = arena_lib.get_arena_by_name(mod, arena_name)

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
  if next(arena.players) then
    for pl_name, stats in pairs(arena.players) do

      arena_lib.HUD_hide("all", arena)
      players_in_queue[pl_name] = nil
      arena.players[pl_name] = nil
      arena.in_queue = false
      minetest.chat_send_player(pl_name, minetest.colorize("#e6482e", S("[!] The arena you were queueing for has been disabled... :(")))

    end
    -- svuoto l'arena
    arena.players_amount = 0
    if arena.teams_enabled then
      for k, v in pairs(arena.players_amount_per_team) do
        arena.players_amount_per_team[k] = 0
      end
    end

  end

  -- disabilito
  arena.enabled = false
  arena_lib.update_sign(arena)
  update_storage(false, mod, arena_ID, arena)
  minetest.chat_send_player(sender, mod_ref.prefix .. S("Arena @1 successfully disabled", arena_name))
end





----------------------------------------------
--------------GESTIONE PARTITA-----------------
----------------------------------------------

-- per tutti i giocatori quando finisce la coda
function arena_lib.load_arena(mod, arena_ID)

  -- my child, let's talk about some black magic: in order to teleport players in their team spawners, first of all I need to
  -- sort them by team. Once it's done, I need to skip every spawner of that team if the maximum number of players is not reached:
  -- otherwise, people will find theirselves in the wrong team (and you don't want that to happen). So I use this int to prevent it,
  -- which increases by 1 or more every time I look for a spawner, comparing the 'team' spawner value to the player's. This happens
  -- in assign_team_spawner, which also returns the new value for team_count
  local team_count = 1

  local count = 1
  local mod_ref = arena_lib.mods[mod]
  local arena = mod_ref.arenas[arena_ID]

  arena.in_loading = true
  arena_lib.update_sign(arena)

  local shuffled_spawners = copy_table(arena.spawn_points)
  local sorted_team_players = {}

  -- aggiungo eventuali proprietà temporanee
  for temp_property, v in pairs(mod_ref.temp_properties) do
    arena[temp_property] = v
  end

  -- randomizzo gli spawner se non è a team
  if not arena.teams_enabled then
    for i = #shuffled_spawners, 2, -1 do
      local j = math.random(i)
      shuffled_spawners[i], shuffled_spawners[j] = shuffled_spawners[j], shuffled_spawners[i]
    end
  -- sennò ordino i giocatori per team
  else
    local j = 1
    for i = 1, #arena.teams do
      for pl_name, pl_stats in pairs(arena.players) do
        if pl_stats.teamID == i then
          sorted_team_players[j] = {name = pl_name, teamID = pl_stats.teamID}
          j = j +1
        end
      end

      -- e aggiungo eventuali proprietà per ogni team
      for k, v in pairs(mod_ref.team_properties) do
        arena.teams[i][k] = v
      end
    end

  end


  -- per ogni giocatore...
  for pl_name, _ in pairs(arena.players) do

    local player = minetest.get_player_by_name(pl_name)

    -- nascondo i nomi se l'opzione è abilitata
    if not mod_ref.show_nametags then
      player:set_nametag_attributes({color = {a = 0, r = 255, g = 255, b = 255}})
    end

    -- disattivo eventualmente la minimappa
    if not mod_ref.show_minimap then
      player:hud_set_flags({minimap = false})
    end

    -- chiudo eventuali formspec
    minetest.close_formspec(pl_name, "")

    -- li blocco sul posto
    player:set_physics_override({
              speed = 0,
              })

    -- cambio eventuale colore texture (richiede i team)
    if arena.teams_enabled and mod_ref.teams_color_overlay then
     player:set_properties({
       textures = {player:get_properties().textures[1] .. "^[colorize:" .. mod_ref.teams_color_overlay[arena.players[pl_name].teamID] .. ":85"}
     })
    end

    -- teletrasporto i giocatori
    if not arena.teams_enabled then
      player:set_pos(shuffled_spawners[count].pos)
    else
      team_count = assign_team_spawner(arena.spawn_points, team_count, sorted_team_players[count].name, sorted_team_players[count].teamID)
    end

    -- li curo
    player:set_hp(minetest.PLAYER_MAX_HP_DEFAULT)

    -- svuoto eventualmente l'inventario
    if not mod_ref.keep_inventory then
      player:get_inventory():set_list("main",{})
      player:get_inventory():set_list("craft",{})
    end

    -- registro giocatori nella tabella apposita
    players_in_queue[pl_name] = nil
    players_in_game[pl_name] = {minigame = mod, arenaID = arena_ID}

    count = count +1
  end


  -- eventuale codice aggiuntivo
  if mod_ref.on_load then
    mod_ref.on_load(arena)
  end

  -- inizio l'arena dopo tot secondi
  minetest.after(mod_ref.load_time, function()
    arena_lib.start_arena(mod_ref, arena)
  end)

end



function arena_lib.start_arena(mod_ref, arena)

  arena.in_loading = false
  arena_lib.update_sign(arena)

  for pl_name, stats in pairs(arena.players) do

    minetest.get_player_by_name(pl_name):set_physics_override({
            speed = 1,
            jump = 1,
            gravity = 1,
            })
  end

  -- parte l'eventuale tempo
  if mod_ref.time_mode > 0 then
    arena.current_time = arena.initial_time
    minetest.after(1, function()
      time_start(mod_ref, arena)
    end)
  end

  -- eventuale codice aggiuntivo
  if mod_ref.on_start then
    mod_ref.on_start(arena)
  end

end



-- per il player singolo a match iniziato
function arena_lib.join_arena(mod, p_name, arena_ID)

  local mod_ref = arena_lib.mods[mod]
  local player = minetest.get_player_by_name(p_name)
  local arena = mod_ref.arenas[arena_ID]

  -- nascondo i nomi se l'opzione è abilitata
  if not mod_ref.show_nametags then
    player:set_nametag_attributes({color = {a = 0, r = 255, g = 255, b = 255}})
  end

  -- disattivo eventualmente la minimappa
  if not mod_ref.show_minimap then
    player:hud_set_flags({minimap = false})
  end

  -- svuoto eventualmente l'inventario
  if not mod_ref.keep_inventory then
    player:get_inventory():set_list("main",{})
    player:get_inventory():set_list("craft",{})
  end

  -- cambio eventuale colore texture (richiede i team)
  if arena.teams_enabled and mod_ref.teams_color_overlay then
    player:set_properties({
      textures = {player:get_properties().textures[1] .. "^[colorize:" .. mod_ref.teams_color_overlay[arena.players[p_name].teamID] .. ":85"}
    })
  end

  -- riempio HP, teletrasporto e aggiungo
  player:set_hp(minetest.PLAYER_MAX_HP_DEFAULT)
  player:set_pos(arena_lib.get_random_spawner(arena, arena.players[p_name].teamID))
  players_in_game[p_name] = {minigame = mod, arenaID = arena_ID}

  -- eventuale codice aggiuntivo
  if mod_ref.on_join then
    mod_ref.on_join(p_name, arena)
  end
end


-- a partita finita.
-- winner_name può essere stringa (no team) o tabella di nomi (team)
function arena_lib.load_celebration(mod, arena, winner_name)

  local mod_ref = arena_lib.mods[mod]

  arena.in_celebration = true
  arena_lib.update_sign(arena)

  -- ripristino HP e visibilità nome di ogni giocatore
  for pl_name, stats in pairs(arena.players) do
    local player = minetest.get_player_by_name(pl_name)

    player:set_hp(minetest.PLAYER_MAX_HP_DEFAULT)
    player:set_nametag_attributes({color = {a = 255, r = 255, g = 255, b = 255}})
  end

  local winning_message = ""

  -- determino il messaggio da inviare
  if type(winner_name) == "string" then
    winning_message = S("@1 wins the game", winner_name)
  elseif type(winner_name) == "table" then
    local winner_team_ID = arena.players[winner_name[1]].teamID
    winning_message = S("Team @1 wins the game", arena.teams[winner_team_ID].name)
  end

  arena_lib.send_message_players_in_arena(arena, mod_ref.prefix  .. winning_message)

  -- eventuale codice aggiuntivo
  if mod_ref.on_celebration then
    mod_ref.on_celebration(arena, winner_name)
  end

  -- l'arena finisce dopo tot secondi
  minetest.after(mod_ref.celebration_time, function()
    arena_lib.end_arena(mod_ref, mod, arena)
  end)

end



function arena_lib.end_arena(mod_ref, mod, arena)

  -- copia da passare a on_end
  local players = {}

  for pl_name, stats in pairs(arena.players) do

    players[pl_name] = stats
    arena.players[pl_name] = nil
    players_in_game[pl_name] = nil

    local player = minetest.get_player_by_name(pl_name)

    -- svuoto eventualmente l'inventario
    if not mod_ref.keep_inventory then
      player:get_inventory():set_list("main", {})
      player:get_inventory():set_list("craft",{})
    end

    -- resetto eventuali texture
    if arena.teams_enabled and mod_ref.teams_color_overlay then
      player:set_properties({
        textures = {string.match(player:get_properties().textures[1], "(.*)^%[")}
      })
    end

    -- teletrasporto nella lobby
    player:set_pos(mod_ref.hub_spawn_point)

    -- se ho hub_manager, restituisco gli oggetti e imposto fisica della lobby
    if minetest.get_modpath("hub_manager") then
      hub_manager.set_items(player)
      hub_manager.set_hub_physics(player)
    end

    -- riattivo la minimappa eventualmente disattivata
    player:hud_set_flags({minimap = true})
  end


  -- azzero il numero di giocatori
  arena.players_amount = 0
  if arena.teams_enabled then
    for i = 1, #arena.teams do
      arena.players_amount_per_team[i] = 0
    end
  end

  -- azzero il timer
  arena.current_time = nil

  -- rimuovo eventuali proprietà temporanee
  for temp_property, v in pairs(mod_ref.temp_properties) do
    arena[temp_property] = nil
  end

  -- e quelle eventuali di team
  if arena.teams_enabled then
    for i = 1, #arena.teams do
      for t_property, _ in pairs(mod_ref.team_properties) do
        arena.teams[i][t_property] = nil
      end
    end
  end

  -- eventuale codice aggiuntivo
  if mod_ref.on_end then
    mod_ref.on_end(arena, players)
  end

  arena.in_loading = false                                                      -- nel caso venga forzata mentre sta caricando, sennò rimane a caricare all'infinito
  arena.in_celebration = false
  arena.in_game = false

  local id = arena_lib.get_arena_by_name(mod, arena.name)

  -- aggiorno storage per le properties e cartello
  update_storage(false, mod, id, arena)
  arena_lib.update_sign(arena)

end



function arena_lib.add_to_queue(p_name, mod, arena_ID)
  players_in_queue[p_name] = {minigame = mod, arenaID = arena_ID}
end



function arena_lib.remove_from_queue(p_name)

  local arena = arena_lib.get_arena_by_player(p_name)

  players_in_queue[p_name] = nil
  arena.players[p_name] = nil
end



----------------------------------------------
--------------------UTILS---------------------
----------------------------------------------

-- mod è opzionale
function arena_lib.is_player_in_arena(p_name, mod)

  if not players_in_game[p_name] then
    return false
  else

    -- se il campo mod è specificato, controllo che sia lo stesso
    if mod ~= nil then
      if players_in_game[p_name].minigame == mod then return true
      else return false
      end
    end

    return true

  end
end



function arena_lib.is_player_in_queue(p_name, mod)

  if not players_in_queue[p_name] then
    return false
  else

    -- se il campo mod è specificato, controllo che sia lo stesso
    if mod then
      if players_in_queue[p_name].minigame == mod then return true
      else return false
      end
    end

    return true

  end
end



function arena_lib.is_player_in_same_team(arena, p_name, t_name)
  if arena.players[p_name].teamID == arena.players[t_name].teamID then return true
  else return false
  end
end



function arena_lib.is_team_declared(mod_ref, team_name)

  if not mod_ref.teams then return false end

  for _, t_name in pairs(mod_ref.teams) do
    if team_name == t_name then
      return true
    end
  end
  return false
end



function arena_lib.force_arena_ending(mod, arena, sender)

  local mod_ref = arena_lib.mods[mod]

  -- se il minigioco non esiste, annullo
  if not mod_ref then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] This minigame doesn't exist!")))
    return end

  -- se l'arena non esiste, annullo
  if not arena then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] This arena doesn't exist!")))
    return end

  -- se l'arena non è in partita, annullo
  if not arena.in_game then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] No ongoing game!")))
    return end

  -- caccio tutti i giocatori
  for pl_name, _ in pairs(arena.players) do
    arena_lib.remove_player_from_arena(pl_name, 4, sender)
  end

  arena_lib.end_arena(mod_ref, mod, arena)
  minetest.chat_send_player(sender, S("Game in arena @1 successfully terminated", arena.name))
end



function arena_lib.remove_player_from_arena(p_name, reason, executioner)
  -- reason 0 = has disconnected
  -- reason 1 = has been eliminated
  -- reason 2 = has been kicked
  -- reason 3 = has quit the arena
  -- reason 4 = has been forced to quit the arena

  -- se il giocatore non è in partita, annullo
  if not arena_lib.is_player_in_arena(p_name) then return end

  local mod = arena_lib.get_mod_by_player(p_name)
  local mod_ref = arena_lib.mods[mod]
  local arena = arena_lib.get_arena_by_player(p_name)

  -- se una ragione è specificata
  if reason ~= 0 then

    local player = minetest.get_player_by_name(p_name)

    -- svuoto eventualmente l'inventario
    if not mod_ref.keep_inventory then
      player:get_inventory():set_list("main",{})
      player:get_inventory():set_list("craft",{})
    end

    -- resetto eventuali texture
    if arena.teams_enabled and mod_ref.teams_color_overlay then
      player:set_properties({
        textures = {string.match(player:get_properties().textures[1], "(.*)^%[")}
      })
    end

    -- resetto gli HP, teletrasporto fuori dall'arena e ripristino nome
    player:set_hp(minetest.PLAYER_MAX_HP_DEFAULT)
    player:set_pos(mod_ref.hub_spawn_point)
    player:set_nametag_attributes({color = {a = 255, r = 255, g = 255, b = 255}})

    -- se ho hub_manager, restituisco gli oggetti e imposto la fisica della lobby
    if minetest.get_modpath("hub_manager") then
      hub_manager.set_items(minetest.get_player_by_name(p_name))
      hub_manager.set_hub_physics(player)
    end

    -- resetto la minimappa eventualmente disattivata
    minetest.get_player_by_name(p_name):hud_set_flags({minimap = true})

    if reason == 1 then
      if executioner then
        arena_lib.send_message_players_in_arena(arena, minetest.colorize("#f16a54", "<<< " .. S("@1 has been eliminated by @2", p_name, executioner)))
      else
        arena_lib.send_message_players_in_arena(arena, minetest.colorize("#f16a54", "<<< " .. S("@1 has been eliminated", p_name)))
      end
      if mod_ref.on_eliminate then
        mod_ref.on_eliminate(arena, p_name)
      elseif mod_ref.on_quit then
        mod_ref.on_quit(arena, p_name)
      end
    elseif reason == 2 then
      if executioner then
        arena_lib.send_message_players_in_arena(arena, minetest.colorize("#f16a54", "<<< " .. S("@1 has been kicked by @2", p_name, executioner)))
      else
        arena_lib.send_message_players_in_arena(arena, minetest.colorize("#f16a54", "<<< " .. S("@1 has been kicked", p_name)))
      end
      if mod_ref.on_kick then
        mod_ref.on_kick(arena, p_name)
      elseif mod_ref.on_quit then
        mod_ref.on_quit(arena, p_name)
      end
    elseif reason == 3 then
      arena_lib.send_message_players_in_arena(arena, minetest.colorize("#d69298", "<<< " .. S("@1 has quit the match", p_name)))
      if mod_ref.on_quit then
        mod_ref.on_quit(arena, p_name)
      end
    elseif reason == 4 then
      if executioner then
        minetest.chat_send_player(p_name, minetest.colorize("#d69298", S("The arena has been forcibly terminated by @1", executioner)))
      else
        minetest.chat_send_player(p_name, minetest.colorize("#d69298", S("The arena has been forcibly terminated")))
      end
      if mod_ref.on_quit then
        mod_ref.on_quit(arena, p_name, true)
      end
    end
  else
    arena_lib.send_message_players_in_arena(arena, minetest.colorize("#f16a54", "<<< " .. p_name ))
    if mod_ref.on_disconnect then
      mod_ref.on_disconnect(arena, p_name)
    end
  end

  -- lo rimuovo
  players_in_game[p_name] = nil
  players_in_queue[p_name] = nil
  arena.players_amount = arena.players_amount - 1
  if arena.teams_enabled then
    local p_team_ID = arena.players[p_name].teamID
    arena.players_amount_per_team[p_team_ID] = arena.players_amount_per_team[p_team_ID] - 1
  end
  arena.players[p_name] = nil

  -- se il termine dell'arena è stato forzato, non c'è bisogno di andare oltre
  if reason == 4 then return end

  -- se l'arena era in coda e ora ci son troppi pochi giocatori, annullo la coda
  if arena.in_queue then

    local timer = minetest.get_node_timer(arena.sign)
    local arena_min_players = arena.min_players * #arena.teams
    local arena_max_players = arena.max_players * #arena.teams

    if arena.players_amount < arena_min_players then
      timer:stop()
      arena.in_queue = false
      arena_lib.HUD_send_msg_all("hotbar", arena, arena.name .. " | " .. arena.players_amount .. "/" .. arena_max_players .. " | " ..
        S("Waiting for more players...") .. " (" .. arena_min_players - arena.players_amount .. ")")
      arena_lib.send_message_players_in_arena(arena, mod_ref.prefix .. S("The queue has been cancelled due to not enough players"))
    end

  -- se invece è in partita, ha i team e sono rimasti solo i giocatori di un team, il loro team vince
  elseif arena.in_game and arena.teams_enabled and arena.players_amount < arena.min_players * #arena.teams then

    local team_to_compare

    for i = 1, #arena.players_amount_per_team do
      if arena.players_amount_per_team[i] ~= 0 then
        team_to_compare = i
        break
      end
    end

    for _, pl_stats in pairs(arena.players) do
      if pl_stats.teamID ~= team_to_compare then
        return
      end
    end

    arena_lib.send_message_players_in_arena(arena, mod_ref.prefix .. S("There are no other teams left, you win!"))
    arena_lib.load_celebration(mod, arena, arena_lib.get_players_in_team(arena, team_to_compare))

  -- se invece è in partita ed erano rimasti solo 2 giocatori in partita, l'altro vince
  elseif arena.in_game and arena.players_amount == 1 then

    if reason == 1 then
      arena_lib.send_message_players_in_arena(arena, mod_ref.prefix .. S("You're the last player standing: you win!"))
    else
      arena_lib.send_message_players_in_arena(arena, mod_ref.prefix .. S("You win the game due to not enough players"))
    end

    for pl_name, stats in pairs(arena.players) do
      arena_lib.load_celebration(mod, arena, pl_name)
    end
  end

  arena_lib.update_sign(arena)

end



function arena_lib.send_message_players_in_arena(arena, msg, teamID, except_teamID)

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
end



function arena_lib.teleport_in_arena(sender, mod, arena_name)

  local id, arena = arena_lib.get_arena_by_name(mod, arena_name)

  -- se non esiste l'arena, annullo
  if arena == nil then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] This arena doesn't exist!")))
    return end

  if not next(arena.spawn_points) then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] This action can't be performed with no spawners set!")))
    return end

  local player = minetest.get_player_by_name(sender)

  player:set_pos(arena.spawn_points[next(arena.spawn_points)].pos)
  minetest.chat_send_player(sender, S("Wooosh!"))

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



function arena_lib.get_players_in_game()
  return players_in_game
end



-- ritorna tabella di nomi giocatori, o di giocatori se to_players == true
function arena_lib.get_players_in_team(arena, team_ID, to_players)
  local players = {}
  for pl_name, pl_stats in pairs(arena.players) do
    if pl_stats.teamID == team_ID then
      if to_players then
        table.insert(players, minetest.get_player_by_name(pl_name))
      else
        table.insert(players, pl_name)
      end
    end
  end

  return players
end



function arena_lib.get_mod_by_player(p_name)
  if arena_lib.is_player_in_arena(p_name) then
    return players_in_game[p_name].minigame
  elseif arena_lib.is_player_in_queue(p_name) then
    return players_in_queue[p_name].minigame
  else
    return end
end



function arena_lib.get_arena_by_player(p_name)

  local mod, arenaID

  if arena_lib.is_player_in_arena(p_name) then      -- è in partita
    mod = players_in_game[p_name].minigame
    arenaID = players_in_game[p_name].arenaID
  elseif arena_lib.is_player_in_queue(p_name) then   -- è in coda
    mod = players_in_queue[p_name].minigame
    arenaID = players_in_queue[p_name].arenaID
  else
    return end

  return arena_lib.mods[mod].arenas[arenaID]
end



function arena_lib.get_arenaID_by_player(p_name)
  if players_in_game[p_name] then
    return players_in_game[p_name].arenaID
  end
end



function arena_lib.get_queueID_by_player(p_name)
  if players_in_queue[p_name] then
    return players_in_queue[p_name].arenaID
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
-----------------SETTERS----------------------
----------------------------------------------

-- nothing to see here ¯\_(ツ)_/¯



----------------------------------------------
---------------FUNZIONI LOCALI----------------
----------------------------------------------


function init_storage(mod, mod_ref)

  arena_lib.mods[mod] = mod_ref

  -- aggiungo le arene
  for i = 1, arena_lib.mods[mod].highest_arena_ID do

    local arena_str = storage:get_string(mod .. "." .. i)

    -- se c'è una stringa con quell'ID, aggiungo l'arena e ne aggiorno l'eventuale cartello
    if arena_str ~= "" then
      local arena = minetest.deserialize(arena_str)
      local to_update = false

      --v------------------ LEGACY UPDATE, to remove in 5.0 -------------------v
      -- team per arena for 3.2.0 and lesser versions
      if arena.teams_enabled == nil then
        if #arena.teams > 1 then
          arena.teams_enabled = true
        else
          arena.teams_enabled = false
        end
        minetest.log("action", "[ARENA_LIB] Added '.teams_enabled' property from 3.2.0")
        to_update = true
      end

      -- refactoring arena.timer in arena.initial_time for 3.6.0 and lesser versions
      if arena.timer then
        arena.initial_time = arena.timer
        arena.timer = nil
        to_update = true
      end
      --^------------------ LEGACY UPDATE, to remove in 5.0 -------------------^

      -- gestione team
      if arena.teams_enabled and not next(mod_ref.teams) then                   -- se avevo abilitato i team e ora li ho rimossi
        arena.players_amount_per_team = nil
        arena.teams = {-1}
        arena.teams_enabled = false
      elseif next(mod_ref.teams) and arena.teams_enabled then                   -- sennò li genero per tutte le arena con teams_enabled
        arena.players_amount_per_team = {}
        arena.teams = {}

        for k, t_name in pairs(mod_ref.teams) do
          arena.players_amount_per_team[k] = 0
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
      if mod_ref.time_mode == 0 and arena.initial_time then                     -- se avevo abilitato il tempo e ora l'ho rimosso, lo tolgo dalle arene
        arena.initial_time = nil
        to_update = true
      elseif mod_ref.time_mode ~= 0 and not arena.initial_time then             -- se li ho abilitati ora e le arene non ce li hanno, glieli aggiungo
        arena.initial_time = mod_ref.time_mode == 1 and 0 or 300
        to_update = true
      elseif mod_ref.time_mode == 1 and arena.initial_time > 0 then             -- se ho disabilitato i timer e le arene ce li avevano, porto il tempo a 0
        arena.initial_time = 0
        to_update = true
      elseif mod_ref.time_mode == 2 and arena.initial_time == 0 then            -- se ho abilitato i timer e le arene partivano da 0, imposto il timer a 5 minuti
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



--[[ Dato che in Lua non è possibile istanziare le tabelle copiandole, bisogna istanziare ogni campo in una nuova tabella.
     Ricorsivo per le sottotabelle. Codice da => http://lua-users.org/wiki/CopyTable]]
function copy_table(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[copy_table(orig_key)] = copy_table(orig_value)
        end
        setmetatable(copy, copy_table(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
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



function assign_team_spawner(spawn_points, ID, p_name, p_team_ID)

  for i = ID, #spawn_points do
    if p_team_ID == spawn_points[i].teamID then
      minetest.get_player_by_name(p_name):set_pos(spawn_points[i].pos)
      return i+1
    end
  end
end



function time_start(mod_ref, arena)

  if arena.on_celebration or not arena.in_game then return end

  if mod_ref.time_mode == 1 then
    arena.current_time = arena.current_time + 1
  else
    arena.current_time = arena.current_time - 1
  end

  if arena.current_time <= 0 then
    assert(mod_ref.on_timeout, "[ARENA_LIB] " .. S("[!] on_timeout callback must be declared to properly use a decreasing timer!"))
    mod_ref.on_timeout(arena)
    return
  else
    mod_ref.on_time_tick(arena)
  end

  minetest.after(1, function()
    time_start(mod_ref, arena)
  end)
end





----------------------------------------------
------------------DEPRECATED------------------
----------------------------------------------

-- to remove in 5.0
function arena_lib.update_properties(mod)
  minetest.log("warning", "[ARENA_LIB] arena_lib.update_properties is deprecated: properties are now updated automatically, pretty handy, init? :D")
end

function arena_lib.on_timer_tick(mod, func)
  minetest.log("warning", "[ARENA_LIB] on_timer_tick is deprecated. Please use on_time_tick instead")
  arena_lib.mods[mod].on_time_tick = func
end
