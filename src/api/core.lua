-- in here: whatever needs to access the storage (minigames and arenas management) + deprecations
arena_lib.mods = {}
arena_lib.entrances = {}

local S = minetest.get_translator("arena_lib")
local storage = minetest.get_mod_storage()



----------------------------------------------
---------------DICHIARAZIONI------------------
----------------------------------------------

local function load_settings() end
local function init_storage() end
local function update_storage() end
local function file_exists() end
local function deprecated_audio_exists() end
local function check_for_properties() end
local function next_available_ID() end
local function is_arena_name_allowed() end

local arena_default = {
  name = "",
  author = "???",
  thumbnail = "",
  entrance = nil,
  entrance_type = arena_lib.DEFAULT_ENTRANCE,
  custom_return_point = nil,
  players = {},                       -- KEY: player name, VALUE: {deaths, teamID, <player_properties>}
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
  spectate_entities_amount = nil,
  spectate_areas_amount = nil,
  spawn_points = {},
  max_players = 4,
  min_players = 2,
  celestial_vault = nil,               -- sky = {...}, sun = {...}, moon = {...}, stars = {...}, clouds = {...}
  lighting = nil,                      -- light = override_day_night_ratio
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

  arena_lib.mods[mod] = {}
  arena_lib.mods[mod].arenas = {}                                               -- KEY: (int) arenaID , VALUE: (table) arena properties
  arena_lib.mods[mod].highest_arena_ID = highest_arena_ID

  local mod_ref = arena_lib.mods[mod]

  -- /minigamesettings parameters
  load_settings(mod)

  --default parameters
  mod_ref.name = def.name or mod
  mod_ref.prefix = "[" .. mod_ref.name .. "] "
  mod_ref.icon = def.icon
  mod_ref.teams = {-1}
  mod_ref.variable_teams_amount = false
  mod_ref.teams_color_overlay = nil
  mod_ref.is_team_chat_default = false
  mod_ref.chat_all_prefix = "[" .. S("arena") .. "] "
  mod_ref.chat_team_prefix = "[" .. S("team") .. "] "
  mod_ref.chat_spectate_prefix = "[" .. S("spectator") .. "] "
  mod_ref.chat_all_color = "#ffffff"
  mod_ref.chat_team_color = "#ddfdff"
  mod_ref.chat_spectate_color = "#dddddd"
  mod_ref.messages = {
    eliminated = "@1 has been eliminated",
    eliminated_by = "@1 has been eliminated by @2",                             -- I won't include `kicked` and `kicked_by` as it's more of a maintenance function
    last_standing = "You're the last player standing: you win!",
    last_standing_team = "There are no other teams left, you win!",
    quit = "@1 has quit the match",
    celebration_one_player = "@1 wins the game",
    celebration_one_team = "Team @1 wins the game",
    celebration_more_players = "@1 win the game",
    celebration_more_teams = "Teams @1 win the game",
    celebration_nobody = "There are no winners"
  }
  mod_ref.custom_messages = {}     -- used internally to check whether a custom message has been registered (so to call the minigame translator rather than arena_lib's); KEY = msg name, VALUE = true
  mod_ref.player_aspect = nil
  mod_ref.fov = nil
  mod_ref.camera_offset = nil
  mod_ref.hotbar = nil
  mod_ref.min_players = 1
  mod_ref.endless = false
  mod_ref.end_when_too_few = true
  mod_ref.join_while_in_progress = false
  mod_ref.spectate_mode = true
  mod_ref.disable_inventory = false
  mod_ref.keep_inventory = false
  mod_ref.keep_attachments = false
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
  mod_ref.spectator_properties = {}
  mod_ref.team_properties = {}

  if def.prefix then
    mod_ref.prefix = def.prefix
  end

  if def.teams and type(def.teams) == "table" then
    mod_ref.teams = def.teams

    if def.variable_teams_amount == true then
      mod_ref.variable_teams_amount = true
    end

    if def.teams_color_overlay then
      mod_ref.teams_color_overlay = def.teams_color_overlay
    end

    if def.is_team_chat_default == true then
      mod_ref.is_team_chat_default = true
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

  if def.custom_messages then
    for k, msg in pairs(def.custom_messages) do
      mod_ref.messages[k] = msg
      mod_ref.custom_messages[k] = true
    end
  end

  if def.player_aspect then
    local aspect = def.player_aspect
    mod_ref.player_aspect = { visual = aspect.visual, mesh = aspect.mesh, textures = aspect.textures, visual_size = aspect.visual_size, collisionbox = aspect.collisionbox, selectionbox = aspect.selectionbox }
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

  if def.min_players then
    mod_ref.min_players = def.min_players
  end

  if def.endless == true then
    mod_ref.endless = true
    mod_ref.join_while_in_progress = true
    mod_ref.min_players = 0
  end

  if def.end_when_too_few == false then
    mod_ref.end_when_too_few = false
  end

  if def.join_while_in_progress == true then
    mod_ref.join_while_in_progress = def.join_while_in_progress
  end

  if def.spectate_mode == false then
    mod_ref.spectate_mode = false
  end

  if def.disable_inventory == true then
    mod_ref.disable_inventory = true
  end

  if def.keep_inventory == true then
    mod_ref.keep_inventory = true
  end

  if def.keep_attachments == true then
    mod_ref.keep_attachments = true
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
    assert(def.celebration_time > 0 or def.endless, "[ARENA_LIB] celebration_time must be greater than 0 (everyone deserves to celebrate!)")
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

  if def.spectator_properties then
    mod_ref.spectator_properties = def.spectator_properties
  end

  if def.team_properties then
    mod_ref.team_properties = def.team_properties
  end

  init_storage(mod, mod_ref)
end



function arena_lib.register_entrance_type(mod, entrance, def)
  local editor = def.editor_settings

  arena_lib.entrances[entrance] = {
    mod           = mod,
    name          = def.name,
    load          = def.on_load   or function() end,
    add           = def.on_add    or function() end,
    update        = def.on_update or function() end,
    remove        = def.on_remove or function() end,
    enter_editor  = editor.on_enter or function() end,
    print         = def.debug_output
  }

  minetest.register_tool( mod ..":editor_entrance", {

    description = editor.name,
    inventory_image = editor.icon,
    groups = {not_in_creative_inventory = 1},
    on_place = function() end,
    on_drop = function() end,

    on_use = function(itemstack, user)
      local p_name = user:get_player_name()
      local mod = user:get_meta():get_string("arena_lib_editor.mod")
      local arena_name = user:get_meta():get_string("arena_lib_editor.arena")
      local id, arena = arena_lib.get_arena_by_name(mod, arena_name)
      local items = editor.items and editor.items(p_name, mod, arena) or editor.tools

      --v------------------ LEGACY UPDATE, to remove in 7.0 -------------------v
      if editor.tools then
        minetest.log("warning", "[ARENA_LIB] editor_settings.tools is deprecated. Please use the editor_settings.items function instead, which shall return a table")
      end
      --^------------------ LEGACY UPDATE, to remove in 7.0 -------------------^

      table.insert(items, 8, "arena_lib:editor_return")
      table.insert(items, 9, "arena_lib:editor_quit")

      arena_lib.HUD_send_msg("hotbar", p_name, editor.description)
      user:get_inventory():set_list("main", items)
    end
  })
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
    if sender then minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] Property type doesn't match, aborting!")))
    else minetest.log("warning", "[ARENA_LIB] [!] Minigame parameters - Property type doesn't match, aborting!") end
    return end

  mod_settings[setting] = new_value
  storage:set_string(mod .. ".SETTINGS", minetest.serialize(mod_settings))

  -- in caso sia stato cambiato il punto di ritorno
  if setting == "return_point" then
    for _, arena in pairs(arena_lib.mods[mod].arenas) do
      if arena_lib.is_arena_in_edit_mode(arena.name) and not arena.custom_return_point then
        arena_lib.update_waypoints(arena_lib.get_player_in_edit_mode(arena.name), mod, arena)
      end
    end
  end

  if sender then minetest.chat_send_player(sender, S("Parameter @1 successfully overwritten", setting))
  else minetest.log("action", "[ARENA_LIB] Parameter " .. setting .. " successfully overwritten") end

end





----------------------------------------------
---------------GESTIONE ARENA-----------------
----------------------------------------------

function arena_lib.create_arena(sender, mod, arena_name, min_players, max_players)
  local mod_ref = arena_lib.mods[mod]

  if not mod_ref then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] This minigame doesn't exist!")))
    return end

  -- controllo nome
  if not is_arena_name_allowed(sender, mod, arena_name) then return end

  -- controllo che non abbiano messo parametri assurdi per lɜ giocatorɜ minimɜ/massimɜ
  if min_players and max_players then
    if min_players > max_players or min_players == 0 or max_players < 2 then
      minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] Parameters don't seem right!")))
      return end

    if min_players < mod_ref.min_players then
      minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] This minigame needs at least @1 players!", mod_ref.min_players)))
      return end

    if mod_ref.endless and min_players ~= 0 then
      minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] In endless minigames, the minimum amount of players must always be 0!")))
      return end
  end

  local ID = next_available_ID(mod_ref)

  -- creo l'arena
  mod_ref.arenas[ID] = table.copy(arena_default)

  local arena = mod_ref.arenas[ID]

  arena.name = arena_name

  -- numero giocatorɜ
  if mod_ref.endless then
    arena.min_players = 0
  end

  if min_players and max_players then
    arena.min_players = min_players
    arena.max_players = max_players
  end

  -- eventuali squadre
  if #mod_ref.teams > 1 then
    arena.teams = {}
    arena.teams_enabled = true
    arena.players_amount_per_team = {}

    for i, t_name in pairs(mod_ref.teams) do
      arena.spawn_points[i] = {}
      arena.teams[i] = {name = t_name}
      arena.players_amount_per_team[i] = 0
    end

    if mod_ref.spectate_mode then
      arena.spectators_amount_per_team = {}
      for i = 1, #mod_ref.teams do
        arena.spectators_amount_per_team[i] = 0
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

  -- aggiungo allo spazio d'archiviazione
  update_storage(false, mod, ID, arena)
  -- aggiorno l'ID globale nello spazio d'archiviazione
  storage:set_int(mod .. ".HIGHEST_ARENA_ID", mod_ref.highest_arena_ID)

  minetest.chat_send_player(sender, mod_ref.prefix .. S("Arena @1 successfully created", arena_name))
end



function arena_lib.remove_arena(sender, mod, arena_name, in_editor)
  local id, arena = arena_lib.get_arena_by_name(mod, arena_name)

  if not in_editor then
    if not ARENA_LIB_EDIT_PRECHECKS_PASSED(sender, arena) then return end
  end

  -- rimozione eventuale entrata
  if arena.entrance then
    arena_lib.entrances[arena.entrance_type].remove(mod, arena)
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

  -- aggiorno l'entrata, se esiste
  if arena.entrance then
    arena_lib.entrances[arena.entrance_type].update(mod, arena)
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
    minetest.chat_send_player(sender, arena_lib.mods[mod].prefix .. S("@1's author successfully removed", arena.name))
  else
    arena.author = author
    minetest.chat_send_player(sender, arena_lib.mods[mod].prefix .. S("@1's author successfully changed to @2", arena.name, arena.author))
  end

  update_storage(false, mod, id, arena)
end



function arena_lib.set_thumbnail(sender, mod, arena_name, thumbnail, in_editor)
  local id, arena = arena_lib.get_arena_by_name(mod, arena_name)

  if not in_editor then
    if not ARENA_LIB_EDIT_PRECHECKS_PASSED(sender, arena) then return end
  end

  if type(thumbnail) ~= "string" then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] Parameters don't seem right!")))
    return
  elseif thumbnail == nil or thumbnail == "" then
    arena.thumbnail = ""
    minetest.chat_send_player(sender, arena_lib.mods[mod].prefix .. S("@1's thumbnail successfully removed", arena.name))
  else
    local thmb_dir = minetest.get_worldpath() .. "/arena_lib/Thumbnails/"
    if not file_exists(thmb_dir, thumbnail) then
      minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] File not found!")))
      return end

    arena.thumbnail = thumbnail
    minetest.chat_send_player(sender, arena_lib.mods[mod].prefix .. S("@1's thumbnail successfully changed to @2", arena.name, arena.thumbnail))
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
    if sender then minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] Property type doesn't match, aborting!")))
    else minetest.log("warning", "[ARENA_LIB] [!] Properties - Property type doesn't match, aborting!") end
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

  local mod_ref = arena_lib.mods[mod]

  -- se il minigioco è infinito e si prova a modificare lɜ giocatorɜ minimɜ
  if mod_ref.endless and min_players and min_players ~= 0 then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] In endless minigames, the minimum amount of players must always be 0!")))
    return end

  -- salvo i vecchi parametri così da poterne modificare anche solo uno senza if lunghissimi
  local old_min_players = arena.min_players
  local old_max_players = arena.max_players

  arena.min_players = min_players or arena.min_players
  arena.max_players = max_players or arena.max_players

  -- se ha parametri assurdi, annullo
  if (arena.max_players ~= -1 and arena.min_players > arena.max_players) or arena.min_players <= 0 then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] Parameters don't seem right!")))
    arena.min_players = old_min_players
    arena.max_players = old_max_players
    return end

  -- se ha meno giocatorɜ di quellɜ richiestɜ dal minigioco, annullo
  if arena.min_players < mod_ref.min_players then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] This minigame needs at least @1 players!", mod_ref.min_players)))
    arena.min_players = old_min_players
    arena.max_players = old_max_players
    return end

  -- se lɜ giocatorɜ massimɜ sono cambiatɜ, svuoto i vecchi punti rinascita per evitare problemi
  if max_players and old_max_players ~= max_players then
    arena_lib.set_spawner(sender, mod, arena_name, nil, "deleteall", nil, in_editor)
  end

  -- aggiorno l'entrata, se esiste
  if arena.entrance then
    arena_lib.entrances[arena.entrance_type].update(mod, arena)
  end

  update_storage(false, mod, id, arena)
  minetest.chat_send_player(sender, arena_lib.mods[mod].prefix .. S("Players amount successfully changed ( min @1 | max @2 )", arena.min_players, arena.max_players))

  -- ritorno true per procedere al cambio di quantità nell'editor
  return true
end



function arena_lib.change_teams_amount(sender, mod, arena_name, amount, in_editor)
  local id, arena = arena_lib.get_arena_by_name(mod, arena_name)

  if not in_editor then
    if not ARENA_LIB_EDIT_PRECHECKS_PASSED(sender, arena) then return end
  end

  -- se le squadre non sono abilitate, annullo
  if not arena.teams_enabled then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] Teams are not enabled!")))
    return end

  -- se il numero inserito è lo stesso delle squadre attuali, annullo
  if #arena.teams == amount then
    minetest.chat_send_player(sender, minetest.colorize("#cfc6b8", S("[!] Nothing to do here!")))
    return end

  local mod_ref = arena_lib.mods[mod]

  -- se il numero è minore di 2, o maggiore delle squadre dichiarate nella mod, annullo
  if amount < 2 or amount > #mod_ref.teams then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] Parameters don't seem right!")))
    return end

  -- svuoto i vecchi punti rinascita per evitare problemi
  arena_lib.set_spawner(sender, mod, arena_name, nil, "deleteall", nil, in_editor)

  arena.teams = {}
  for i = 1, amount do
    arena.teams[i] = {name = mod_ref.teams[i]}
  end

  -- aggiorno l'entrata, se esiste
  if arena.entrance then
    arena_lib.entrances[arena.entrance_type].update(mod, arena)
  end

  update_storage(false, mod, id, arena)
  minetest.chat_send_player(sender, arena_lib.mods[mod].prefix .. S("Teams amount successfully changed (@1)", amount))

  -- ritorno true per procedere al cambio di stack nell'editor
  return true
end



function arena_lib.toggle_teams_per_arena(sender, mod, arena_name, enable, in_editor)      -- enable can be 0 or 1
  local id, arena = arena_lib.get_arena_by_name(mod, arena_name)

  if not in_editor then
    if not ARENA_LIB_EDIT_PRECHECKS_PASSED(sender, arena) then return end
  end

  -- se non ci sono squadre nella mod, annullo
  if not next(arena_lib.mods[mod].teams) then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] Teams are not enabled!")))
    return end

  -- se le squadre sono già in quello stato, annullo
  if enable == arena.teams_enabled then
    minetest.chat_send_player(sender, minetest.colorize("#cfc6b8", S("[!] Nothing to do here!")))
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

  -- svuoto i vecchi punti rinascita per evitare problemi
  arena_lib.set_spawner(sender, mod, arena_name, nil, "deleteall", nil, in_editor)

  -- aggiorno l'entrata, se esiste
  if arena.entrance then
    arena_lib.entrances[arena.entrance_type].update(mod, arena)
  end

  update_storage(false, mod, id, arena)
end



-- I punti rinascita si impostano prendendo la coordinata del giocatore che lancia il comando.
-- Non ci possono essere più punti rinascita del numero massimo di giocatori.
-- 'param' può essere "delete" o "deleteall"
function arena_lib.set_spawner(sender, mod, arena_name, team_ID, param, ID, in_editor)
  local id, arena = arena_lib.get_arena_by_name(mod, arena_name)

  if not in_editor then
    if not ARENA_LIB_EDIT_PRECHECKS_PASSED(sender, arena) then return end
  end

  local mod_ref = arena_lib.mods[mod]

  -- se l'eventuale squadra non esiste, annullo
  if team_ID and not arena.teams[team_ID] then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] This team doesn't exist!")))
    return end

  local pos = vector.round(minetest.get_player_by_name(sender):get_pos())       -- tolgo i decimali per immagazzinare un int

  -- o sto modificando un punto già esistente...
  if param then
    if param == "delete" then
      local spawner = not team_ID and arena.spawn_points[ID] or arena.spawn_points[team_ID][ID]
      if not spawner then
        minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] No spawner with ID @1 has been found!", ID)))
        return end

      if team_ID then
        table.remove(arena.spawn_points[team_ID], ID)
      else
        table.remove(arena.spawn_points, ID)
      end
      minetest.chat_send_player(sender, mod_ref.prefix .. S("Spawn point #@1 successfully deleted", ID))

    elseif param == "deleteall" then
      if team_ID then
        arena.spawn_points[team_ID] = {}
        minetest.chat_send_player(sender, S("All the spawn points belonging to team @1 have been removed", mod_ref.teams[team_ID]))
      else
        if arena.teams_enabled then
          for i = 1, #arena.teams do
            arena.spawn_points[i] = {}
          end
        else
          arena.spawn_points = {}
        end
        minetest.chat_send_player(sender, S("All spawn points have been removed"))
      end

    else
      minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] Parameters don't seem right!")))
    end

    arena_lib.update_waypoints(sender, mod, arena)
    update_storage(false, mod, id, arena)
    return
  end

  -- ...sennò sto creando un nuovo punto rinascita
  local spawn_points_count = arena_lib.get_arena_spawners_count(arena, team_ID)    -- (se team_ID è nil, ritorna in automatico i punti rinascita totali)

  -- se provo a impostare un punto rinascita di troppo, annullo
  if arena.max_players ~= -1 and spawn_points_count == arena.max_players then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] Spawn points can't exceed the maximum number of players!")))
    return end

  -- se c'è già un punto di rinascita a quelle coordinate, annullo
  if not team_ID then
    for id, spawn in pairs(arena.spawn_points) do
      if vector.equals(pos, spawn) then
        minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] There's already a spawn in this point!")))
        return
      end
    end
  else
    for i = 1, #arena.teams do
      for id, spawn in pairs(arena.spawn_points[i]) do
        if vector.equals(pos, spawn) then
          minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] There's already a spawn in this point!")))
          return
        end
      end
    end
  end

  local spawn_points = team_ID and arena.spawn_points[team_ID] or arena.spawn_points
  local next_available_spawnID = #spawn_points +1

  -- imposto il punto di rinascita
  if team_ID then
    arena.spawn_points[team_ID][next_available_spawnID] = pos
  else
    arena.spawn_points[next_available_spawnID] = pos
  end

  arena_lib.update_waypoints(sender, mod, arena)
  minetest.chat_send_player(sender, mod_ref.prefix .. S("Spawn point #@1 successfully set", next_available_spawnID))

  update_storage(false, mod, id, arena)
end



function arena_lib.set_entrance_type(sender, mod, arena_name, type)
  local id, arena = arena_lib.get_arena_by_name(mod, arena_name)

  if not arena_lib.is_player_in_edit_mode(sender) then
    if not ARENA_LIB_EDIT_PRECHECKS_PASSED(sender, arena) then return end
  end

  if arena.entrance_type == type then return end

  if not arena_lib.entrances[type] then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] There is no entrance type with this name!")))
    return end

  -- se esiste, rimuovo l'entrata attuale onde evitare danni
  if arena.entrance then
    arena_lib.entrances[arena.entrance_type].remove(mod, arena)
    arena.entrance = nil
  end

  arena.entrance_type = type
  minetest.chat_send_player(sender, arena_lib.mods[mod].prefix .. S("Entrance type of arena @1 successfully changed (@2)", arena_name, type))

  update_storage(false, mod, id, arena)
end



-- `action` = "add", "remove"
-- `...` è utile per "add", in quanto si vorrà passare perlomeno una posizione (nodi) o una stringa (entità) da salvare in arena.entrance
function arena_lib.set_entrance(sender, mod, arena_name, action, ...)
  local id, arena = arena_lib.get_arena_by_name(mod, arena_name)

  if not arena_lib.is_player_in_edit_mode(sender) then
    if not ARENA_LIB_EDIT_PRECHECKS_PASSED(sender, arena) then return end
  end

  local entrance = arena_lib.entrances[arena.entrance_type]

  if action == "add" then

    if arena.entrance then
      minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] There is already an entrance for this arena!")))
      return end

    local new_entrance = entrance.add(sender, mod, arena, ...)
    if not new_entrance then return end

    arena.entrance = new_entrance
    entrance.update(mod, arena)
    minetest.chat_send_player(sender, arena_lib.mods[mod].prefix .. S("Entrance of arena @1 successfully set", arena_name))

  elseif action == "remove" then

    if not arena.entrance then
      minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] There is no entrance to remove assigned to @1!", arena_name)))
      return end

    entrance.remove(mod, arena)
    arena.entrance = nil
    minetest.chat_send_player(sender, arena_lib.mods[mod].prefix .. S("Entrance of arena @1 successfully removed", arena_name))

  else
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] Parameters don't seem right!")))
    return
  end

  update_storage(false, mod, id, arena)
end



function arena_lib.set_custom_return_point(sender, mod, arena_name, pos, in_editor)
  local id, arena = arena_lib.get_arena_by_name(mod, arena_name)

  if not arena_lib.is_player_in_edit_mode(sender) then
    if not ARENA_LIB_EDIT_PRECHECKS_PASSED(sender, arena) then return end
  end

  if pos ~= nil and not vector.check(pos) then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] Parameters don't seem right!")))
    return end

  if arena.custom_return_point == pos then
    minetest.chat_send_player(sender, minetest.colorize("#cfc6b8", S("[!] Nothing to do here!")))
    return end

  arena.custom_return_point = pos
  arena_lib.update_waypoints(sender, mod, arena)

  local msg = arena.custom_return_point and "Custom return point of arena @1 succesfully set"
                                         or "Custom return point of arena @1 succesfully removed"

  update_storage(false, mod, id, arena)
  minetest.chat_send_player(sender, arena_lib.mods[mod].prefix .. S(msg, arena_name))
end



function arena_lib.set_lighting(sender, mod, arena_name, light_table, in_editor)
  local id, arena = arena_lib.get_arena_by_name(mod, arena_name)

  if not in_editor then
    if not ARENA_LIB_EDIT_PRECHECKS_PASSED(sender, arena) then return end
  end

  if light_table ~= nil and type(light_table) ~= "table" then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] Parameters don't seem right!")))
    return end

  arena.lighting = light_table

  update_storage(false, mod, id, arena)
  minetest.chat_send_player(sender, arena_lib.mods[mod].prefix .. S("Lighting of arena @1 successfully overwritten", arena.name))
end



function arena_lib.set_celestial_vault(sender, mod, arena_name, element, params, in_editor)
  local id, arena = arena_lib.get_arena_by_name(mod, arena_name)

  if not in_editor then
    if not ARENA_LIB_EDIT_PRECHECKS_PASSED(sender, arena) then return end
  end

  if params ~= nil and type(params) ~= "table" then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] Parameters don't seem right!")))
    return end

  -- sovrascrivi tutti
  if element == "all" then
    arena.celestial_vault = params

  -- sovrascrivine uno specifico
  elseif element == "sky" or element == "sun" or element == "moon" or element == "stars" or element == "clouds" then
    if not arena.celestial_vault then
      arena.celestial_vault = {}
    end
    arena.celestial_vault[element] = params

  -- oppure type non è un parametro contemplato
  else
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] Parameters don't seem right!")))
    return
  end

  element = element:gsub("^%l", string.upper) -- per non tradurre sia Sky che sky

  update_storage(false, mod, id, arena)
  minetest.chat_send_player(sender, arena_lib.mods[mod].prefix .. S("(@1) Celestial vault of arena @2 successfully overwritten", S(element), arena.name))
end




function arena_lib.set_bgm(sender, mod, arena_name, track, title, author, volume, pitch, in_editor)
  local id, arena = arena_lib.get_arena_by_name(mod, arena_name)

  if not in_editor then
    if not ARENA_LIB_EDIT_PRECHECKS_PASSED(sender, arena) then return end
  end

  local bgm_dir = minetest.get_worldpath() .. "/arena_lib/BGM/"

  if not file_exists(bgm_dir, track .. ".ogg") then
    if not deprecated_audio_exists(mod, track, sender) then
      minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] File not found!")))
      return end
  end

  if track == nil or track == "" then
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
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] Timers are not enabled in this mod!") .. " (time_mode = 'decremental')"))
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

  local has_sufficient_spawners = true

  if arena.teams_enabled then
    for i = 1, #arena.teams do
      if #arena.spawn_points[i] == 0 then
        has_sufficient_spawners = false
        break
      end
    end
  elseif #arena.spawn_points == 0 then
    has_sufficient_spawners = false
  end

  -- se non ci sono abbastanza punti rinascita
  if not has_sufficient_spawners then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] Insufficient spawners, the arena can't be enabled!")))
    arena.enabled = false
    return end

  -- se non c'è l'entrata
  if not arena.entrance then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] Entrance not set, the arena can't be enabled!")))
    arena.enabled = false
    return end

  local mod_ref = arena_lib.mods[mod]

  -- eventuali controlli personalizzati
  if mod_ref.on_enable then
    if not mod_ref.on_enable(arena, sender) then return end
  end

  for _, callback in ipairs(arena_lib.registered_on_enable) do
    if not callback(mod_ref, arena, sender) then return end
  end


  -- se sono nell'editor, vengo buttato fuori
  if arena_lib.is_player_in_edit_mode(sender) then
    arena_lib.quit_editor(minetest.get_player_by_name(sender))
  end

  -- abilito
  arena.enabled = true
  arena_lib.entrances[arena.entrance_type].update(mod, arena)
  update_storage(false, mod, id, arena)

  if mod_ref.endless then
    arena_lib.load_arena(mod, id)
  end

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

  -- se il minigioco è infinito e non ci son giocatorɜ, forzo la chiusura e ne
  -- estrapolo l'esito (rilancerà questa funzione ma con in_game = false)
  if mod_ref.endless and arena.in_game and arena.players_amount == 0 then
    return arena_lib.force_arena_ending(mod, arena, sender)
  end

  -- se una partita è in corso, annullo
  if arena.in_game then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] You can't disable an arena during an ongoing game!")))
    return end

  -- eventuali controlli personalizzati
  if mod_ref.on_disable then
    if not mod_ref.on_disable(arena, sender) then return end
  end

  for _, callback in ipairs(arena_lib.registered_on_disable) do
    if not callback(mod_ref, arena, sender) then return end
  end

  -- se c'è gente rimasta è in coda: annullo la coda e li avviso della disabilitazione
  for pl_name, stats in pairs(arena.players) do
    arena_lib.remove_player_from_queue(pl_name)
    minetest.chat_send_player(pl_name, minetest.colorize("#e6482e", S("[!] The arena you were queueing for has been disabled... :(")))
  end

  -- disabilito
  arena.enabled = false
  arena_lib.entrances[arena.entrance_type].update(mod, arena)
  update_storage(false, mod, id, arena)

  minetest.chat_send_player(sender, mod_ref.prefix .. S("Arena @1 successfully disabled", arena_name))
  return true
end





----------------------------------------------
--------------------UTILS---------------------
----------------------------------------------

-- internal use only
function arena_lib.store_inventory(player)
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

  player:get_inventory():set_list("main",{})
  player:get_inventory():set_list("craft",{})
end



-- internal use only
function arena_lib.restore_inventory(p_name)

  if storage:get_string(p_name .. ".INVENTORY") ~= "" then

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
  end
end





----------------------------------------------
---------------FUNZIONI LOCALI----------------
----------------------------------------------

function load_settings(mod)

  -- primo avvio
  if storage:get_string(mod .. ".SETTINGS") == "" then
    local default_settings = {
      return_point = { x = 0, y = 20, z = 0},
      queue_waiting_time = 10
    }
    arena_lib.mods[mod].settings = default_settings
    storage:set_string(mod .. ".SETTINGS", minetest.serialize(default_settings))
  else
    arena_lib.mods[mod].settings = minetest.deserialize(storage:get_string(mod .. ".SETTINGS"))

    --v------------------ LEGACY UPDATE, to remove in 7.0 -------------------v
    if arena_lib.mods[mod].settings.hub_spawn_point then
      arena_lib.mods[mod].settings.return_point = table.copy(arena_lib.mods[mod].settings.hub_spawn_point)
      arena_lib.mods[mod].settings.hub_spawn_point = nil
      storage:set_string(mod .. ".SETTINGS", minetest.serialize(arena_lib.mods[mod].settings))
    end
    --^------------------ LEGACY UPDATE, to remove in 7.0 -------------------^
  end
end



function init_storage(mod, mod_ref)
  arena_lib.mods[mod] = mod_ref

  -- aggiungo le arene
  for i = 1, arena_lib.mods[mod].highest_arena_ID do
    local arena_str = storage:get_string(mod .. "." .. i)

    -- se c'è una stringa con quell'ID, aggiungo l'arena e inizializzo l'entrata
    if arena_str ~= "" then
      local arena = minetest.deserialize(arena_str)
      local to_update = false

      --v------------------ LEGACY UPDATE, to remove in 8.0 -------------------v
      if arena.spawn_points[1] and arena.spawn_points[1].pos then
        local spawn_points = {}

        if arena.spawn_points[1].teamID then
          for i = 1, #arena.teams do
            spawn_points[i] = {}
          end
          for _, spawner in pairs(arena.spawn_points) do
            table.insert(spawn_points[spawner.teamID], spawner.pos)
          end
          arena.spawn_points = spawn_points

        else
          for _, spawner in pairs(arena.spawn_points) do
            table.insert(spawn_points, spawner.pos)
          end
          arena.spawn_points = spawn_points
        end
        minetest.log("action", "[ARENA_LIB] spawn points of arena " .. arena.name ..
          " has been converted into the new format")
        to_update = true
      end
      --^------------------ LEGACY UPDATE, to remove in 8.0 -------------------^

      --v------------------ LEGACY UPDATE, to remove in 7.0 -------------------v
      if not arena.spectators then
        arena.spectators = {}
        arena.spectators_amount = 0
        arena.players_and_spectators = {}
        arena.past_present_players = {}
        arena.past_present_players_inside = {}
        to_update = true
      end

      if arena.celestial_vault and not next(arena.celestial_vault) then
        arena.celestial_vault = nil
        to_update = true
      end

      if arena.sign then
        arena.entrance_type = "sign"
        arena.entrance = next(arena.sign) and table.copy(arena.sign) or nil
        arena.sign = nil
        to_update = true
      end

      if not arena.thumbnail then
        arena.thumbnail = ""
        to_update = true
      end
      --^------------------ LEGACY UPDATE, to remove in 7.0 -------------------^

      -- gestione squadre
      -- se avevo abilitato le squadre e ora le ho rimosse dalla mod
      if arena.teams_enabled and not (#mod_ref.teams > 1) then
        arena.teams = {-1}
        arena.teams_enabled = false
        arena.players_amount_per_team = nil
        arena.spectators_amount_per_team = nil
        arena.spawn_points = {}
        arena.enabled = false
        to_update = true

      -- se la mod ha le squadre, ma l'arena no e non è abilitata, arena_lib
      -- gliele mette nel dubbio (che tanto non se ne accorgono).
      -- Al contrario, non posso sapere se le squadre sono state appena inserite e
      -- tutte le arene vanno convertite; l'onere di conversione spetta allɜ amministratorɜ
      elseif #mod_ref.teams > 1 and not arena.teams_enabled and not arena.enabled then
        arena.players_amount_per_team = {}
        arena.spectators_amount_per_team = {}
        arena.teams = {}
        arena.spawn_points = {}

        for i, t_name in pairs(mod_ref.teams) do
          arena.players_amount_per_team[i] = 0
          arena.spectators_amount_per_team[i] = 0
          arena.teams[i] = {name = t_name}
          arena.spawn_points[i] = {}
        end

        arena.teams_enabled = true
        to_update = true

      -- se l'arena ha le squadre, non supporta n° variabile e il n° non coincide, le aggiorno
      elseif arena.teams_enabled and not mod_ref.variable_teams_amount and #mod_ref.teams ~= #arena.teams then
        for i, t_name in pairs(mod_ref.teams) do
          arena.players_amount_per_team[i] = 0
          arena.spectators_amount_per_team[i] = 0
          arena.teams[i] = {name = t_name}
          arena.spawn_points[i] = {}
        end

        arena.enabled = false
        to_update = true
        minetest.log("action", "[ARENA_LIB] teams amount of arena " .. arena.name ..
            " has changed: resetting arena spawn points")
      end

      -- aggiorna lɜ giocatorɜ minimɜ in caso di conflitto
      if mod_ref.endless and arena.min_players > 0 then
        arena.min_players = 0
        to_update = true
      end

      if arena.min_players < mod_ref.min_players then
        arena.min_players = mod_ref.min_players
        if arena.max_players < mod_ref.min_players then
          arena.max_players = mod_ref.min_players
        end
        to_update = true
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

      -- Contrariamente alle entità, i nodi non hanno un richiamo `on_activate`,
      -- ergo se si vogliono aggiornare all'avvio serve per forza un `on_load`
      minetest.after(0.01, function()
        if arena.entrance then                                                  -- signs_lib ha bisogno di un attimo per caricare sennò tira errore. Se
          arena_lib.entrances[arena.entrance_type].load(mod, arena)             -- non è ancora stato registrato nessun nodo per l'arena, evito il crash
        end
      end)
    end
  end

  check_for_properties(mod, mod_ref)

  -- se il minigioco è infinito, avvia tutte le arene non disabilitate
  if mod_ref.endless then
    for id, arena in pairs(mod_ref.arenas) do
      if arena.enabled then
        minetest.after(0.1, function()
          arena_lib.load_arena(mod, id)
        end)
      end
    end
  end

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



function file_exists(src_dir, name)
  local content = minetest.get_dir_list(src_dir, false)

  local function iterate_dirs(dir)
    for _, f_name in pairs(minetest.get_dir_list(dir, false)) do
      local file = io.open(dir .. "/" .. name, "r")
      if file then
        io.close(file)
        return true
      end
    end

    for _, subdir in pairs(minetest.get_dir_list(dir, true)) do
       if iterate_dirs(dir .. "/" .. subdir) then
         return true
       end
    end
  end

  return iterate_dirs(src_dir)
end


-- le proprietà vengono salvate nello spazio d'archiviazione senza valori, in una coppia id-proprietà. Sia per leggerezza, sia perché non c'è bisogno di paragonarne i valori
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

function arena_lib.set_sign(sender)
	minetest.log("warning", "[ARENA_LIB] set_sign(...) is deprecated, please use the new entrance system. Aborting...")
	minetest.chat_send_player(sender, "[ARENA_LIB] set_sign(...) is deprecated, please use the new entrance system. Aborting...")
end

function deprecated_audio_exists(mod, track, p_name)
  local deprecated_file = io.open(minetest.get_modpath(mod) .. "/sounds/" .. track .. ".ogg", "r")
  if deprecated_file then
    deprecated_file:close()
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", "[arena_lib] loading sounds from the minigame folder is deprecated and it'll be removed in future versions: "
      .. "put it into the world folder instead!"))
    return true
  end
end
